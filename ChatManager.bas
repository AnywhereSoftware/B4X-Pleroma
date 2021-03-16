B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@
#Event: NewMessage (Message As PLMChatMessage)
Sub Class_Globals
	Private tu As TextUtils
	Private mChatSupported As Boolean
	Private B4XFloatTextField1 As B4XFloatTextField
	Private mBase As B4XView
	Private xui As XUI
	Private btnSend As B4XView
	Private ChatId As String
	Private mCallback As ListOfStatuses
	Private mEventName As String
	Private mTheme As ThemeManager 'ignore
	Private btnCancel As Button
	
End Sub

Public Sub Initialize (parent As B4XView, Callback As ListOfStatuses, EventName As String)
	tu = B4XPages.MainPage.TextUtils1
	mBase = xui.CreatePanel("")
	mTheme = B4XPages.MainPage.Theme
	mBase.SetLayoutAnimated(0, 0, 0, parent.Width, 50dip)
	mBase.LoadLayout("ChatInputField")
	mBase.Visible = False
	parent.AddView(mBase, 0, 0, mBase.Width, mBase.Height)
	mCallback = Callback
	mEventName = EventName
	mTheme.RegisterForEvents(Me)
	Theme_Changed
End Sub

Private Sub Theme_Changed
	mTheme.SetFloatTextFieldColor(B4XFloatTextField1)
	If xui.IsB4i Then
		B4XFloatTextField1.mBase.SetColorAndBorder(xui.Color_Transparent, 1dip, xui.Color_LightGray, 2dip)
	End If
End Sub

Public Sub getChatSupported As Boolean
	Return B4XPages.MainPage.User.SignedIn And mChatSupported	
End Sub

Public Sub AfterServerVerified (Features As PLMInstanceFeatures)
	Dim NewValue As Boolean = Features.IsPleroma And Features.Features.Contains("pleroma_chat_messages")
	Dim ShouldUpdate As Boolean = mChatSupported <> NewValue
	mChatSupported = NewValue
	If ShouldUpdate Then B4XPages.MainPage.DrawerManager1.UpdateLeftDrawerList
End Sub

Public Sub StartChat (User As PLMAccount)
	
	Dim j As HttpJob = tu.CreateHttpJob(Me, Null, True)
	If j = Null Then Return
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/pleroma/chats/by-account-id/${User.id}/"$
	j.PostString(link, "")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	Dim Chat As PLMMetaChat
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			Chat = tu.ParseMetaChat(m)
		End If
	End If
	j.Release
	B4XPages.MainPage.HideProgress
	If Chat.IsInitialized Then
		B4XPages.MainPage.CloseDialogAndDrawer
		Dim link2 As PLMLink = tu.CreatePLMLink($"/api/v1/pleroma/chats/${Chat.ID}/messages"$, _
			Constants.LINKTYPE_CHAT, Chat.Account.UserName & " (Chat)")
		link2.Extra = CreateMap("chat_id": Chat.Id)
		B4XPages.MainPage.Statuses.Refresh2(B4XPages.MainPage.User, link2, True, False)
	Else
		B4XPages.MainPage.ShowMessage("Failed to start chat: " & j.ErrorMessage)
	End If
End Sub

Public Sub MessageFromStreamer (m As Map) As String
	Try
		Dim jh As JSONGenerator
		jh.Initialize(m)
		Dim s As String = m.Get("payload")
		m = tu.JsonParseMap(s)
		If m.IsInitialized Then
			Dim msg As PLMChatMessage = tu.ParseChatMessage(m.Get("last_message"))
			If msg.ChatId = ChatId Then
				If msg.AccountId <> B4XPages.MainPage.User.Id Then
					CallSub2(mCallback, mEventName & "_NewMessage", msg)
				End If
			Else
				If mCallback.feed.mLink.LinkType = Constants.LINKTYPE_CHATS_LIST Then
					mCallback.Refresh
				End If
				Return ChatMessagesUrlFromChatId(msg.ChatId)
			End If
		End If
	Catch
		Log(LastException)
	End Try
	Return ""
End Sub

Public Sub ChatMessagesUrlFromChatId (vChatId As String) As String
	Return $"/api/v1/pleroma/chats/${vChatId}/messages"$
End Sub

Public Sub Show (link As PLMLink)
	mBase.Visible = True
	mBase.BringToFront
	ChatId = link.Extra.Get("chat_id")
	Log("Chat starts: " & ChatId)
	KeyboardStateChanged
End Sub

Private Sub Post (status As String)
	If status.Trim = "" Then Return
	btnSend.Enabled = False
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
	If j = Null Then Return
	Dim params As Map = CreateMap("content": status)
	Dim jg As JSONGenerator
	jg.Initialize(params)
	j.PostString(B4XPages.MainPage.GetServer.URL & $"/api/v1/pleroma/chats/${ChatId}/messages"$, jg.ToString)
	j.GetRequest.SetContentType("application/json")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	B4XPages.MainPage.HideProgress
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			Dim msg As PLMChatMessage = tu.ParseChatMessage(m)
			CallSub2(mCallback, mEventName & "_NewMessage", msg)
		End If
		B4XFloatTextField1.Text = ""

	Else
		B4XPages.MainPage.ShowMessage("Failed to post message: " & j.ErrorMessage)
	End If
	j.Release
	btnSend.Enabled = True
End Sub

Public Sub Hide
	mBase.Visible = False
	B4XFloatTextField1.Text = ""
	ChatId = ""
End Sub

Private Sub btnSend_Click
	Post(B4XFloatTextField1.Text.Trim)
End Sub

Public Sub KeyboardStateChanged
	Dim NewTop As Int
	Dim OldTop As Int = mBase.Top
	Dim KeyboardVisible As Boolean = B4XPages.MainPage.IsKeyboardVisible
	Dim Left As Int = 10dip
	Dim Right As Int = btnSend.Left - 5dip
	If KeyboardVisible Then
		mBase.Height = 90dip
		B4XFloatTextField1.mBase.Height = mBase.Height - 10dip
	Else
		mBase.Height = 70dip
		B4XFloatTextField1.mBase.Height = mBase.Height - 20dip
		Left = 60dip
	End If
	
	B4XFloatTextField1.mBase.Width = Right - Left
	B4XFloatTextField1.mBase.Left = Left
	B4XFloatTextField1.TextField.Width = B4XFloatTextField1.mBase.Width
	B4XFloatTextField1.TextField.Height = B4XFloatTextField1.mBase.Height
	btnCancel.Visible = KeyboardVisible
	#if B4A
	NewTop = B4XPages.MainPage.B4AKeyboardActivityHeight - mBase.Height
	#else if B4i or B4J
	NewTop = B4XPages.MainPage.Root.Height - B4XPages.MainPage.B4iKeyboardHeight - mBase.Height
	#End If
	Dim duration As Int
	If mBase.Top = 0 Then duration = 0 Else duration = 100
	mBase.SetLayoutAnimated(duration, 0, NewTop, mBase.Width, mBase.Height)
	#if B4A
	If B4XPages.MainPage.B4iKeyboardHeight > 0 Then
		mBase.Color = mTheme.Background
	Else
		mBase.Color = xui.Color_Transparent
	End If
	#end if
	If KeyboardVisible Then mCallback.MakeSureThatLastStubItemIsLargeEnoughForKeyboard(Abs(OldTop - NewTop) + mBase.Height)
	mCallback.SmoothScrollBy(OldTop - NewTop)
End Sub

'returns True if the dialog was closed
Public Sub BackKeyPressed (OnlyTesting As Boolean) As Boolean
	Return False
End Sub

Private Sub btnCancel_Click
	B4XPages.MainPage.HideKeyboard
	B4XFloatTextField1.TextField.Enabled = False
	Sleep(0)
	B4XFloatTextField1.TextField.Enabled = True
End Sub

Public Sub Focus
	B4XFloatTextField1.RequestFocusAndShowKeyboard
End Sub

Public Sub MarkAsRead (feed As PleromaFeed)
	If feed.Statuses.Size <= feed.IndexOfFirstChatMessage Then Return
	Dim o As Object = feed.Statuses.Get(feed.Statuses.Keys.Get(feed.IndexOfFirstChatMessage))
	If (o Is PLMChatMessage) = False Then Return
	Dim lastmessage As PLMChatMessage = o
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
	If j = Null Then Return
	Dim params As Map = CreateMap("last_read_id": lastmessage.Id)
	Dim jg As JSONGenerator
	jg.Initialize(params)
	j.PostString(B4XPages.MainPage.GetServer.URL & $"/api/v1/pleroma/chats/${ChatId}/read"$, jg.ToString)
	j.GetRequest.SetContentType("application/json")
	B4XPages.MainPage.auth.AddAuthorization(j)
	B4XPages.MainPage.HideProgress
	Wait For (j) JobDone(j As HttpJob)
	j.Release
End Sub