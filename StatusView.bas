B4J=true
Group=ListItems
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
#Event: ShowLargeImage (URL As String, PreviewURL as String)
#Event: AvatarClicked (Account As PLMAccount) 
#Event: LinkClicked (Link As PLMLink) 
#Event: HeightChanged
#Event: Reply
#Event: AddReaction
#Event: StatusDeleted
Sub Class_Globals
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Public mBase As B4XView
	Private xui As XUI 'ignore
	Public Tag As Object
	Private lblTime As B4XView
	Private pnlBottom As B4XView
	Private pnlMedia As B4XView
	Private pnlTop As B4XView
	Private imgAvatar As B4XView
	Public mStatus As PLMStatus
	Private mTextEngine As BCTextEngine
	Private MediaSize As Int = 300dip
	Private BBListItem1 As BBListItem
	Private bbTop As BBListItem
	Private ImagesCache1 As ImagesCache
	Private TopFont As B4XFont
	Private BBBottom As BBListItem
	Private tu As TextUtils
	Private imgReadMore As B4XImageView
	Private BBListItem1FullHeight As Int
	Private Notif As PLMNotification
	Private SensitiveOverlay As Boolean
	Private pnlLine As B4XView
	Private IconsFont As B4XFont
	Private VideoPlayersReady As B4XSet
	Private mTheme As ThemeManager
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	ImagesCache1 = B4XPages.MainPage.ImagesCache1
	TopFont = xui.CreateDefaultFont(12)
	IconsFont = xui.CreateFontAwesome(18)
	tu = B4XPages.MainPage.TextUtils1
	VideoPlayersReady.Initialize
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
End Sub

Public Sub Create (Base As B4XView)
	mBase = Base
    Tag = mBase.Tag
    mBase.Tag = Me 
	mTextEngine = tu.TextEngine
	mBase.LoadLayout("StatusViewImpl")
	mBase.Tag = Me 'need to be set again as the previous layout will overwrite it.
	BBListItem1.TextEngine = mTextEngine
	#if B4J
	Dim iv As ImageView = imgAvatar
	iv.PickOnBounds = True
	Dim jo As JavaObject = lblTime
	jo.RunMethod("setFocusTraversable", Array(False)) 'prevent the "time" button from stealing the keyboard focus which causes the list to scroll unintentionally.
	#End If
	bbTop.TextEngine = mTextEngine
	BBBottom.TextEngine = mTextEngine
	B4XPages.MainPage.SetImageViewTag(imgAvatar)
	imgAvatar.SetColorAndBorder(xui.Color_Transparent, 0, 0, 5dip)
	B4XPages.MainPage.ViewsCache1.SetCircleClip(imgAvatar.Parent)
	bbTop.WordWrap = False
	Dim lbl As Label
	lbl.Initialize("lblReadMore")
	Dim xlbl As B4XView = lbl
	xlbl.Text = "Read more"
	xlbl.SetTextAlignment("CENTER", "CENTER")
	xlbl.Font = xui.CreateDefaultBoldFont(16)
	imgReadMore.mBase.AddView(xlbl, 0, 20dip, mBase.Width, 30dip)
	BBListItem1.ClickHighlight = lblTime
	Theme_Changed
End Sub

Private Sub Theme_Changed
	Dim imgReadMoreLabel As B4XView = imgReadMore.mBase.GetView(imgReadMore.mBase.NumberOfViews - 1)
	imgReadMoreLabel.TextColor = mTheme.DefaultText
	mBase.Color = mTheme.Background
	BBListItem1.ParseData.DefaultColor = mTheme.DefaultText
	pnlLine.Color = mTheme.Divider
	imgAvatar.Parent.Color = mTheme.AttachmentPanelBackground
	lblTime.TextColor = mTheme.SecondTextColor
End Sub


Public Sub SetContent (Status As PLMStatus, ListItem As PLMCLVItem)
	mStatus = Status
	VideoPlayersReady.Clear
	SensitiveOverlay = mStatus.Sensitive And B4XPages.MainPage.Settings.NSFW_Overlay
	Dim Notif As PLMNotification 'this will set it to be uninitialized.
	If mStatus.ExtraContent.IsInitialized And mStatus.ExtraContent.ContainsKey(Constants.ExtraContentKeyNotification) Then
		 Notif = mStatus.ExtraContent.Get(Constants.ExtraContentKeyNotification)
	End If
	SetTopText
	SetBottomPanel
	SetBBListContent
	SetTime
	ImagesCache1.SetImage(GetAvatarAccount.Avatar, imgAvatar.Tag, ImagesCache1.RESIZE_NONE)
	If BBListItem1.mBase.Height > Constants.MaxTextHeight + 20dip And ListItem.Expanded = False Then
		BBListItem1FullHeight = BBListItem1.mBase.Height
		BBListItem1.mBase.Height = Constants.MaxTextHeight
		imgReadMore.Bitmap = mTheme.ReadMoreGradient
		imgReadMore.mBase.Visible = True
		imgReadMore.mBase.Top =  BBListItem1.mBase.Top + BBListItem1.mBase.Height - imgReadMore.mBase.Height + 5dip
		imgReadMore.mbase.BringToFront
	Else
		imgReadMore.mBase.Visible = False
	End If
	Dim h As Int = BBListItem1.mBase.Height + 8dip * 2
	If mStatus.StubForDuplicatedNotification = False Then
		h = h + HandleAttachments
	End If
	BBBottom.mBase.Visible = mStatus.StubForDuplicatedNotification = False
	
	mBase.Height = pnlTop.Height + h + pnlBottom.Height
	SetHeightBasedOnMBaseHeight
End Sub

Private Sub GetAvatarAccount As PLMAccount
	If Notif.IsInitialized Then Return Notif.Account Else Return mStatus.StatusAuthor
End Sub

#If B4J
Private Sub lblReadMore_MouseClicked (EventData As MouseEvent)
#else
Private Sub lblReadMore_Click
#end if	
	Dim diff As Int = BBListItem1FullHeight - BBListItem1.mBase.Height
	BBListItem1.mBase.Height = BBListItem1FullHeight
	mBase.Height = mBase.Height + diff
	SetHeightBasedOnMBaseHeight
	imgReadMore.mBase.Visible = False
	CallSub(mCallBack, mEventName & "_HeightChanged")
	BBListItem1.UpdateVisibleRegion(0, 1000dip)
End Sub

Private Sub SetHeightBasedOnMBaseHeight
	pnlBottom.Top = mBase.Height - pnlBottom.Height
	pnlMedia.Top = BBListItem1.mBase.Top + BBListItem1.mBase.Height + 5dip
End Sub

Private Sub SetBBListContent
	BBListItem1.ReleaseInlineImageViews
	BBListItem1.PrepareBeforeRuns
	Dim runs As List = tu.HtmlConverter.ConvertHtmlToRuns(mStatus.Content.RootHtmlNode, BBListItem1.ParseData, mStatus.Emojis)
	
	BBListItem1.SetRuns(runs)
End Sub

Private Sub EmojiReactions (Runs As List)
	Dim fnt As B4XFont = xui.CreateFontAwesome(18)
	For Each m As Map In mStatus.EmojiReactions
		Dim IsMe As Boolean = m.Get("me") = True
		Dim action As String
		If IsMe Then
			action = "~emoji_delete:"
		Else
			action ="~emoji_put:"
		End If
		Dim r As BCTextRun = tu.CreateUrlRun(action & m.Get("name") , m.Get("name") & tu.NBSP, BBBottom.ParseData)
		r.TextFont = fnt
		Runs.Add(r)
		r = tu.CreateRun("(" & m.Get("count") & ")", TopFont)
		r.TextColor = GetIsUserColor(IsMe)
		Runs.Add(r)
		Runs.Add(tu.TextEngine.CreateRun("  "))
	Next
	Runs.Add(tu.TextEngine.CreateRun(CRLF & CRLF))
End Sub

Private Sub FavouriteClick
	Dim j As HttpJob = tu.CreateHttpJob(Me, BBBottom.mBase, True)
	If j = Null Then Return
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses/${mStatus.id}/"$
	If mStatus.Favourited Then
		link = link & "unfavourite"
	Else
		link = link & "favourite"
	End If
	Dim s As PLMStatus = mStatus
	j.PostString(link, "")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Wait For (tu.DownloadStatus(mStatus.id)) Complete (status As PLMStatus)
		If s = mStatus And status <> Null Then
			mStatus.Favourited = status.Favourited
			mStatus.FavouritesCount = status.FavouritesCount
			SetBottomPanel
		End If
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

Private Sub ReblogClick
	Dim j As HttpJob = tu.CreateHttpJob(Me, BBBottom.mBase, True)
	If j = Null Then Return
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses/${mStatus.id}/"$
	If mStatus.Reblogged Then
		link = link & "unreblog"
	Else
		link = link & "reblog"
	End If
	Dim s As PLMStatus = mStatus
	j.PostString(link, "")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Wait For (tu.DownloadStatus(mStatus.id)) Complete (status As PLMStatus)
		If s = mStatus And status <> Null Then
			mStatus.Reblogged = status.Reblogged
			mStatus.ReblogsCount = status.ReblogsCount
			SetBottomPanel
		End If
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

Public Sub EmojiClick (url As String)
	Dim j As HttpJob = tu.CreateHttpJob(Me, BBBottom.mBase, True)
	If j = Null Then Return
	Dim emoji As String = url.SubString(url.IndexOf(":") + 1)
	Dim su As StringUtils
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/pleroma/statuses/${mStatus.id}/reactions/${su.EncodeUrl(emoji, "utf8")}"$
	Dim s As PLMStatus = mStatus
	If url.StartsWith("~emoji_delete:") Then
		j.Delete(link)
	Else
		j.PutString(link, "")
	End If
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	j.Release
	If s = mStatus Then
		Wait For (tu.DownloadStatus(mStatus.id)) Complete (status As PLMStatus)
		If status <> Null And s = mStatus Then
			mStatus.EmojiReactions = status.EmojiReactions
			Dim h As Int = pnlBottom.Height
			SetBottomPanel
			Dim diff As Int = pnlBottom.Height - h
			If diff <> 0 Then
				mBase.Height = mBase.Height + diff
				SetHeightBasedOnMBaseHeight
				CallSub(mCallBack, mEventName & "_HeightChanged")
			End If
		End If
	End If
	B4XPages.MainPage.HideProgress
End Sub

Public Sub SetVisibility (visible As Boolean)
	Dim cache As ImagesCache = B4XPages.MainPage.ImagesCache1
	cache.SetConsumerVisibility(imgAvatar.Tag, visible)
	For Each x As B4XView In pnlMedia.GetAllViewsRecursive
		If x.Tag Is ImageConsumer Then
			cache.SetConsumerVisibility(x.Tag, visible)
		Else If x.Tag Is CardView Then
			Dim cv As CardView = x.Tag
			cv.SetVisibility(visible)
		Else If visible = False Then
			#If B4A or B4i
			#if B4A
			If x.Tag Is SimpleExoPlayer Then
			#else if B4i
			If x.Tag Is VideoPlayer Then
			#End If
				B4XPages.MainPage.ViewsCache1.StopVideoPlayback(x)
			End If
			#end if
		End If
	Next
	BBListItem1.ChangeVisibility(visible)
	bbTop.ChangeVisibility(visible)
End Sub

Private Sub SetTopText
	bbTop.PrepareBeforeRuns
	Dim runs As List
	runs.Initialize
	If mStatus.ExtraContent.IsInitialized And mStatus.ExtraContent.ContainsKey(Constants.ExtraContentKeyReblog) Then
		Dim reblog As PLMAccount = mStatus.ExtraContent.Get(Constants.ExtraContentKeyReblog)
		runs.Add(tu.CreateRun(Chr(0xF079) & " ", xui.CreateFontAwesome(12)))
		runs.Add(tu.CreateUrlRun(tu.CreateSpecialUrl("statuses", reblog.Id), "by " & reblog.Acct, bbTop.ParseData))
		runs.Add(mTextEngine.CreateRun(CRLF))
		For i = 0 To runs.Size - 1
			Dim r As BCTextRun = runs.Get(i)
			r.TextColor = mTheme.DefaultText
			If i > 0 Then r.TextFont = TopFont
		Next
	End If
	Dim acc As PLMAccount
	If Notif.IsInitialized Then acc = Notif.Account Else acc = mStatus.StatusAuthor
	tu.TextWithEmojisToRuns(acc.DisplayName & " ", runs, acc.Emojis, bbTop.ParseData, bbTop.ParseData.DefaultBoldFont)
	Dim r As BCTextRun = tu.CreateUrlRun("@", acc.Acct, bbTop.ParseData)
	r.TextFont = TopFont
	runs.Add(r)
	If Notif.IsInitialized Then
		NotificationToText(runs)
	Else
		If mStatus.InReplyToAccountAcct <> "" Then
			runs.Add(mTextEngine.CreateRun(CRLF))
			Dim r As BCTextRun = tu.CreateUrlRun(Constants.TextRunThreadLink, "" & Chr(0xF064) & " Reply to", bbTop.ParseData)
			r.TextFont = xui.CreateFontAwesome(12)
			r.TextColor = mTheme.DefaultText
			runs.Add(r)
			runs.Add(mTextEngine.CreateRun(" "))
			r = tu.CreateUrlRun(tu.CreateSpecialUrl("statuses", mStatus.InReplyToAccountId) , mStatus.InReplyToAccountAcct, bbTop.ParseData)
			r.TextFont = TopFont
			r.TextColor = mTheme.DefaultText
			runs.Add(r)
		End If
	End If
	bbTop.SetRuns(runs)
	bbTop.UpdateVisibleRegion(0, 300dip)
End Sub

Private Sub NotificationToText (runs As List)
	Dim fnt As B4XFont = xui.CreateFontAwesome(14)
	runs.Add(mTextEngine.CreateRun(CRLF))
	Dim r As BCTextRun
	Select Notif.NotificationType
		Case "reblog"
			r = tu.CreateRun(Chr(0xF079) & " reblogged your status", fnt)
		Case "favourite"
			r = tu.CreateRun(Chr(0xF006) & " favorited your status", fnt)
		Case "mention"
			r = tu.CreateRun(Chr(0xF1FA) & " mentioned you in their status", fnt)
		Case Else
			Log("Not implemented: " & Notif.NotificationType)
	End Select
	If r.IsInitialized Then
		runs.Add(r)
	End If
End Sub

Private Sub SetBottomPanel
	BBBottom.PrepareBeforeRuns
	Dim runs As List
	runs.Initialize
	If mStatus.EmojiReactions.IsInitialized And mStatus.EmojiReactions.Size > 0 Then
		EmojiReactions(runs)
	End If
	Dim tb As String = "  "
	
	runs.Add(CreateIconRun("~replies", Chr(0xF112), False))
	runs.Add(CreateCountRun(mStatus.RepliesCount))	
	runs.Add(mTextEngine.CreateRun(tb))
	
	runs.Add(CreateIconRun("~favourites", Chr(0xF006), mStatus.Favourited))
	runs.Add(CreateCountRun(mStatus.FavouritesCount))
	runs.Add(mTextEngine.CreateRun(tb))
	
	runs.Add(CreateIconRun("~reblog", Chr(0xF079), mStatus.Reblogged))
	runs.Add(CreateCountRun(mStatus.ReblogsCount))
	
	If B4XPages.MainPage.ServerSupportsEmojiReactions Then
		runs.Add(mTextEngine.CreateRun(tb))
		runs.Add(CreateIconRun("~reactions", Chr(0xF118), False))
	End If
	
	runs.Add(mTextEngine.CreateRun(tb))
	runs.Add(CreateIconRun("~more", Chr(0xF141), False))
	
	BBBottom.SetRuns(runs)
	BBBottom.UpdateVisibleRegion(0, 300dip)
	pnlBottom.Height = 5dip + BBBottom.mBase.Height
	pnlLine.Top = pnlBottom.Height - 1dip
End Sub

Private Sub CreateIconRun(URL As String, c As String, UserColorParameter As Boolean) As BCTextRun
	Dim r As BCTextRun = tu.CreateUrlRun(URL,  "  " & c & " ", BBBottom.ParseData)
	r.TextFont = IconsFont
	r.TextColor = GetIsUserColor(UserColorParameter)
	Return r
End Sub

Private Sub CreateCountRun (c As Int) As BCTextRun
	Dim s As String = " "
	If c > 0 Then 
		s = "(" & c & ")"
	End If
	Dim r As BCTextRun = tu.CreateRun(s, TopFont)
	r.VerticalOffset = -2dip
	Return r
End Sub

Private Sub GetIsUserColor(b As Boolean) As Int
	If b Then Return mTheme.AlreadyTookAction Else Return mTheme.DefaultText
End Sub

Private Sub HandleAttachments As Int
	Dim h(1) As Int
	For Each attachment As PLMMedia In mStatus.Attachments
		If attachment.PreviewUrl <> "" Then
			If attachment.TType = "image" Then
				ImageAttachment(attachment, h)
			Else If attachment.TType = "video" Then
				VideoAttachment(attachment, h)
			End If
			
		End If
	Next
	If mStatus.ExtraContent.IsInitialized And mStatus.ExtraContent.ContainsKey(Constants.ExtraContentKeyCard) Then
		CardAttachment(mStatus.ExtraContent.Get(Constants.ExtraContentKeyCard), h)
	End If
	pnlMedia.Height = h(0)
	pnlMedia.Visible = h(0) > 0
	Return h(0)
End Sub

Private Sub CardAttachment (card As Map, h() As Int)
	Dim stub As PLMMedia
	stub.TType = "card"
	Dim cv As CardView = B4XPages.MainPage.ViewsCache1.GetCardView
	Dim parent As B4XView = CreateAttachmentPanel(stub, h, 100dip, 15dip, cv.ImageView1.Tag)
	parent.AddView(cv.base, 0, 0, parent.Width, parent.Height)
	cv.SetCard(card, mCallBack, mEventName, mStatus.Attachments)
	parent.Height = cv.base.Height
	h(0) = h(0) - 100dip + cv.base.Height
End Sub

Private Sub ImageAttachment (attachment As PLMMedia, h() As Int)
	Dim iv As B4XView = B4XPages.MainPage.CreateImageView
	Dim Parent As B4XView = CreateAttachmentPanel(attachment, h, MediaSize, 30dip, iv.Tag)
	Parent.AddView(iv, 0, 0, 0, 0)
	Dim url As String = attachment.PreviewUrl
	If SensitiveOverlay Then
		url = B4XPages.MainPage.ImagesCache1.NSFW_URL
		ImagesCache1.SetImage(url, iv.Tag, ImagesCache1.RESIZE_FILL_NO_DISTORTIONS)
		ImagesCache1.HoldAnotherImage(attachment.PreviewUrl, iv.Tag, False, 0)
	Else
		ImagesCache1.SetImage(url, iv.Tag, ImagesCache1.RESIZE_FILL_NO_DISTORTIONS)
	End If
End Sub

Private Sub CreateAttachmentPanel (att As PLMMedia, h() As Int, Height As Int, SideGap As Int, Consumer As ImageConsumer) As B4XView
	Dim Parent As B4XView = xui.CreatePanel("AttachmentParent")
	If Consumer <> Null Then
		Consumer.PanelColor = mTheme.Background
	End If
	Parent.SetColorAndBorder(mTheme.AttachmentPanelBackground, 0, 0, 5dip)
	B4XPages.MainPage.ViewsCache1.SetClipToOutline(Parent)
	Parent.Tag = att
	pnlMedia.AddView(Parent, SideGap, h(0) + 10dip, pnlMedia.Width - 2 * SideGap, Height)
	h(0) = h(0) + Height + 10dip
	Return Parent
End Sub

Private Sub VideoAttachment (attachment As PLMMedia, h() As Int)
	If xui.IsB4J Then Return
	Dim iv As B4XView = B4XPages.MainPage.CreateImageView
	Dim Parent As B4XView = CreateAttachmentPanel(attachment, h, MediaSize, 2dip, iv.Tag)
	Dim playerview As B4XView = B4XPages.MainPage.ViewsCache1.GetVideoPlayer (Me, attachment)
	Parent.AddView(playerview, 0, 0, Parent.Width, Parent.Height)
	Parent.AddView(iv, 0, 0, 0, 0)
	#if B4A
	Dim player As SimpleExoPlayer = playerview.Tag
	player.Prepare(player.CreateUriSource(attachment.Url))
	#else if B4i
	Dim player As VideoPlayer = playerview.Tag
	player.LoadVideoUrl(attachment.Url)
	#end if
End Sub

Public Sub VideoReady (Success As Boolean, attachment As PLMMedia)
	For i = 0 To pnlMedia.NumberOfViews - 1
		Dim parent As B4XView = pnlMedia.GetView(i)
		If attachment = parent.Tag Then
			Dim iv As B4XView = parent.GetView(1)
			If Success = False Then
				ImagesCache1.SetImage(B4XPages.MainPage.ImagesCache1.MISSING_URL, iv.Tag, ImagesCache1.RESIZE_FILLWIDTH)
			Else
				VideoPlayersReady.Add(attachment)
				If SensitiveOverlay Then
					ImagesCache1.SetImage(B4XPages.MainPage.ImagesCache1.NSFW_URL, iv.Tag, ImagesCache1.RESIZE_FILLWIDTH)
				Else
					ShowPlayButton(iv)
				End If
			End If
		End If
	Next
End Sub

Private Sub ShowPlayButton (iv As B4XView)
	Dim parent As B4XView = iv.Parent
	iv.SetLayoutAnimated(0, parent.Width / 2 - 40dip, parent.Height / 2 - 30dip, 80dip, 60dip)
	ImagesCache1.SetImage(B4XPages.MainPage.ImagesCache1.PLAY, iv.Tag, ImagesCache1.RESIZE_NONE)
End Sub

#if B4J
Private Sub AttachmentParent_MouseClicked (EventData As MouseEvent)
#else
Private Sub AttachmentParent_Click
#End If
	If SensitiveOverlay Then
		RemoveSensitiveOverlay
		Return
	End If
	Dim Parent As B4XView = Sender
	Dim attachment As PLMMedia = Parent.Tag
	If attachment.TType = "image" Then
		CallSubDelayed3(mCallBack, mEventName & "_ShowLargeImage", attachment.Url, attachment.PreviewUrl)
	Else If attachment.TType = "video" Then
		If VideoPlayersReady.Contains(attachment) Then
			Parent.GetView(1).Visible = False
			ToggleVideo(Parent.GetView(0))
		End If
	End If
End Sub

Private Sub RemoveSensitiveOverlay
	For i = 0 To pnlMedia.NumberOfViews - 1
		Dim parent As B4XView = pnlMedia.GetView(i)
		Dim attachment As PLMMedia = parent.Tag
		Select attachment.TType
			Case "image"
				Dim iv As B4XView = parent.GetView(0)
				iv.SetBitmap(Null)
				ImagesCache1.SetImage(attachment.PreviewUrl, iv.Tag, ImagesCache1.RESIZE_FILL_NO_DISTORTIONS)
			Case "video"
				ShowPlayButton(parent.GetView(1))
		End Select
	Next
	SensitiveOverlay = False
End Sub

Private Sub ToggleVideo (PlayerView As B4XView) 'ignore
#if B4A or B4i
	If PlayerView.Parent.Tag = False Then Return
	#if B4A
	Dim player As SimpleExoPlayer = PlayerView.Tag
	Dim IsPlaying As Boolean =  player.IsPlaying
	#else if B4i
	Dim player As VideoPlayer = PlayerView.Tag
	Dim no As NativeObject = player
	Dim IsPlaying As Boolean = no.GetField("controller").GetField("player").GetField("rate").AsNumber > 0
	#End If
	If IsPlaying Then
		player.Pause
	Else
		If player.Position >= player.Duration Then
			player.Position = 0
		End If
		player.Play
		B4XPages.MainPage.ViewsCache1.StopPlaybackOfOtherVideos(PlayerView)
	End If
#end if
End Sub


Private Sub BBTOP_LinkClicked (URL As String, Text As String)
	BBListItem1_LinkClicked(URL, Text)
End Sub

Private Sub BBListItem1_LinkClicked (URL As String, Text As String)
	If URL = "~time click" Then
		lblTime_Click
	Else
		CallSub2(mCallBack, mEventName & "_LinkClicked", tu.ManageLink(mStatus, GetAvatarAccount, URL, Text))
	End If
End Sub

Private Sub BBBottom_LinkClicked (URL As String, Text As String)
	If URL.StartsWith("~favourites") Then
		FavouriteClick
	Else If URL.StartsWith("~reblog") Then
		ReblogClick
	Else If URL.StartsWith("~replies") Then
		XUIViewsUtils.PerformHapticFeedback(BBBottom.mBase)
		CallSub(mCallBack, mEventName & "_Reply")
	Else If URL.StartsWith("~reactions") Then
		XUIViewsUtils.PerformHapticFeedback(BBBottom.mBase)
		CallSub(mCallBack, mEventName & "_AddReaction")
	Else If URL.StartsWith("~more") Then
		ShowMoreOptions
	Else If URL.StartsWith("~emoji") Then
		EmojiClick(URL)
	End If
End Sub

Private Sub ShowMoreOptions
	Dim options As List
	options.Initialize
	options.Add(tu.CreateMenuItem(0xF1E0, "Share"))
	options.Add(tu.CreateMenuItem(0xF0C5, "Copy text"))
	options.Add(tu.CreateMenuItem(0xF024, "Report"))
	If B4XPages.MainPage.User.SignedIn And mStatus.StatusAuthor.Id = B4XPages.MainPage.User.Id Then
		options.Add(tu.CreateMenuItem(0xF014, "Delete"))
	End If
	Wait For (B4XPages.MainPage.ShowListDialog(options, False)) Complete (Result As String)
	Select options.IndexOf(Result)
		Case 0
			SharePost
		Case 1
			CopyToClipboard
		Case 2
			B4XPages.MainPage.Report.Show(mStatus.StatusAuthor, mStatus.id)
		Case 3
			DeleteStatus
	End Select
End Sub

Private Sub CopyToClipboard
	Try
		
		Dim text As String = tu.HtmlConverter.ConvertHtmlToText(mStatus.Content.RootHtmlNode, mStatus.Emojis)
	#if B4J
	Dim fx As JFX
	fx.Clipboard.SetString(text)
	#Else If B4i
	Dim c As Clipboard
	c.StringItem = text
	#Else if B4A
	Dim ctxt As JavaObject
	ctxt.InitializeContext
	Dim ClipboardManager As JavaObject = ctxt.RunMethod("getSystemService", Array("clipboard"))
	ClipboardManager.RunMethod("setText", Array(text))
	#End If
	B4XPages.MainPage.ShowMessage("Message copied to clipboard.")
	Catch
		Log(LastException)
		B4XPages.MainPage.ShowMessage("Failed to copy message: " & LastException)
	End Try
End Sub

Private Sub SharePost
#if B4A
	Dim in As Intent
	in.Initialize(in.ACTION_SEND, "")
	in.SetType("text/plain")
	in.PutExtra("android.intent.extra.TEXT", mStatus.Url)
	StartActivity(in)	
#Else If B4i
	Dim avc As ActivityViewController
	avc.Initialize("avc", Array(mStatus.URI))
	avc.Show(B4XPages.GetNativeParent(B4XPages.MainPage), BBBottom.mBase)
#End If
End Sub

Private Sub DeleteStatus
	Wait For (B4XPages.MainPage.ConfirmMessage("Delete status?")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
	If j = Null Then Return
	j.Delete(B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses/${mStatus.id}"$)
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	If j.Success Then
		CallSub(mCallBack, mEventName & "_StatusDeleted")
	Else
		B4XPages.MainPage.ShowMessage("Error deleting status: " & j.ErrorMessage)
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

Private Sub lblTime_Click
	BBListItem1_LinkClicked(Constants.TextRunThreadLink, "")
End Sub

Public Sub RemoveFromParent
	B4XPages.MainPage.ImagesCache1.ReleaseImage(imgAvatar.Tag)
	B4XPages.MainPage.ImagesCache1.RemovePanelChildImageViews(pnlMedia)
	Dim vc As ViewsCache = B4XPages.MainPage.ViewsCache1
	For i = 0 To pnlMedia.NumberOfViews - 1
		Dim parent As B4XView = pnlMedia.GetView(i)
		Dim attachment As PLMMedia = parent.Tag
		If attachment.TType = "video" Then
			Dim playerview As B4XView = parent.GetView(0)
			vc.StopVideoPlayback (playerview)
			playerview.RemoveViewFromParent
			vc.ReturnVideoPlayer(playerview)
		Else If attachment.TType = "card" Then
			Dim cv As CardView = parent.GetView(0).Tag
			cv.Release
		End If
	Next
	pnlMedia.RemoveAllViews
	BBListItem1.TextIndex = BBListItem1.TextIndex + 1
	mBase.RemoveViewFromParent
	BBListItem1.ReleaseInlineImageViews
	bbTop.ReleaseInlineImageViews
	imgReadMore.Clear
	imgReadMore.mBase.Visible = False
End Sub

Public Sub ParentScrolled(ScrollViewOffset As Int, CLVHeight As Int)
	If BBListItem1.Paragraph.IsInitialized And mBase.Parent.IsInitialized And mBase.Parent.Parent.IsInitialized Then
		Dim scale As Float = BBListItem1.TextEngine.mScale
		Dim ItemOffset As Int = mBase.Parent.Parent.Top + 60dip
		Dim ItemHeight As Int = BBListItem1.mBase.Height
		If ItemOffset > ScrollViewOffset + CLVHeight Or ItemOffset + ItemHeight < ScrollViewOffset Then
			Return
		End If
		Dim FixedItemOffset As Int = Max(0, ScrollViewOffset - ItemOffset)
		ItemHeight = Min(ItemHeight - FixedItemOffset, ScrollViewOffset + CLVHeight - ItemOffset)
		BBListItem1.UpdateVisibleRegion(FixedItemOffset * scale, ItemHeight * scale)
	End If
End Sub

Private Sub Base_Resize (Width As Double, Height As Double)
'	Log("Resize: " & Width & ", " & Height)
End Sub

Private Sub SetTime
	Dim t As Long = mStatus.CreatedAt
	If Notif.IsInitialized Then t = Notif.CreatedAt
	lblTime.Text = tu.TicksToTimeString(t, True)
	
End Sub

#if B4J
Private Sub imgAvatar_MouseClicked (EventData As MouseEvent)
#else
Private Sub imgAvatar_Click
#end if
	If mStatus.IsInitialized Then
		CallSub2(mCallBack, mEventName & "_AvatarClicked", GetAvatarAccount)
	End If
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub


