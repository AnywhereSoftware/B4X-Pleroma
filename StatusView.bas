B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
#Event: ShowLargeImage (URL As String)
#Event: AvatarClicked (Account As PLMAccount) 
#Event: LinkClicked (Link As PLMLink) 
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
	Private mStatus As PLMStatus
	Private mTextEngine As BCTextEngine
	Private MediaSize As Int = 300dip
	Private BBListItem1 As BBListItem
	Private bbTop As BBListItem
	Public ListIndex As Int
	Private ImagesCache1 As ImagesCache
	Private TopFont As B4XFont
	Private BBBottom As BBListItem
	Private tu As TextUtils
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	ImagesCache1 = B4XPages.MainPage.ImagesCache1
	TopFont = xui.CreateDefaultFont(12)
	tu = B4XPages.MainPage.TextUtils1
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
End Sub


Public Sub SetContent (Status As PLMStatus)
	mStatus = Status
	SetTopText
	SetBottomPanel
	BBListItem1.Tag = ListIndex
	SetBBListContent
	SetTime
	ImagesCache1.SetImage(mStatus.Account.Avatar, imgAvatar.Tag, ImagesCache1.RESIZE_NONE)
	Dim h As Int = BBListItem1.mBase.Height + 8dip * 2
	h = h + HandleAttachments
	pnlMedia.Top = BBListItem1.mBase.Top + BBListItem1.mBase.Height + 5dip
	mBase.Height = pnlTop.Height + h + pnlBottom.Height
	pnlBottom.Top = mBase.Height - pnlBottom.Height
End Sub

Private Sub SetBBListContent
	BBListItem1.ReleaseInlineImageViews
	BBListItem1.PrepareBeforeRuns
	Dim runs As List = tu.HtmlConverter.ConvertHtmlToRuns(mStatus.Content.RootHtmlNode, BBListItem1.ParseData, mStatus.Emojis)
	If mStatus.EmojiReactions.IsInitialized And mStatus.EmojiReactions.Size > 0 Then
		EmojiReactions(runs)
	End If
	BBListItem1.SetRuns(runs)
End Sub

Private Sub EmojiReactions (Runs As List)
	Runs.Add(tu.TextEngine.CreateRun(CRLF & CRLF))
	For Each m As Map In mStatus.EmojiReactions
		Dim IsMe As Boolean = m.Get("me") = True
		Dim action As String
		If IsMe Then
			action = "~emoji_delete:"
		Else
			action ="~emoji_put:"
		End If
		Dim r As BCTextRun = tu.CreateUrlRun(action & m.Get("name") , m.Get("name") & tu.NBSP & m.Get("count"), BBListItem1.ParseData)
		r.TextColor = GetIsUserColor(IsMe)
		Runs.Add(r)
		Runs.Add(tu.TextEngine.CreateRun("  "))
	Next
End Sub


Private Sub FavouriteClick
	XUIViewsUtils.PerformHapticFeedback(BBBottom.mBase)
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then Return
	B4XPages.MainPage.ShowProgress
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses/${mStatus.id}/"$
	If mStatus.Favourited Then
		link = link & "unfavourite"
	Else
		link = link & "favourite"
	End If
	Dim s As PLMStatus = mStatus
	Dim j As HttpJob
	j.Initialize("", Me)
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

Private Sub EmojiClick (url As String)
	XUIViewsUtils.PerformHapticFeedback(BBBottom.mBase)
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then Return
	B4XPages.MainPage.ShowProgress
	Dim emoji As String = url.SubString(url.IndexOf(":") + 1)
	Dim su As StringUtils
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/pleroma/statuses/${mStatus.id}/reactions/${su.EncodeUrl(emoji, "utf8")}"$
	Dim j As HttpJob
	j.Initialize("", Me)
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
			SetBBListContent
			BBListItem1.UpdateLastVisibleRegion
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
		End If
	Next
	BBListItem1.ChangeVisibility(visible)
	bbTop.ChangeVisibility(visible)
End Sub

Private Sub SetTopText
	bbTop.PrepareBeforeRuns
	Dim runs As List
	runs.Initialize
	If mStatus.ExtraContent.IsInitialized And mStatus.ExtraContent.ContainsKey("reblog") Then
		Dim reblog As PLMAccount = mStatus.ExtraContent.Get("reblog")
		runs.Add(tu.CreateRun(Chr(0xF079) & " ", xui.CreateFontAwesome(12)))
		runs.Add(tu.CreateUrlRun("@@" &reblog.Id, "by " & reblog.Acct, bbTop.ParseData))
		runs.Add(mTextEngine.CreateRun(CRLF))
		For i = 0 To runs.Size - 1
			Dim r As BCTextRun = runs.Get(i)
			r.TextColor = Constants.ColorDefaultText
			If i > 0 Then r.TextFont = TopFont
		Next
	End If
	tu.TextWithEmojisToRuns(mStatus.Account.DisplayName & " ", runs, mStatus.Account.Emojis, bbTop.ParseData, bbTop.ParseData.DefaultBoldFont)
	Dim r As BCTextRun = tu.CreateUrlRun("@", mStatus.Account.Acct, bbTop.ParseData)
	r.TextFont = TopFont
	runs.Add(r)
	If mStatus.InReplyToAccountAcct <> "" Then
		runs.Add(mTextEngine.CreateRun(CRLF))
		Dim r As BCTextRun = tu.CreateUrlRun("~time", "" & Chr(0xF064) & " Reply to", bbTop.ParseData)
		r.TextFont = xui.CreateFontAwesome(12)
		r.TextColor = Constants.ColorDefaultText
		runs.Add(r)
		runs.Add(mTextEngine.CreateRun(" "))
		r = tu.CreateUrlRun("@@" & mStatus.InReplyToAccountId, mStatus.InReplyToAccountAcct, bbTop.ParseData)
		r.TextFont = TopFont
		r.TextColor = Constants.ColorDefaultText
		runs.Add(r)
	End If
	bbTop.SetRuns(runs)
	bbTop.UpdateVisibleRegion(0, 300dip)
End Sub

Private Sub SetBottomPanel
	BBBottom.PrepareBeforeRuns
	Dim fnt As B4XFont = xui.CreateFontAwesome(15)
	Dim runs As List
	runs.Initialize
	Dim r As BCTextRun
	r = tu.CreateUrlRun("~replies",  " " & Chr(0xF112) & CountToString(mStatus.RepliesCount) & " ", BBBottom.ParseData)
	r.TextColor = GetIsUserColor(False)
	runs.Add(r)
	runs.Add(mTextEngine.CreateRun(TAB))
	r = tu.CreateUrlRun("~favourites",  " " & Chr(0xF006) & CountToString(mStatus.FavouritesCount) & " ", BBBottom.ParseData)
	r.TextColor = GetIsUserColor(mStatus.Favourited)
	runs.Add(r)
	runs.Add(mTextEngine.CreateRun(TAB))
	r = tu.CreateUrlRun("~reblog", " " &  Chr(0xF079) & CountToString(mStatus.ReblogsCount) & " ", BBBottom.ParseData)
	r.TextColor = GetIsUserColor(mStatus.Reblogged)
	runs.Add(r)
	For Each r As BCTextRun In runs
		r.TextFont = fnt
	Next
	BBBottom.SetRuns(runs)
	BBBottom.UpdateVisibleRegion(0, 300dip)
End Sub

Private Sub GetIsUserColor(b As Boolean) As Int
	If b Then Return Constants.ColorAlreadyTookAction Else Return Constants.ColorDefaultText
End Sub

Private Sub CountToString (c As Int) As String
	If c > 0 Then Return " " & c
	Return ""
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
	If mStatus.ExtraContent.IsInitialized And mStatus.ExtraContent.ContainsKey("card") Then
		CardAttachment(mStatus.ExtraContent.Get("card"), h)
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
	cv.SetCard(card, mCallBack, mEventName)
	parent.Height = cv.base.Height
	h(0) = h(0) - 100dip + cv.base.Height
End Sub

Private Sub ImageAttachment (attachment As PLMMedia, h() As Int)
	Dim iv As B4XView = B4XPages.MainPage.CreateImageView
	Dim Parent As B4XView = CreateAttachmentPanel(attachment, h, MediaSize, 30dip, iv.Tag)
	Parent.AddView(iv, 0, 0, 0, 0)
	Dim url As String = attachment.PreviewUrl
	If mStatus.Sensitive Then url = B4XPages.MainPage.ImagesCache1.NSFW_URL
	ImagesCache1.SetImage(url, iv.Tag, ImagesCache1.RESIZE_FILLWIDTH)
	If mStatus.Sensitive Then B4XPages.MainPage.ImagesCache1.HoldAnotherImage(attachment.PreviewUrl, iv.Tag)
End Sub

Private Sub CreateAttachmentPanel (att As PLMMedia, h() As Int, Height As Int, SideGap As Int, Consumer As ImageConsumer) As B4XView
	Dim Parent As B4XView = xui.CreatePanel("AttachmentParent")
	Parent.Color = 0xFFF5F5F5
	If Consumer <> Null Then
		Consumer.PanelColor = xui.Color_White
	End If
	Parent.Tag = att
	pnlMedia.AddView(Parent, SideGap, h(0) + 10dip, pnlMedia.Width - 2 * SideGap, Height)
	h(0) = h(0) + Height + 10dip
	Return Parent
End Sub

Private Sub VideoAttachment (attachment As PLMMedia, h() As Int)
	If xui.IsB4J Then Return
	Dim iv As B4XView = B4XPages.MainPage.CreateImageView
	Dim Parent As B4XView = CreateAttachmentPanel(attachment, h, MediaSize, 2dip, iv.Tag)
	Dim playerview As B4XView = B4XPages.MainPage.ViewsCache1.GetVideoPlayer
	Parent.AddView(playerview, 0, 0, Parent.Width, Parent.Height)
	Parent.AddView(iv, Parent.Width / 2 - 40dip, Parent.Height / 2 - 30dip, 80dip, 60dip)
	If mStatus.Sensitive Then
		ImagesCache1.SetImage(B4XPages.MainPage.ImagesCache1.NSFW_URL, iv.Tag, ImagesCache1.RESIZE_FILLWIDTH)
	Else
		B4XPages.MainPage.ImagesCache1.SetImage(B4XPages.MainPage.ImagesCache1.PLAY, iv.Tag, ImagesCache1.RESIZE_NONE)
	End If
	#if B4A
	Dim player As SimpleExoPlayer = playerview.Tag
	player.Prepare(player.CreateUriSource(attachment.Url))
	#else if B4i
	Dim player As VideoPlayer = playerview.Tag
	player.LoadVideoUrl(attachment.Url)
	#end if
End Sub

#if B4J
Private Sub AttachmentParent_MouseClicked (EventData As MouseEvent)
#else
Private Sub AttachmentParent_Click
#End If
	Dim Parent As B4XView = Sender
	Dim attachment As PLMMedia = Parent.Tag
	If attachment.TType = "image" Then
		CallSubDelayed2(mCallBack, mEventName & "_ShowLargeImage", attachment.Url)
	Else If attachment.TType = "video" Then
		Parent.GetView(1).Visible = False
		ToggleVideo(Parent.GetView(0))
	End If
End Sub

Private Sub ToggleVideo (PlayerView As B4XView) 'ignore
#if B4A or B4i
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
	End If
#end if
End Sub


Private Sub BBTOP_LinkClicked (URL As String, Text As String)
	BBListItem1_LinkClicked(URL, Text)
End Sub

Private Sub BBListItem1_LinkClicked (URL As String, Text As String)
	If URL.StartsWith("~emoji") Then
		EmojiClick(URL)
	Else
		CallSub2(mCallBack, mEventName & "_LinkClicked", tu.ManageLink(mStatus, mStatus.Account, URL, Text))
	End If
End Sub

Private Sub BBBottom_LinkClicked (URL As String, Text As String)
	
	If URL.StartsWith("~favourites") Then
		FavouriteClick
	End If
End Sub

Private Sub lblTime_Click
	BBListItem1_LinkClicked("~time", "")
End Sub

Public Sub RemoveFromParent
	B4XPages.MainPage.ImagesCache1.ReleaseImage(imgAvatar.Tag)
	B4XPages.MainPage.ImagesCache1.RemovePanelChildImageViews(pnlMedia)
	For i = 0 To pnlMedia.NumberOfViews - 1
		Dim parent As B4XView = pnlMedia.GetView(i)
		Dim attachment As PLMMedia = parent.Tag
		If attachment.TType = "video" Then
			Dim playerview As B4XView = parent.GetView(0)
				#if B4A
				Dim player As SimpleExoPlayer = playerview.Tag
				player.Pause
				#Else If B4i
				Dim player As VideoPlayer = playerview.Tag
				player.Pause
				#End If
			playerview.RemoveViewFromParent
			B4XPages.MainPage.ViewsCache1.ReturnVideoPlayer(playerview)
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
	Dim DeltaSeconds As Int = (DateTime.Now - mStatus.CreatedAt) / DateTime.TicksPerSecond
	Dim s As String
	Select True
		Case DeltaSeconds < 30
			s = "now"
		Case DeltaSeconds < 3600
			s = $"$1.0{DeltaSeconds / 60}m"$
		Case DeltaSeconds < 3600 * 24
			s = $"$1.0{DeltaSeconds / 3600}h"$
		Case DeltaSeconds < 3600 * 24 * 30
			s = $"$1.0{DeltaSeconds / 3600 / 24}d"$
		Case Else
			s = $"$1.0{DeltaSeconds / 3600 / 24 / 30}mo"$
	End Select
	lblTime.Text = s
	
End Sub

#if B4J
Private Sub imgAvatar_MouseClicked (EventData As MouseEvent)
#else
Private Sub imgAvatar_Click
#end if
	If mStatus.IsInitialized Then
		CallSub2(mCallBack, mEventName & "_AvatarClicked", mStatus.Account)
	End If
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub


