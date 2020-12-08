B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	#if B4J
	Private client As WebSocketClient
	#else
	Private client As WebSocket
	#End If
	Private LastConnectedTime As Long
	Private Connecting As Boolean
	Private ConnectingStartTime As Long
End Sub

Public Sub Initialize
	client.Initialize("client")
	MyLoop
End Sub

Private Sub MyLoop
	Do While True
		Sleep(10000)
		If Connecting And ConnectingStartTime + 60  * DateTime.TicksPerSecond > DateTime.Now Then
			Continue
		End If
		
		If IsClientConnected = False Or DateTime.Now > LastConnectedTime + 5 * DateTime.TicksPerMinute Then
			Connect
		End If
	Loop
End Sub

Public Sub Connect 
	Disconnect
	Sleep(1000)
	Dim User As PLMUser = B4XPages.MainPage.User
	If User.SignedIn = False Then Return
	Log("WebSocket Connect")
	#if B4J
	Private client As WebSocketClient
	#else
	Private client As WebSocket
	#End If
	client.Initialize("client")	
	Dim link As String = B4XPages.MainPage.GetServer.URL
	link = link.Replace("https://", "wss://").Replace("http://", "ws://")
	client.Connect(link & $"/api/v1/streaming?access_token=${User.AccessToken}&stream=user"$)
	Connecting = True
	ConnectingStartTime = DateTime.Now
End Sub

Public Sub UserChanged
	Disconnect
End Sub

Private Sub Client_Connected
	Log("WebSocket connected")
	Connecting = False
	LastConnectedTime = DateTime.Now
End Sub

Private Sub Client_Closed (Reason As String)
	Log("WebSocket closed: " & Reason)
	Connecting = False
End Sub

Private Sub Client_TextMessage (Message As String)
	Log("WebSocket: " & Message)
	Dim links As B4XLinksManager = B4XPages.MainPage.LinksManager
	Dim m As Map = B4XPages.MainPage.TextUtils1.JsonParseMap(Message)
	If m.IsInitialized Then
		Dim EventType As String = m.Get("event")
		Select EventType
			Case "update"
				links.LinksWithStreamerEvents.Add(links.LINK_HOME.URL)
			Case "notification"
				links.LinksWithStreamerEvents.Add(links.LINK_NOTIFICATIONS.URL)
		End Select
		B4XPages.MainPage.DrawerManager1.UpdateLeftDrawerList
		B4XPages.MainPage.UpdateHamburgerIcon
	End If
End Sub

Public Sub Disconnect
	Try
		If IsClientConnected Then
			Log("WebSocket disconnect")
			client.Close
		End If
	Catch
		Log(LastException)
	End Try
	Connecting = False
End Sub

Private Sub IsClientConnected As Boolean
	#if B4i
	Return client.IsInitialized And client.Connected
	#else
	Return client.Connected
	#End If
End Sub