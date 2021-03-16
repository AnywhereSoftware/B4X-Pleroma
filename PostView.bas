B4J=true
Group=ListItems
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
#Event: Close
#Event: NewPost (Status As PLMStatus)
Sub Class_Globals
	Private xui As XUI
	Public mBase As B4XView
	Public B4XFloatTextField1 As B4XFloatTextField
	Public mReplyToId As String
	Private IdempotencyKey As String
	Private tu As TextUtils
	Private mCallback As Object
	Private mEventName As String
	Private btnCancel As B4XView
	Private btnCamera As B4XView	
	
	Private Medias As List
	Private pnlMedia As B4XView
	Private B4XImageView1 As B4XImageView
	Private InDialog As Boolean
	Private Posting As Boolean
	Private MediaSize As Int = 50dip
	
	Private PrefDialog As PreferencesDialog
	Private PostOptions As Map
	Private MediaChooser1 As MediaChooser
	Private Pane1 As B4XView
	Private mTheme As ThemeManager
	Private PollDialog As PreferencesDialog
	Private PollOptionsMap As Map
	Private PollOptionsList As List
	Private lblTextLength As B4XView
	Private lblVisibility As B4XView
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	mBase.LoadLayout("PostView")
	tu = B4XPages.MainPage.TextUtils1
	mCallback = Callback
	mEventName = EventName
	Medias.Initialize
	MediaChooser1 = B4XPages.MainPage.MediaChooser1
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	Theme_Changed
End Sub

Private Sub Theme_Changed
	mTheme.SetFloatTextFieldColor(B4XFloatTextField1)
	If xui.IsB4i Then
		B4XFloatTextField1.mBase.SetColorAndBorder(xui.Color_Transparent, 1dip, xui.Color_LightGray, 2dip)
	End If
End Sub

Public Sub SetContent(Content As PLMPost, ListItem As PLMCLVItem)
	PostOptions = CreateMap("nsfw": False, "visibility": Constants.VisibilityKeyToUserValue.GetDefault(Content.Visibility, "Public"))
	CreateDefaultPollOptions
	
	PollOptionsList.Initialize
	Dim IsSameReplyAsPreviousOne As Boolean = mReplyToId <> "" And mReplyToId = Content.ReplyToStatusId
	mReplyToId = Content.ReplyToStatusId
	mBase.Color = mTheme.Background
	For Each pm As PostMedia In Medias
		pm.Pnl.RemoveViewFromParent
	Next
	Medias.Clear
	InDialog = Content.ReplyToStatusId = ""
	btnCancel.Visible = Not(InDialog)
	Pane1.Visible = Not(InDialog)
	IdempotencyKey = Rnd(0, 0x7FFFFFFF)
	Dim mentions As StringBuilder
	mentions.Initialize
	For Each acct As String In Content.Mentions.AsList
		If acct = B4XPages.MainPage.User.Acct Then Continue
		mentions.Append("@").Append(acct).Append(" ")
	Next
	If IsSameReplyAsPreviousOne = False Then
		B4XFloatTextField1.Text = mentions.ToString
	End If
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	#if B4J
	Dim ta As TextArea = B4XFloatTextField1.TextField
	ta.SetSelection(B4XFloatTextField1.Text.Length, B4XFloatTextField1.Text.Length)
	#Else If B4i
	Dim ta As TextView = B4XFloatTextField1.TextField
	ta.SetSelection(B4XFloatTextField1.Text.Length, 0)
	#Else If B4A
	Dim et As EditText = B4XFloatTextField1.TextField
	et.SelectionStart = et.Text.Length
	et.SetSelection(B4XFloatTextField1.Text.Length, 0)
	#End If
	ArrangeMedias
	B4XFloatTextField1_TextChanged("", B4XFloatTextField1.Text)
	UpdateVisibiliyLabel
End Sub

Private Sub UpdateVisibiliyLabel
	Dim key As String = PostOptions.Get("visibility")
	key = key.ToLowerCase
	Dim str As String
	If key = "private" Or key = "direct" Then
		str = Chr(0xF023) & " "
	End If
	lblVisibility.Text = str & Constants.VisibilityKeyToUserValue.Get(key.ToLowerCase)
End Sub

Public Sub SetVisibility (visible As Boolean)
End Sub

Private Sub Post (status As String)
	If status.Trim = "" Then Return
	If Posting Then Return
	Dim AttachmentIds As List
	AttachmentIds.Initialize
	For Each pm As PostMedia In Medias
		If pm.Uploading Then
			B4XPages.MainPage.ShowMessage("Attachments are still being uploaded. Please try again shortly.")
			Return
		End If
		If pm.Removed = False And pm.UploadedSuccessfully Then
			AttachmentIds.Add(pm.Media.Id)
		End If
	Next
	If status.Length > B4XPages.MainPage.ServerFeatures.StatusMaxLength Then
		B4XPages.MainPage.ShowMessage("Status too long.")
		Return
	End If
	Posting = True
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
	If j = Null Then Return
	Dim params As Map = CreateMap("status": status)
	If mReplyToId <> "" Then params.Put("in_reply_to_id", mReplyToId)
	Dim vis As String = PostOptions.Get("visibility")
	params.Put("visibility", vis.ToLowerCase)
	params.Put("sensitive", PostOptions.Get("nsfw"))
	If PollOptionsList.Size > 0 Then
		Dim expiresIn As Int = (GetPollExpiryTime(PollOptionsMap) - DateTime.Now) / DateTime.TicksPerSecond
		Dim poll As Map = CreateMap("multiple": PollOptionsMap.Get("Multiple"), "expires_in": expiresIn, "options": PollOptionsList)
		params.Put("poll", poll)
	End If
	If AttachmentIds.Size > 0 Then params.Put("media_ids", AttachmentIds)
	Dim jg As JSONGenerator
	jg.Initialize(params)
	j.PostString(B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses"$, jg.ToString)
	j.GetRequest.SetHeader("Idempotency-Key", IdempotencyKey)
	j.GetRequest.SetContentType("application/json")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	B4XPages.MainPage.HideProgress
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			Dim st As PLMStatus = tu.ParseStatus(m)
			For Each pm As PostMedia In Medias
				If pm.Removed = False Then pm.UploadedSuccessfully = True
			Next
			If AttachmentIds.Size > 0 Then
				Sleep(1000) 'give the server some time to process the attachments.
			End If
			CallSub2(mCallback, mEventName & "_NewPost", st) 'ReplyToId is reset after this call.
			B4XPages.MainPage.Sound.PlaySound(Constants.SOUND_MESSAGE)
		End If
		
	End If
	Posting = False
	j.Release
End Sub

Public Sub RemoveFromParent
	mBase.RemoveViewFromParent
	For Each pm As PostMedia In Medias
		If pm.UploadedSuccessfully = False And pm.Uploading = False Then
			RemoveFromServer(pm)		
		End If
		If pm.DeleteTempFile Then
			File.Delete(pm.FileName, "")
		End If
	Next
	Medias.Clear
End Sub

Private Sub RemoveFromServer (pm As PostMedia) 'ignore
	'should be implemented when there is an API to remove already uploaded posts
	
End Sub

Private Sub btnCancel_Click
	CallSub(mCallback, mEventName & "_Close")
End Sub

Private Sub AttachMediaFile (pm As PostMedia)
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	If pm.IsInitialized = False Then Return
	If tu.CheckPostMediaSize (pm) = False Then Return
	If Posting Then Return
	Medias.Add(pm)
	pm.Pnl = xui.CreatePanel("")
	pm.Pnl.SetLayoutAnimated(0, 0, 0, MediaSize + 10dip , MediaSize + 10dip)
	pm.Pnl.LoadLayout("PostViewMedia")
	pm.Pnl.GetView(2).TextColor = mTheme.DefaultText
	pm.Pnl.Tag = pm
	If pm.IsImage Then
		Try
			B4XImageView1.Bitmap = xui.LoadBitmapResize(pm.FileName, "", MediaSize, MediaSize, True)
		Catch
			B4XImageView1.Bitmap = xui.LoadBitmapResize(File.DirAssets, Constants.MissingBitmapFileName, MediaSize, MediaSize, True)
		End Try
	Else
		pm.Pnl.GetView(1).Text = "Video"
	End If
	pm.Pnl.GetView(pm.Pnl.NumberOfViews -1).Visible = False
	B4XPages.MainPage.ViewsCache1.SetAlpha(pm.Pnl, 0.3)
	ArrangeMedias
	UploadMedia (pm)
End Sub

Private Sub ArrangeMedias
	pnlMedia.RemoveAllViews
	Dim count As Int
	Dim Offset As Int
	If InDialog Then Offset = 20dip Else Offset = 5dip
	For Each pm As PostMedia In Medias
		If pm.Removed Then Continue
		pnlMedia.AddView(pm.Pnl, Offset + (MediaSize + 15dip) * count, 0, pm.Pnl.Width, pm.Pnl.Width)
		count = count + 1
	Next
End Sub

Private Sub UploadMedia (pm As PostMedia)
	pm.Uploading = True
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
	If j = Null Then Return
	Dim part As MultipartFileData
	part.Initialize
	part.FileName = pm.FileName
	part.KeyName = "file"
	Log($"Uploading ${pm.FileName}, size: $1.0{File.Size(pm.FileName, "") / 1024 / 1024} MB"$)
	j.PostMultipart(B4XPages.MainPage.GetServer.URL & $"/api/v2/media"$, Null, Array(part))
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			pm.Media = tu.CreateAttachment(m)
			pm.Uploading = False
			If pm.Removed = False Then
				B4XPages.MainPage.ViewsCache1.SetAlpha(pm.Pnl, 1)
				pm.Pnl.GetView(pm.Pnl.NumberOfViews -1).Visible = True
				pm.UploadedSuccessfully = True
			Else
				RemoveFromServer(pm)	
			End If
		End If
	Else
		Log("Failed to upload")
		pm.Removed = True
		ArrangeMedias
		B4XPages.MainPage.ShowMessage("Error uploading attachment: " & j.ErrorMessage)
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

#if B4J
Private Sub lblDelete_MouseClicked (EventData As MouseEvent)
	EventData.Consume
#Else
Private Sub lblDelete_Click
#end if
	Dim lbl As B4XView = Sender
	Dim pm As PostMedia = lbl.Parent.Tag
	pm.Removed = True
	ArrangeMedias
End Sub

Private Sub btnMore_Click
	Dim options As List = Array("Capture image", "Image from gallery", "Capture video", "Video from gallery", "Poll")
	Wait For (B4XPages.MainPage.ShowListDialog(options, True)) Complete (Result As String)
	Dim rs As Object
	Dim option As Int = options.IndexOf(Result)
	Dim IsPoll As Boolean = option = 4
	If IsPollWithMedia(IsPoll) Then Return
	Select option
		Case 0
			rs = MediaChooser1.AddImageFromCamera
		Case 1
			rs = MediaChooser1.AddImageFromGallery (btnCamera)
		Case 2
			rs = MediaChooser1.AddVideoFromCamera 
		Case 3
			#if b4i
			MediaChooser1.AddVideoFromGallery(Me, "AttachMediaFile", btnCamera)
			Return
			#else
			rs = MediaChooser1.AddVideoFromGallery
			#End If
		Case 4
			AddPoll
	End Select
	Wait For (rs) Complete (pm As PostMedia)
	AttachMediaFile(pm)
End Sub

Private Sub IsPollWithMedia (IsPoll As Boolean) As Boolean
	If (IsPoll And pnlMedia.NumberOfViews > 0) Or (IsPoll = False And PollOptionsList.Size > 0) Then
		B4XPages.MainPage.ShowMessage("Cannot create poll with other media.")
		Return True
	End If
	Return False
End Sub

Private Sub AddPoll
	If PollDialog.IsInitialized = False Then
		PollDialog = B4XPages.MainPage.ViewsCache1.CreatePreferencesDialog("Poll.json")
	End If
	For i = 1 To 10
		If PollOptionsList.Size >= i Then
			PollOptionsMap.Put("o" & i, PollOptionsList.Get(i - 1))
		Else
			PollOptionsMap.Put("o" & i, "")
		End If
	Next
	PollDialog.SetEventsListener(Me, "PollDialog")
	Dim rs As Object = PollDialog.ShowDialog(PollOptionsMap, "Ok", "Cancel")
	B4XPages.MainPage.ViewsCache1.AfterShowDialog(PollDialog.Dialog)
	B4XFloatTextField1.TextField.Enabled = False
	Wait For (rs) Complete (Result As Int)
	B4XFloatTextField1.TextField.Enabled = True
	
	If Result = xui.DialogResponse_Positive Then
		PollOptionsList.Clear
		For i = 1 To 10
			Dim t As String = PollOptionsMap.Get("o" & i)
			t = t.Trim
			If t <> "" Then
				PollOptionsList.Add(t)
			End If
		Next
	End If
End Sub

Private Sub PollDialog_IsValid (TempData As Map) As Boolean
	If GetPollExpiryTime(TempData) <= DateTime.Now + 1 * DateTime.TicksPerMinute Then
		B4XPages.MainPage.ShowMessage("Invalid expiry date")
		Return False
	End If
	Return True	
End Sub

Private Sub GetPollExpiryTime (m As Map) As Long
	Dim date As Long = m.Get("Date")
	Dim time As Period = m.Get("Time")
	Return DateUtils.AddPeriod(date, time)
End Sub

Private Sub CreateDefaultPollOptions
	Dim n As Long = DateTime.Now
	PollOptionsMap = CreateMap("Date": DateUtils.SetDate(DateTime.GetYear(n), DateTime.GetMonth(n), DateTime.GetDayOfMonth(n)))
	Dim m As Int = DateTime.GetMinute(n) + 10
	Dim h As Int = DateTime.GetHour(n)
	If m > 60 Then 
		m = m - 60
		h = (h + 1) Mod 24
	End If
	Dim p As Period
	p.Initialize
	p.Hours = h
	p.Minutes = m
	PollOptionsMap.Put("Time", p)
End Sub

Private Sub btnCamera_Click
	If IsPollWithMedia(False) Then Return
	Wait For (MediaChooser1.AddImageFromCamera) Complete (pm As PostMedia)
	AttachMediaFile(pm)
	
End Sub

Sub btnGallery_Click
	If IsPollWithMedia(False) Then Return
	Wait For (MediaChooser1.AddImageFromGallery (btnCamera)) Complete (pm As PostMedia)
	AttachMediaFile(pm)
End Sub


Private Sub btnOptions_Click
	If PrefDialog.IsInitialized = False Then
		PrefDialog = B4XPages.MainPage.ViewsCache1.CreatePreferencesDialog("PostView.json")
	End If
	Dim rs As Object = PrefDialog.ShowDialog(PostOptions, "Ok", "Cancel")
	B4XPages.MainPage.ViewsCache1.AfterShowDialog(PrefDialog.Dialog)
	Wait For (rs) Complete (Success As Int)
	B4XPages.MainPage.UpdateHamburgerIcon
	UpdateVisibiliyLabel
End Sub

'returns True if the dialog was closed
Public Sub BackKeyPressed (OnlyTesting As Boolean) As Boolean
	If PrefDialog.IsInitialized And PrefDialog.Dialog.Visible Then
		If OnlyTesting = False Then PrefDialog.Dialog.Close(xui.DialogResponse_Cancel)
		Return True
	End If
	Return False
End Sub

Private Sub btnSend_Click
	Post(B4XFloatTextField1.Text)
End Sub

Private Sub B4XFloatTextField1_TextChanged (Old As String, New As String)
	Dim maxlength As Int = B4XPages.MainPage.ServerFeatures.StatusMaxLength
	lblTextLength.Text = $"${New.Length}/${maxlength}"$
	If New.Length > maxlength Then lblTextLength.TextColor = xui.Color_Red Else lblTextLength.TextColor = mTheme.DefaultText
End Sub