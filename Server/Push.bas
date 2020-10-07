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
	Log("*************************************")
	Log("push message from: " & req.RemoteAddress)
	Log(req.GetHeader("User-Agent"))
	Log(req.FullRequestURI)
	Dim m As Matcher = Regex.Matcher("/([^/]+)/(b4.?)$", req.FullRequestURI)
	If m.Find = False Then
		Return
	End If
	Dim su As StringUtils
	Dim auth As String = su.DecodeUrl(m.Group(1), "UTF8")
	Dim product As String = m.Group(2)
	Dim encrypted() As Byte = Bit.InputStreamToBytes(req.InputStream)
	Dim salt As String = GetValueFromHeader(req.GetHeader("Encryption"), "salt")
	Dim dh As String = GetValueFromHeader(req.GetHeader("Crypto-Key"), "dh")
	Dim text As String = Main.gcm.DecryptMessage(dh, salt, encrypted, su.DecodeBase64(auth))
	Dim parser As JSONParser
	parser.Initialize(text)
	Dim m2 As Map = parser.NextObject
	Dim msg As NotificationMessage = Main.CreateNotificationMessage(m2.Get("title"), m2.Get("body"), m.Group(1), product = "b4i")
	CallSubDelayed2(Main.fcm, "SendMessage", msg)
End Sub



Private Sub GetValueFromHeader (header As String, key As String) As String
	Dim m As Matcher = Regex.Matcher($"${key}=([^;]+)(;|$)"$, header)
	m.Find
	Return m.Group(1)
End Sub


