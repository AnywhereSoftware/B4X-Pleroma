B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
'Handler class
Sub Class_Globals
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim data As Map = req.GetMultipartData(File.DirTemp, 5000000)
	Dim json As String
	For Each prt As Part In data.Values
		If prt.SubmittedFilename = "reports.json" Then
			json = File.ReadString(prt.TempFile, "")
		End If
		File.Delete(prt.TempFile, "")
	Next
	If json <> "" Then
		Dim parser As JSONParser
		parser.Initialize(json)
		Dim reports As List = parser.NextArray
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append("Number of reports: ").Append(reports.Size).Append(CRLF)
		For Each report As String In reports
			sb.Append(report).Append(CRLF)
		Next
		Dim smtp As SMTP
		Dim settings As Map = Main.Config1.Settings
		smtp.Initialize(settings.Get("SmtpServer"), 587, settings.Get("SmtpUser"), settings.Get("SmtpPassword"), "smtp")
		smtp.To.Add(settings.Get("SmtpTo"))
		smtp.Subject = "Crash Report"
		smtp.Body = sb.ToString
		smtp.Send
		StartMessageLoop
	End If
End Sub

Private Sub SMTP_MessageSent(Success As Boolean)
	Log("Message sent: " & Success)
	StopMessageLoop
End Sub

