B4J=true
Group=ListItems
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
#Event: LinkClicked (URL As String)
Sub Class_Globals
	Private xui As XUI
	Public mBase As B4XView
	Private bbTop As BBListItem
	Private imgAvatar As B4XView
	Private ImageView1 As B4XView
	Private ImagesCache1 As ImagesCache
	Public mDialog As B4XDialog
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Private BBListItem1 As BBListItem
	Private pnlLine As B4XView
	Private mAccount As PLMAccount
	Private btnFollow As B4XView
	Private tu As TextUtils
	Private lblLogOut As B4XView
	Private btnMention As B4XView
	Private pnlCurrentUser As B4XView
	Private lblChangeAvatar As B4XView
	Private PrefDialog As PreferencesDialog
	Private btnMore As B4XView
	Private AccountHolder(1) As PLMAccount
	Private mTheme As ThemeManager
End Sub

Public Sub Initialize (Parent As B4XView, Callback As Object, EventName As String)
	mBase = Parent
	mBase.LoadLayout("AccountView")
	bbTop.TextEngine = B4XPages.MainPage.TextUtils1.TextEngine
	BBListItem1.TextEngine = bbTop.TextEngine
	ImagesCache1 = B4XPages.MainPage.ImagesCache1
	mCallBack = Callback
	mEventName = EventName
	B4XPages.MainPage.ViewsCache1.SetAlpha(ImageView1, 0.3)
	
	B4XPages.MainPage.ViewsCache1.SetCircleClip(imgAvatar.Parent)
	tu = B4XPages.MainPage.TextUtils1
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	Theme_Changed
End Sub

Private Sub Theme_Changed
	mBase.Color = mTheme.Background
	BBListItem1.ParseData.DefaultColor = mTheme.DefaultText
	bbTop.ParseData.DefaultColor = mTheme.DefaultText
	pnlLine.Color = mTheme.Divider
	imgAvatar.Parent.Color = mTheme.AttachmentPanelBackground
	ImageView1.Parent.Color = mTheme.AttachmentPanelBackground
	For Each v As B4XView In pnlCurrentUser.GetAllViewsRecursive
		v.TextColor = mTheme.DefaultText
	Next
	lblChangeAvatar.TextColor = mTheme.DefaultText
End Sub

Public Sub SetContent(Account As PLMAccount, ListItem As PLMCLVItem)
	mAccount = Account
	AccountHolder(0) = mAccount
	Dim mp As B4XMainPage = B4XPages.MainPage
	Dim consumer As ImageConsumer = mp.SetImageViewTag(imgAvatar)
	consumer.IsVisible = True
	mp.SetImageViewTag(ImageView1).IsVisible = True
	Dim tu As TextUtils = B4XPages.MainPage.TextUtils1
	ImagesCache1.SetImage(Account.Avatar, imgAvatar.Tag, ImagesCache1.RESIZE_NONE)
	Dim consumer As ImageConsumer = ImageView1.Tag
	consumer.NoAnimation = True
	consumer.PanelColor = xui.Color_Transparent
	ImagesCache1.SetImage(Account.HeaderURL, ImageView1.Tag, ImagesCache1.RESIZE_FILL_NO_DISTORTIONS)
	tu.SetAccountTopText(bbTop, mAccount, Null, False, Null)
	Dim node As HtmlNode = mp.TextUtils1.HtmlParser.Parse(Account.Note)
	Dim clr As String = mTheme.ColorToHex(mTheme.DefaultText)
	Dim bbcode As String = $"[color=${clr}]
${TableRow(WrapURL("statuses", "Statuses", clr), WrapURL("following", "Following", clr), WrapURL("followers", "Followers", clr))}
${TableRow(Account.StatusesCount, Account.FollowingCount, Account.FollowersCount)}
[/color]
"$
	BBListItem1.PrepareBeforeRuns
	BBListItem1.ParseData.Text = bbcode
	Dim parser As BBCodeParser = BBListItem1.TextEngine.TagParser
	Dim runs As List = parser.CreateRuns(parser.Parse(BBListItem1.ParseData), BBListItem1.ParseData)
	runs.AddAll(tu.HtmlConverter.ConvertHtmlToRuns(node, BBListItem1.ParseData, Account.Emojis))
	For Each run As BCTextRun In runs
		run.HorizontalAlignment = "center"
	Next
	BBListItem1.SetRuns(runs)
	If node.Children.Size = 0 Then BBListItem1.mBase.Height = 51dip
	mBase.Height = ImageView1.Parent.Height + BBListItem1.mBase.Height - 50dip
	BBListItem1.UpdateVisibleRegion(0, 10000)
	pnlLine.Top = mBase.Height - 2dip
	pnlLine.Visible = Not(mDialog.IsInitialized)
	
	btnMention.Visible = True
	btnMore.Visible = True
	pnlCurrentUser.Visible = False
	lblChangeAvatar.Visible = False
	If mAccount.Id = B4XPages.MainPage.User.Id Then CurrentUser
	Wait For (tu.UpdateFollowButton(btnFollow, mAccount, False)) Complete (ShouldUpdate As Boolean)
	If ShouldUpdate Then
		tu.SetAccountTopText(bbTop, mAccount, Null, False, Null)
	End If
End Sub

Private Sub CurrentUser
	pnlCurrentUser.Visible = True
	btnMention.Visible = False
	btnMore.Visible = False
	lblChangeAvatar.Visible = True
End Sub

Private Sub WrapURL(method As String, text As String, clr As String) As String
	Return $"[url=~@${method}:${mAccount.Id}][color=${clr}]${text}[/color][/url]"$
End Sub

Private Sub btnFollow_Click
	tu.FollowButtonClicked(btnFollow, AccountHolder, "follow", False)
End Sub

Private Sub btnMute_Click
	tu.FollowButtonClicked(btnFollow, AccountHolder, "mute", False)
End Sub

Private Sub TableRow(Field1 As String, Field2 As String, Field3 As String) As String
	Return $"[Span MinWidth=25%x Alignment=center][b]${Field1}[/b][/Span][Span MinWidth=25%x Alignment=center][b]${Field2}[/b][/Span][Span MinWidth=25%x Alignment=center][b]${Field3}[/b][/Span]"$
End Sub

Public Sub RemoveFromParent
	ImagesCache1.RemovePanelChildImageViews(mBase)
	mBase.RemoveViewFromParent
	BBListItem1.ReleaseInlineImageViews
	bbTop.ReleaseInlineImageViews
End Sub

Public Sub SetVisibility (visible As Boolean)
	Dim cache As ImagesCache = B4XPages.MainPage.ImagesCache1
	cache.SetConsumerVisibility(imgAvatar.Tag, visible)
	cache.SetConsumerVisibility(ImageView1.Tag, visible)
	BBListItem1.ChangeVisibility(visible)
	bbTop.ChangeVisibility(visible)
End Sub

#if B4J
Private Sub lblExit_MouseClicked (EventData As MouseEvent)
#else
Private Sub lblExit_Click
#end if
	imgAvatar_Click
End Sub


Sub imgAvatar_Click
	If mDialog.IsInitialized Then
		mDialog.Close(xui.DialogResponse_Cancel)
	End If
End Sub

#if B4J
Sub imgAvatar_MouseClicked (EventData As MouseEvent)
	imgAvatar_Click
End Sub
#End If



Private Sub BBTOP_LinkClicked (URL As String, Text As String)
	BBListItem1_LinkClicked(URL, Text)
End Sub

Private Sub BBListItem1_LinkClicked (URL As String, Text As String)
	If URL.StartsWith("~@") Then Text = mAccount.UserName
	RaiseLinkClicked(B4XPages.MainPage.TextUtils1.ManageLink(Null, mAccount, URL, Text))
End Sub

Private Sub RaiseLinkClicked(Link As PLMLink)
	CallSub2(mCallBack, mEventName & "_LinkClicked", Link)
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub


Private Sub lblLogOut_Click
	Wait For (B4XPages.MainPage.ConfirmMessage("Sign out?")) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		B4XPages.MainPage.SignOut
	End If
End Sub

Private Sub lblChangeAvatar_Click
	UploadMedia("avatar")
End Sub

Private Sub lblChangeHeader_Click
	UploadMedia("header")
End Sub

Private Sub UploadMedia (MediaKey As String)
	Wait For (B4XPages.MainPage.MediaChooser1.AddImageFromGallery (lblChangeAvatar)) Complete (pm As PostMedia)
	If pm.IsInitialized Then
		Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
		If j = Null Then Return
		Dim part As MultipartFileData
		part.Initialize
		part.FileName = pm.FileName
		part.KeyName = MediaKey
		Log($"Uploading ${pm.FileName}, size: $1.0{File.Size(pm.FileName, "") / 1024 / 1024} MB"$)
		Dim b() As Byte = tu.CreateMultipart(Null, Array(part))
		j.PatchBytes(B4XPages.MainPage.GetServer.URL & "/api/v1/accounts/update_credentials", b)
		B4XPages.MainPage.auth.AddAuthorization(j)
		j.GetRequest.SetContentType("multipart/form-data; boundary=" & tu.MultipartBoundary)
		j.GetRequest.SetContentEncoding("UTF8")
		Wait For (j) JobDone(j As HttpJob)
		If j.Success Then
			AfterUserUpdate
		Else
			Log("Failed to upload")
			B4XPages.MainPage.ShowMessage("Error uploading attachment: " & j.ErrorMessage)
		End If
		j.Release
		B4XPages.MainPage.HideProgress
	End If
End Sub

Private Sub lblEdit_Click
	If PrefDialog.IsInitialized = False Then
		PrefDialog = B4XPages.MainPage.ViewsCache1.CreatePreferencesDialog("AccountView.json")
	End If
	Dim user As PLMUser = B4XPages.MainPage.user
	Dim m As Map = CreateMap("display_name": user.DisplayName, "note": user.Note)
	Dim rs As Object = PrefDialog.ShowDialog(m, "Ok", "Cancel")
	
	B4XPages.MainPage.ViewsCache1.AfterShowDialog(PrefDialog.Dialog) 'apply the round corners to the content
	Wait For (rs) Complete (Result As Int)
	B4XPages.MainPage.UpdateHamburgerIcon
	If Result = xui.DialogResponse_Positive Then
		Dim note As String = m.Get("note")
		If note = user.Note Then m.Remove("note")
		Dim j As HttpJob = tu.CreateHttpJob(Me, mBase, True)
		Dim jg As JSONGenerator
		jg.Initialize(m)
		j.PatchBytes(B4XPages.MainPage.GetServer.URL & "/api/v1/accounts/update_credentials", jg.ToString.GetBytes("UTF8"))
		B4XPages.MainPage.auth.AddAuthorization(j)
		j.GetRequest.SetContentType("application/json")
		Wait For (j) JobDone(j As HttpJob)
		If j.Success Then
			AfterUserUpdate
		Else
			B4XPages.MainPage.ShowMessage("Error updating profile: " & j.ErrorMessage)
		End If
		j.Release
		B4XPages.MainPage.HideProgress
	End If
End Sub

Private Sub AfterUserUpdate
	B4XPages.MainPage.UserDetailsChanged
	CallSub2(mCallBack, mEventName & "_LinkClicked", tu.ManageLink(Null, mAccount, tu.CreateSpecialUrl("statuses", mAccount.Id), mAccount.UserName))
End Sub



'returns True if the dialog was closed
Public Sub BackKeyPressed (OnlyTesting As Boolean) As Boolean
	If PrefDialog.IsInitialized And PrefDialog.Dialog.Visible Then
		If OnlyTesting = False Then
			PrefDialog.Dialog.Close(xui.DialogResponse_Cancel)
		End If
		Return True
	End If
	Return False
End Sub

Private Sub lblSettings_Click
	B4XPages.MainPage.Settings.ShowSettings
End Sub

Private Sub btnMention_Click
	B4XPages.MainPage.ShowCreatePostInDialog (mAccount.Acct)
End Sub

'current user more options
Private Sub lblMore_Click
	Dim options As List = Array("Mutes", "Blocks")
	Wait For (B4XPages.MainPage.ShowListDialog(options, True)) Complete (Result As String)
	Dim i As Int = options.IndexOf(Result)
	Select i
		Case 0
			RaiseLinkClicked(tu.CreateUserLinkWithMutedOrSimilar(mAccount.Id, mAccount.UserName, "/api/v1/mutes", "mutes"))
		Case 1
			RaiseLinkClicked(tu.CreateUserLinkWithMutedOrSimilar(mAccount.Id, mAccount.UserName, "/api/v1/blocks", "blocks"))
	End Select
End Sub

Private Sub btnMore_Click
	tu.OtherAccountMoreClicked(btnFollow, AccountHolder, False, bbTop, Null, Null)
End Sub