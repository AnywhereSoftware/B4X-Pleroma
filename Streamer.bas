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
	Public MostRecentNotification As Long
	Private tu As TextUtils
	Private LinksManager As B4XLinksManager
	Private LastExplicitCheck As Long
End Sub

Public Sub Initialize
	client.Initialize("client")
	tu = B4XPages.MainPage.TextUtils1
	LinksManager = B4XPages.MainPage.LinksManager
	MyLoop
End Sub

Private Sub MyLoop
	Do While True
		Sleep(10000)
		If Connecting And ConnectingStartTime + 60  * DateTime.TicksPerSecond > DateTime.Now Then
			Continue
		End If
		
		If IsClientConnected = False Or DateTime.Now > LastConnectedTime + 10 * DateTime.TicksPerMinute Then
			Connect
		End If
	Loop
End Sub

Public Sub LoadFromStore (store As KeyValueStore)
	MostRecentNotification = store.GetDefault("MostRecentNotification", 0)
	Log($"most recent notification: $DateTime{MostRecentNotification}"$)
End Sub

Public Sub SaveToStore (store As KeyValueStore)
	store.Put("MostRecentNotification", MostRecentNotification)
End Sub

Private Sub Connect 
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
	Dim Link As String = B4XPages.MainPage.GetServer.URL
	Link = Link.Replace("https://", "wss://").Replace("http://", "ws://")
	client.Connect(Link & $"/api/v1/streaming?access_token=${User.AccessToken}&stream=user"$)
	Connecting = True
	ConnectingStartTime = DateTime.Now
End Sub

Public Sub UserChanged
	Disconnect
	LastExplicitCheck = 0
	CheckForNewNotificationsAndChats
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
	Dim m As Map = B4XPages.MainPage.TextUtils1.JsonParseMap(Message)
	If m.IsInitialized Then
		Dim EventType As String = m.Get("event")
		Select EventType
			Case "update"
				LinksManager.LinksWithStreamerEvents.Add(LinksManager.LINK_HOME.URL)
			Case "notification"
				Dim payload As String = m.GetDefault("payload", "")
				If payload.Contains("pleroma:chat_mention") Then Return
				LinksManager.LinksWithStreamerEvents.Add(LinksManager.LINK_NOTIFICATIONS.URL)
			Case "pleroma:chat_update"
				Dim link As String = B4XPages.MainPage.Statuses.Chat.MessageFromStreamer(m)
				If link <> "" Then
					LinksManager.LinksWithStreamerEvents.Add(link)
				End If
		End Select
		AfterStateChanged
	End If
End Sub

Private Sub AfterStateChanged
	LinksManager.AfterLinksWithStreamerChanged
	B4XPages.MainPage.DrawerManager1.UpdateLeftDrawerList
	B4XPages.MainPage.UpdateHamburgerIcon
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

Public Sub CheckForNewNotificationsAndChats
	If LastExplicitCheck + 10 * DateTime.TicksPerSecond > DateTime.Now Then Return
	LastExplicitCheck = DateTime.Now
	Dim j As HttpJob = tu.CreateHttpJob(Me, Null, False)
	If j = Null Then Return
	j.Download(B4XPages.MainPage.GetServer.URL & B4XPages.MainPage.LinksManager.LINK_CHATS_LIST.URL)
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	If j.Success Then
		Dim messages As List = tu.JsonParseList(j.GetString)
		If messages.IsInitialized Then
			For Each message As Map In messages
				Dim cm As PLMMetaChat = tu.ParseMetaChat(message)
				If cm.Unread > 0 Then
					LinksManager.LinksWithStreamerEvents.Add(B4XPages.MainPage.Statuses.Chat.ChatMessagesUrlFromChatId(cm.Id))
				End If
			Next
		End If
	End If
	j.Release
	B4XPages.MainPage.HideProgress
	Dim j As HttpJob = tu.CreateHttpJob(Me, Null, False)
	If j = Null Then Return
	j.Download(B4XPages.MainPage.GetServer.URL & B4XPages.MainPage.LinksManager.LINK_NOTIFICATIONS.URL)
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	
	If j.Success Then
		Dim messages As List = tu.JsonParseList(j.GetString)
		If messages.IsInitialized Then
			For Each message As Map In messages
				Dim LastTime As Long = tu.ParseDate(message.GetDefault("created_at", ""))
				If LastTime > MostRecentNotification Then
					LinksManager.LinksWithStreamerEvents.Add(LinksManager.LINK_NOTIFICATIONS.URL)
				End If
				Exit
			Next
		End If
	End If
	B4XPages.MainPage.HideProgress
	AfterStateChanged
	
	j.Release
End Sub