B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=10.2
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: False
	
#End Region

Sub Process_Globals
	Private fm As FirebaseMessaging
End Sub

Sub Service_Create
	fm.Initialize("fm")
End Sub

Public Sub SubscribeToTopic (Topic As String)
	fm.SubscribeToTopic(Topic)
End Sub

Sub Service_Start (StartingIntent As Intent)
	If StartingIntent.IsInitialized Then fm.HandleIntent(StartingIntent)
	Sleep(0)
	Service.StopAutomaticForeground 'remove if not using B4A v8+.
End Sub

Sub fm_MessageArrived (Message As RemoteMessage)
	Log("Message arrived")
	Log($"Message data: ${Message.GetData}"$)
	Dim title As String = Message.GetData.Get("title")
	Dim IsChat As Boolean = title = Constants.NewChatMessageTitle
	If IsChat And B4XPages.IsInitialized And B4XPages.MainPage.IsInitialized And B4XPages.MainPage.Background = False Then
		Return
	End If
	Dim n As Notification
	n.Initialize2(n.IMPORTANCE_HIGH)
	n.Icon = "icon"
	n.AutoCancel = True
	Dim tag As String
	If IsChat Then tag = "chat" Else tag = "notification"
	n.SetInfo2(title, Message.GetData.Get("body"), tag, Main)
	n.Notify(1)
End Sub

Sub Service_Destroy

End Sub