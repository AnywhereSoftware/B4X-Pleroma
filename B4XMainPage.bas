﻿B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.31
@EndOfDesignText@
#Region Shared Files Synchronization
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'github desktop ide://run?file=%WINDIR%\System32\cmd.exe&Args=/c&Args=github&Args=..\..\


Sub Class_Globals
	Type PLMServer (URL As String, Name As String, AppClientId As String, AppClientSecret As String, _
		AccessToken As String)
	
	Type PLMUser (AccessToken As String, TypeVersion As Float, _
		ServerName As String, MeURL As String, DisplayName As String, Avatar As String, _
		SignedIn As Boolean, Id As String, Note As String, Acct As String, Verified As Boolean)
	Type PLMResult (Success As Boolean, ErrorMessage As String)
	Public Root As B4XView 'ignore
	Private xui As XUI 'ignore
	Public TextUtils1 As TextUtils
	Public Statuses As ListOfStatuses
	Public ImagesCache1 As ImagesCache
	Public ViewsCache1 As ViewsCache
	Public store As KeyValueStore
	Public auth As OAuth
	Public User As PLMUser
	Private pnlList As B4XView
	Public Drawer As B4XDrawer

	Public Dialog As B4XDialog
	Public Dialog2 As B4XDialog
	Private AccountView1 As AccountView
	Private wvdialog As WebViewDialog 'ignore
	Private DialogContainer As B4XView
	Private DialogListOfStatuses As ListOfStatuses
	Private DialogBtnExit As B4XView
	Private DialogIndex As Int
	Public DrawerManager1 As DrawerManager
	Public Toast As BCToast
	Private AnotherProgressBar1 As AnotherProgressBar
	Private ProgressCounter As Int
	Public MadeWithLove1 As MadeWithLove
	Private Search As SearchManager
	Private pnlListDefaultTop As Int
	Private SignInIndex As Int
	Public StoreVersion As Float
	Public ServerManager1 As ServerManager
	Private PostView1 As PostView
	Private Dialog2ListTemplate As B4XListTemplate
	#if B4A
	Public Provider As FileProvider
	Private IME As IME 'ignore
	#End If
	Public B4iKeyboardHeight As Int
	Public B4AKeyboardActivityHeight As Int
	Public push1 As Push
	Public LinksManager As B4XLinksManager
	Public MediaChooser1 As MediaChooser
	Public Settings As PLMSettings
	Public ServerSupportsEmojiReactions As Boolean
	#if B4i
	Public safari As SafariController
	#End If
	Public Report As ReportManager
	Public Theme As ThemeManager
	Public Stream As Streamer
	Private HamburgerIcons As Map
	Private Const HamburgerState_Close = 1, HamburgerState_Default = 2, HamburgerState_Notification_Large = 3, HamburgerState_Notification_Small = 4, _
		HamburgerState_Invalid = 5 As Int
	#if B4J
	Private ivHamburger As ImageView
	#End If
	Private UpdateHamburgerIconIndex As Int
	Private HamburgerState As Int = HamburgerState_Invalid
	Private B4XImageView1 As B4XImageView
	Public Sound As X2SoundPool
	Public Background As Boolean = True
	Public ServerFeatures As PLMInstanceFeatures
End Sub

Public Sub Initialize
	Log($"Version:${NumberFormat2(Constants.Version, 0, 2, 2, False)}"$)
	xui.SetDataFolder("b4x_pleroma")
	Settings.Initialize
	TextUtils1.Initialize
	LinksManager.Initialize
	Constants.Initialize
	ServerManager1.Initialize
	HamburgerIcons.Initialize
	store.Initialize(xui.DefaultFolder, "store.dat")
	
	StoreVersion = store.GetDefault("version", 0)
	Log($"Store version:${NumberFormat2(StoreVersion, 0, 2, 2, False)}"$)
	If StoreVersion < Constants.Version Then
		UpdateOldStore
	End If
	store.Put("version", Constants.VERSION)
	Settings.LoadFromStore(store, StoreVersion)
	Theme.Initialize(File.ReadString(File.DirAssets, "theme.json"))
	ServerManager1.AfterThemeCreated
	ImagesCache1.Initialize
	ViewsCache1.Initialize
	auth.Initialize(Me, "auth")
	#if B4A
	Provider.Initialize
	#End If
	Constants.Initialize
	push1.Initialize
	Report.Initialize
	Theme.RegisterForEvents(Me)
	Stream.Initialize
	Stream.LoadFromStore(store)
	B4XPages.GetManager.TransitionAnimationDuration = 0
	Sound.Initialize
	Sound.AddSound(Constants.SOUND_MESSAGE, File.DirAssets, "message.wav")
	ServerFeatures.Initialize
End Sub

Private Sub UpdateOldStore
	If StoreVersion < 1.30 Then store.Remove("stack")
End Sub

Private Sub Theme_Changed
	DialogSetTheme(Dialog2)
	SetListTemplateTheme
	DialogSetTheme (Dialog)
	Toast.pnl.Color = Theme.DefaultText
	Toast.DefaultTextColor = Theme.Background
	DialogContainer.Color = 0
	'Background pattern from Toptal Subtle Patterns (https://www.toptal.com/designers/subtlepatterns)
	If Theme.IsDark Then
		B4XImageView1.Bitmap = xui.LoadBitmap(File.DirAssets, "tile-dark.png")
	Else
		
		B4XImageView1.Bitmap = xui.LoadBitmap(File.DirAssets, "tile.png")
	End If
End Sub


Private Sub LoadSavedDataAndStart
	ServerManager1.LoadFromStore(store)
	If store.ContainsKey("user") Then
		User = store.Get("user")
		User.Verified = False
	Else
		User = CreateNewUser
		PersistUserAndServers
		SignOut
	End If
	If User.SignedIn = True Then
		VerifyUser
	Else
		SignOut
	End If
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Drawer.Initialize(Me, "Drawer", Root, 200dip)
	Drawer.CenterPanel.LoadLayout("MainPage")
	DrawerManager1.Initialize(Drawer)
#if B4i
Dim no As NativeObject = B4XPages.GetNativeParent(Me)
no.RunMethod("addWillHide", Null)
#End If
	#if B4A
	Drawer.ExtraWidth = 30dip
	#end if
	B4AKeyboardActivityHeight = Root.Height
	Statuses.Initialize(Me, "Statuses", pnlList)
	Statuses.TiedDrawer = DrawerManager1
	HamburgerIcons.Put(HamburgerState_Default, xui.LoadBitmapResize(File.DirAssets, "hamburger.png", 32dip, 32dip, True))
	HamburgerIcons.Put(HamburgerState_Notification_Large, xui.LoadBitmapResize(File.DirAssets, "hamburger_notif.png", 32dip, 32dip, True))
	HamburgerIcons.Put(HamburgerState_Notification_Small, xui.LoadBitmapResize(File.DirAssets, "hamburger_notif_small.png", 32dip, 32dip, True))
	HamburgerIcons.Put(HamburgerState_Close, xui.LoadBitmapResize(File.DirAssets, "close_icon.png", 32dip, 32dip, True))
	B4XPages.SetTitle(Me, Constants.AppName)
	MediaChooser1.Initialize
	CreateMenu
	Dialog.Initialize(Root)
	If store.ContainsKey("stack") Then
		Statuses.Stack.SetDataFromStore(store.Get("stack"))
	End If
	DrawerManager1.UpdateLeftDrawerList
	Dialog2.Initialize(Root)
	Dialog2ListTemplate.Initialize
	If Root.Width = 0 Then
		Wait For B4XPage_Resize (Width As Int, Height As Int)
		Drawer.Resize(Width, Height)
	End If
	DialogContainer = CreatePanelForDialog
	DialogContainer.LoadLayout("DialogContainer")
	#if B4J
	Dim InnerPanel As B4XView = xui.CreatePanel("")
	Dim sp As ScrollPane = DialogContainer.GetView(0)
	sp.InnerNode = InnerPanel
	InnerPanel.SetLayoutAnimated(0, 0, 0, DialogContainer.Width, DialogContainer.Height)
	#End If
	Toast.Initialize(Root)
	Toast.DurationMs = Constants.ToastDurationMs
	pnlListDefaultTop = pnlList.Top
	Search.Initialize(Root.Width)
	LoadSavedDataAndStart
	Theme_Changed
	ShowMadeWithLove
End Sub

Private Sub ShowMadeWithLove
	MadeWithLove1.mBase.Color = Theme.OverlayColorMadeWithLove
	Dim xlbl As B4XView = MadeWithLove1.mBase.GetView(0)
	xlbl.TextColor = Theme.DefaultText
	#if B4I
	'changing the text color resets the CSBuilder colors, we need to set it again.
	Dim cs As CSBuilder
	cs.Initialize.Append("Made with ").Font(Font.CreateFontAwesome(xlbl.TextSize)).Color(xui.Color_Red).Append(Chr(0xF004)).Pop.Pop.Append(" in B4X").PopAll
	XUIViewsUtils.SetTextOrCSBuilderToLabel(xlbl, cs)
	#End If
	Sleep(4000)
	MadeWithLove1.mBase.SetVisibleAnimated(300, False)
End Sub

Private Sub CreateMenu
	#if B4A
	Dim cs As CSBuilder
	Dim mi As B4AMenuItem
	mi = B4XPages.AddMenuItem(Me, cs.Initialize.Typeface(Typeface.FONTAWESOME).Size(22).Append(Constants.PlusChar).PopAll)
	mi.AddToBar = True
	mi.Tag = "new post"
	mi = B4XPages.AddMenuItem(Me, cs.Initialize.Typeface(Typeface.FONTAWESOME).Size(20).Append(Chr(0xF021)).PopAll)
	mi.AddToBar = True
	mi.Tag = "refresh"
	mi = B4XPages.AddMenuItem(Me, cs.Initialize.Typeface(Typeface.FONTAWESOME).Size(20).Append(Constants.SearchIconChar).PopAll)
	mi.AddToBar = True
	mi.Tag = "search"
	#Else if B4i
	Dim bb As BarButton
	bb.InitializeSystem(bb.ITEM_REFRESH, "refresh")
	Dim bb2 As BarButton
	bb2.InitializeSystem(bb.ITEM_SEARCH, "search")
	Dim bb3 As BarButton
	bb3.InitializeSystem(bb.ITEM_ADD, "new post")
	B4XPages.GetNativeParent(Me).TopRightButtons = Array(bb2, bb, bb3)
	#Else If B4J
	ivHamburger.Initialize("imgHamburger")
	Drawer.CenterPanel.AddView(ivHamburger, 2dip, 2dip, 32dip, 32dip)
	ivHamburger.PickOnBounds = True
	#end if
	UpdateHamburgerIcon
End Sub


#if B4J
Private Sub imgHamburger_MouseClicked (EventData As MouseEvent)
	ToggleDrawer
End Sub
#else

Private Sub B4XPage_MenuClick (Tag As String)
	If Tag = "hamburger" Then
		ToggleDrawer
	Else If Tag = "refresh" Then
		btnRefresh_Click
	Else If Tag = "search" Then
		btnSearch_Click
	Else If Tag = "new post" Then
		btnPlus_Click
	End If
End Sub
#end if

Private Sub ToggleDrawer
	If Drawer.LeftOpen Then
		Drawer.LeftOpen = False
	Else if CheckAllClosableInterfaces(False, False) Then
	Else
		Drawer.LeftOpen = True
	End If
	UpdateHamburgerIcon
End Sub

Private Sub CreateNewUser As PLMUser
	Dim u As PLMUser
	u.Initialize
	u.ServerName = Constants.DefaultServer
	Return u
End Sub

Public Sub CreateImageView As B4XView
	Dim iv As ImageView
	iv.Initialize("")
	#if b4j
	iv.PreserveRatio = False
	iv.PickOnBounds = True
	#End If
	SetImageViewTag(iv)
	Return iv
End Sub

Public Sub SetImageViewTag(iv As B4XView) As ImageConsumer
	Dim Consumer As ImageConsumer
	Consumer.Initialize
	Consumer.CBitmaps.Initialize
	Consumer.Target = iv
	iv.Tag = Consumer
	Return Consumer
End Sub

Public Sub PersistUserAndServers
	If User.IsInitialized Then
		store.Put("user", User)
	End If
	ServerManager1.SaveToStore(store)
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	#if B4A
	'home button
	If Main.ActionBarHomeClicked Then
		ToggleDrawer
		Return False
	End If
	If CheckAllClosableInterfaces(False, True) Then Return False
	#end if
	Return True 'ignore
End Sub

'Returns true if there is a dialog that can be closed
Private Sub CheckAllClosableInterfaces (OnlyTesting As Boolean, BackButton As Boolean) As Boolean
	If Settings.BackKeyPressed (OnlyTesting) Then
		Return True
	End If
	If Report.BackKeyPressed (OnlyTesting) Then Return True
	'back key
	
	If Drawer.LeftOpen Then
		If OnlyTesting = False Then Drawer.LeftOpen = False
		Return True
	End If
	If AccountView1.IsInitialized And AccountView1.BackKeyPressed(OnlyTesting) Then
		Return True
	End If
	If PostView1.IsInitialized And PostView1.BackKeyPressed(OnlyTesting) Then
		Return True
	End If
	If Dialog2.IsInitialized And Dialog2.Visible Then
		If OnlyTesting = False Then Dialog2.Close(xui.DialogResponse_Cancel)
		Return True
	End If
	If Dialog.IsInitialized And Dialog.Visible Then
		If OnlyTesting = False Then Dialog.Close(xui.DialogResponse_Cancel)
		Return True
	End If
	If Search.IsInitialized And Search.mBase.Parent.IsInitialized Then
		If OnlyTesting = False Then HideSearch
		Return True
	End If
	#if B4i
	If B4iKeyboardHeight > 0 Then
		If OnlyTesting = False Then HideKeyboard
		Return True
	End If
	#end if
	Return Statuses.IsInitialized And Statuses.BackKeyPressedShouldClose(OnlyTesting, BackButton)
End Sub


Private Sub B4XPage_Appear
	#if B4A
	Sleep(0)
	B4XPages.GetManager.ActionBar.RunMethod("setDisplayHomeAsUpEnabled", Array(True))
	HamburgerState = HamburgerState_Invalid
	UpdateHamburgerIcon
	auth.CallFromResume(B4XPages.GetNativeParent(Me).GetStartingIntent)
	#End If
	Drawer.LeftOpen = False
End Sub

Public Sub UpdateHamburgerIcon
	UpdateHamburgerIconIndex = UpdateHamburgerIconIndex + 1
	Dim MyIndex As Int = UpdateHamburgerIconIndex
	If HamburgerState <> HamburgerState_Invalid Then
		Sleep(50)
	End If
	If MyIndex <> UpdateHamburgerIconIndex Then Return
	Dim NewState As Int
	If CheckAllClosableInterfaces(True, False) Then
		NewState = HamburgerState_Close
	Else If LinksManager.LinksWithStreamerEvents.Size > 0 Then
		If LinksManager.LinksWithStreamerEvents.Contains(LinksManager.LINK_CHATS_LIST.URL) Or _
				LinksManager.LinksWithStreamerEvents.Contains(LinksManager.LINK_NOTIFICATIONS.URL) Then
			NewState = HamburgerState_Notification_Large
		Else
			NewState = HamburgerState_Notification_Small
		End If
	Else
		NewState = HamburgerState_Default
	End If
	If NewState = HamburgerState Then Return
	HamburgerState = NewState
	SetHamburgerIcon
End Sub

Private Sub SetHamburgerIcon
	Dim icon As B4XBitmap = HamburgerIcons.Get(HamburgerState)
	#if B4A
	Dim bd As BitmapDrawable
	bd.Initialize(icon)
	B4XPages.GetManager.ActionBar.RunMethod("setHomeAsUpIndicator", Array(bd))
	#else if B4i
	Dim bb As BarButton
	If HamburgerState = HamburgerState_Close Then
		bb.InitializeSystem(bb.ITEM_STOP, "hamburger")
	Else
		bb.InitializeBitmap(KeepOriginalColors(icon), "hamburger")
	End If
	B4XPages.GetNativeParent(Me).TopLeftButtons = Array(bb)
	#Else if B4J
	ivHamburger.SetImage(icon)
	#End If
End Sub

#if B4i
Sub KeepOriginalColors(bmp As Bitmap) As Bitmap
	Dim no As NativeObject = bmp
	Return no.RunMethod("imageWithRenderingMode:", Array(1))
End Sub
#End If

Private Sub B4XPage_Disappear
	#if B4A
	B4XPages.GetManager.ActionBar.RunMethod("setHomeAsUpIndicator", Array(0))
	#end if
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	Drawer.Resize(Width, Height)
End Sub



Public Sub SignIn
	SignInIndex = SignInIndex + 1
	Dim MyIndex As Int = SignInIndex
	Wait For (ServerManager1.RequestServerName(Dialog)) Complete (Server As PLMServer)
	If SignInIndex <> MyIndex Or Server.IsInitialized = False Then Return
	Wait For (ServerManager1.VerifyInstanceFeatures(Server)) Complete (Success As Boolean)
	If Success = False Then
		Return
	End If
	User.ServerName = Server.Name
	If Server.AppClientSecret = "" Then
		Wait For (auth.RegisterApp (Server)) Complete (Result As PLMResult)
		If SignInIndex <> MyIndex Then Return
		If Result.Success = False Then
			ShowMessage("Error registering app: " & Result.ErrorMessage)
			Return
		Else
			PersistUserAndServers
		End If
	End If
	auth.SignIn(User, Server)
	Wait For Auth_SignedIn (Result As PLMResult)
	If SignInIndex <> MyIndex Then Return
	If Result.Success Then
		AfterSignIn
	Else
		ShowMessage("Failed to sign in: " & Result.ErrorMessage)
		User.SignedIn = False
		Server.AppClientSecret = ""
		SignOut
	End If
End Sub

Public Sub SignOut
	push1.Unsubscribe
	User.SignedIn = False
	User.DisplayName = ""
	User.AccessToken = ""
	PersistUserAndServers
	Stream.MostRecentNotification = 0
	Statuses.Stack.Clear
	Statuses.Refresh2(User, LinksManager.LINK_LOCAL, False, False)
	DrawerManager1.UpdateLeftDrawerList
End Sub

Public Sub MakeSureThatUserSignedIn As Boolean
	If User.SignedIn = False Then
		B4XPages.MainPage.ShowMessage("Please sign in first")
	End If
	Return User.SignedIn
End Sub

Public Sub ShowMessage(str As String)
	Sleep(0)
	If B4iKeyboardHeight > 0 Then
		Toast.VerticalCenterPercentage = 30
	Else
		Toast.VerticalCenterPercentage = 85
	End If
	Toast.Show($"[plain]${str}[/plain]"$)
	Log("ShowMessage: " & str)
End Sub

Public Sub ConfirmMessage (Message As String) As ResumableSub
	Wait For (Dialog2.Show(Message, "Yes", "", "Cancel")) Complete (Result As Int)
	Return Result
End Sub

Public Sub ConfirmMessage2 (Message As String, Yes As String, Cancel As String, No As String) As ResumableSub
	#if B4i
	HideKeyboard
	#End If
	Wait For (Dialog2.Show(Message, Yes, No, Cancel)) Complete (Result As Int)
	Return Result
End Sub

Public Sub VerifyUser
	Wait For (auth.VerifyUser (GetServer)) Complete (Result As PLMResult)
	If Result.Success Then
		User.Verified = True
		AfterSignIn
	Else
		ShowMessage("Error logging in: " & Result.ErrorMessage)
	End If
End Sub

Private Sub AfterSignIn
	Log("after sign in!")
	User.SignedIn = True
	ServerManager1.AfterSignIn (User.ServerName)
	PersistUserAndServers
	Statuses.Refresh2(User, LinksManager.LINK_HOME, True, False)
	DrawerManager1.SignIn
	DrawerManager1.UpdateLeftDrawerList
	push1.Subscribe
	Stream.UserChanged
End Sub

Public Sub GetServer As PLMServer
	Return ServerManager1.GetServer(User)
End Sub



Private Sub btnRefresh_Click
	'ImagesCache1.LogCacheState
	CloseDialogAndDrawer
	Statuses.Refresh
End Sub

Public Sub CloseDialogAndDrawer
	If Dialog2.Visible Then Dialog2.Close(xui.DialogResponse_Cancel)
	ClosePrevDialog
	Drawer.LeftOpen = False
	UpdateHamburgerIcon
End Sub


Public Sub DialogSetTheme (diag As B4XDialog)
	diag.BackgroundColor = Theme.Background
	diag.ButtonsColor = Theme.Background
	diag.TitleBarColor = Theme.PrefSeparatorColor
	diag.ButtonsTextColor = Theme.Link
	diag.BorderColor = xui.Color_Transparent
	diag.BorderWidth = 0dip
	diag.BodyTextColor = Theme.DefaultText
	diag.OverlayColor = Theme.OverlayColor
	diag.TitleBarTextColor = xui.Color_Black
	diag.BorderCornersRadius = Constants.DialogCornerRadius
End Sub

Private Sub Statuses_AvatarClicked (Account As PLMAccount)
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	If AccountView1.IsInitialized = False Then
		AccountView1.Initialize(CreatePanelForDialog, Me, "Statuses")
		AccountView1.mDialog = Dialog
	End If
	AccountView1.SetContent(Account, Null)
	AccountView1.SetVisibility(True)
	Sleep(100)
	Wait For (ShowDialogWithoutButtons(AccountView1.mBase, True)) Complete (Result As Int)
	AccountView1.RemoveFromParent
End Sub

Private Sub ShowThreadInDialog (Link As PLMLink)
	If DialogListOfStatuses.IsInitialized = False Then
		Dim DialogListOfStatuses As ListOfStatuses
		DialogListOfStatuses.Initialize(Me, "Statuses", CreatePanelForDialog)
	End If 
	DialogListOfStatuses.Refresh2(User, Link, False, False)
	Wait For (ShowDialogWithoutButtons(DialogListOfStatuses.mBase, False)) Complete (Result As Int)
	For Each v As B4XView In DialogListOfStatuses.mBase.GetAllViewsRecursive
		v.Enabled = True
	Next
	DialogListOfStatuses.StopAndClear 
End Sub

Private Sub btnPlus_Click
	If Statuses.feed.mLink.LinkType = Constants.LINKTYPE_CHAT Then
		Statuses.Chat.Focus
		Return
	Else If Statuses.feed.mLink.LinkType = Constants.LINKTYPE_CHATS_LIST Then
		btnSearch_Click
		Return
	End If
	ShowCreatePostInDialog ("", "public")
End Sub

Public Sub ShowCreatePostInDialog (MentionAcct As String, VisibilityKey As String)
	If MakeSureThatUserSignedIn = False Then Return
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	Wait For (ShowAgreeToSafeContent) Complete (Agree As Boolean)
	If Agree = False Then Return
	If PostView1.IsInitialized = False Then
		PostView1.Initialize(Me, "PostView1", Root.Width * 0.95)
	End If
	Dim post As PLMPost = Statuses.feed.CreatePLMPost("", VisibilityKey)
	If MentionAcct <> "" Then post.Mentions.Add(MentionAcct)
	PostView1.SetContent(post, Null)
	If PostView1.mBase.Parent.IsInitialized Then Return
	Dim rs As Object = ShowDialogWithoutButtons(PostView1.mBase, False)
	Sleep(0)
	PostView1.B4XFloatTextField1.RequestFocusAndShowKeyboard
	Wait For (rs) Complete (Result As Int)
	PostView1.RemoveFromParent
End Sub

Public Sub ShowAgreeToSafeContent As ResumableSub
	If Settings.GetUserAgreedToSafeContent = False Then
		Wait For (B4XPages.MainPage.ConfirmMessage2(Constants.UserContentAgreement, "Agree", "Cancel", "")) Complete (Result As Int)
		If Result = xui.DialogResponse_Positive Then
			B4XPages.MainPage.Settings.SetUserAgreed
			Return True
		Else
			Return False
		End If
	End If
	Return True
End Sub

Private Sub Statuses_LinkClicked (Link As PLMLink)
	XUIViewsUtils.PerformHapticFeedback(Root)
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	LinkClickedShared(Link)
End Sub


Private Sub LinkClickedShared (Link As PLMLink)
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	If Link.LINKTYPE = Constants.LINKTYPE_OTHER Then
		#if B4i
		ShowExternalLink(Link.URL)
		#else
		If wvdialog.IsInitialized = False Then
			wvdialog.Initialize(CreatePanelForDialog)
		End If
		wvdialog.Show(Dialog, Link)
		Wait For (ShowDialogWithoutButtons(wvdialog.mParent, False)) Complete (Result As Int)
		wvdialog.Close
		#End If
	Else If Link.LINKTYPE = Constants.LINKTYPE_THREAD Then
		ShowThreadInDialog(Link)
	Else
		Statuses.Refresh2(User, Link, True, False)
	End If
End Sub

Private Sub ClosePrevDialog As ResumableSub
	HideKeyboard
	DialogIndex = DialogIndex + 1
	Dim MyIndex As Int = DialogIndex
	If Dialog.Visible Then
		Dialog.Close(xui.DialogResponse_Cancel)
		Do While Dialog.Visible
			Sleep(100)
		Loop
	End If
	Return MyIndex <> DialogIndex
End Sub


Private Sub ShowDialogWithoutButtons (pnl As B4XView, WithSV As Boolean) As ResumableSub
	Dialog.Title = ""
	Dialog.ButtonsHeight = -1dip
	Dialog.VisibleAnimationDuration = 300
	Dim sv As B4XView = DialogContainer.GetView(0)
	sv.Visible = WithSV
	If WithSV Then
		sv.ScrollViewContentHeight = pnl.Height
		sv.ScrollViewContentWidth = sv.Width
		Dim InnerPanel As B4XView = sv.ScrollViewInnerPanel
		InnerPanel.RemoveAllViews
		InnerPanel.AddView(pnl, 0, 0, InnerPanel.Width, pnl.Height)
		DialogContainer.Height = Min(0.9 * Root.Height, pnl.Height)
		sv.Height = DialogContainer.Height
		sv.ScrollViewOffsetY = 0
	Else
		DialogContainer.SetLayoutAnimated(0, 0, 0, pnl.Width, pnl.Height)
		DialogContainer.AddView(pnl, 0, 0, DialogContainer.Width, pnl.Height)
		DialogBtnExit.BringToFront
	End If
	DialogBtnExit.Top = DialogContainer.Height - DialogBtnExit.Height - 4dip
	Dialog.PutAtTop = True
	Dim rs As Object = Dialog.ShowCustom(DialogContainer, "", "", "")
	Dialog.Base.Parent.Tag = "" 'this will prevent the dialog from closing when the second dialog appears.
	Dialog.VisibleAnimationDuration = 0
	ViewsCache1.SetClipToOutline(Dialog.Base)
	#if B4i
	Statuses.RemoveClickRecognizer(Dialog.Base)
	#End If
	UpdateHamburgerIcon
	Wait For (rs) Complete (Result As Int)
	pnl.RemoveViewFromParent
	If xui.IsB4J Then Statuses.mBase.RequestFocus
	UpdateHamburgerIcon
	Return Result
End Sub


Private Sub CreatePanelForDialog As B4XView
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, Root.Width * 0.95, Root.Height * 0.95)
	Return pnl
End Sub

Public Sub ShowExternalLink (link As String)
	If link.StartsWith("https://") = False And link.StartsWith("http://") = False Then
		Log("Invalid link: " & link)
		Return
	End If
	Try
		#if B4J
		Dim fx As JFX
		fx.ShowExternalDocument(link)
		#else if B4A
		Dim pi As PhoneIntents
		StartActivity(pi.OpenBrowser(link))
		#else if B4i
		safari.Initialize("safari", link)
		Dim no As NativeObject = safari
		safari.TintColor = xui.Color_Red
		no = no.GetField("safari")
	
		no.SetField("preferredBarTintColor", no.ColorToUIColor(Main.NavBarBarTintColor))
		no.SetField("preferredControlTintColor", no.ColorToUIColor(Main.NavBarTintColor))
		safari.Show(B4XPages.GetNativeParent(Me))
	#end if
	Catch
		Log(LastException)
	End Try
End Sub



Private Sub Statuses_LinkUpdated (Link As PLMLink)
	Dim st As ListOfStatuses = Sender
	If st = DialogListOfStatuses Then Return
	LinksManager.LinksWithStreamerEvents.Remove(Link.URL)
	LinksManager.AfterLinksWithStreamerChanged
	B4XPages.SetTitle(Me, Link.Title)
	DrawerManager1.StackChanged
	UpdateHamburgerIcon
End Sub


Private Sub DialogBtnExit_Click
	Dialog.Close(xui.DialogResponse_Cancel)
End Sub

Public Sub ShowProgress
	ProgressCounter = ProgressCounter + 1
	If ProgressCounter = 1 Then
		AnotherProgressBar1.Visible = True
	End If
End Sub

Public Sub HideProgress
	ProgressCounter = Max(0, ProgressCounter - 1)
	If ProgressCounter = 0 Then
		AnotherProgressBar1.Visible = False
	End If
End Sub

Public Sub ResetProgress
	ProgressCounter = 0
	HideProgress
End Sub

Private Sub btnSearch_Click
	CloseDialogAndDrawer
	If Search.mBase.Parent.IsInitialized Then
		Search.mBase.RemoveViewFromParent
	Else
		Dim h As Int = Search.mBase.Height
		Drawer.CenterPanel.AddView(Search.mBase, 0, pnlListDefaultTop - h, Root.Width, Search.mBase.Height)
		Search.mBase.SetLayoutAnimated(100, 0, Search.mBase.Top + h, Search.mBase.Width, h)
		Search.Focus
	End If
	UpdateHamburgerIcon
End Sub

Public Sub HideSearch
	If Search.mBase.Parent.IsInitialized Then
		Search.mBase.RemoveViewFromParent
	End If
End Sub

Private Sub B4XPage_Background
	If store.IsInitialized = False Then Return 
	store.Put("stack", Statuses.Stack.GetDataForStore)
	Stream.SaveToStore(store)
	If ViewsCache1.IsInitialized = False Then Return
	ViewsCache1.StopPlaybackOfOtherVideos(Null)
	Background = True
End Sub

Private Sub B4XPage_Foreground
	Log("foreground")
	Background = False
	Sleep(3000)
	Stream.PeriodicCheck
End Sub

Private Sub PostView1_Close
	If Dialog.Visible Then Dialog.Close(xui.DialogResponse_Cancel)
End Sub

Private Sub PostView1_NewPost (Status As PLMStatus)
	Dialog.close(xui.DialogResponse_Cancel)
	Statuses.Refresh2(User, LinksManager.LINK_HOME, True, False)
	
End Sub

Public Sub ShowListDialog (Options As List, PutAtTop As Boolean) As ResumableSub
	Dialog2ListTemplate.Options = Options
	Dialog2ListTemplate.Resize(200dip, Min(70dip * Options.Size, 250dip))
	Dialog2ListTemplate.CustomListView1.AsView.Height = Dialog2ListTemplate.mBase.Height
	Dialog2.PutAtTop = PutAtTop
	Dim rs As ResumableSub = Dialog2.ShowTemplate(Dialog2ListTemplate, "", "", "Cancel")
	ViewsCache1.SetClipToOutline(Dialog2.Base) 'apply the round corners to the content
	#if B4i
	Sleep(10)
	#End If
	Dialog2ListTemplate.CustomListView1.AsView.Top = -2dip
	UpdateHamburgerIcon
	Wait For (rs) Complete (Result As Int)
	UpdateHamburgerIcon
	If Result = xui.DialogResponse_Positive Then
		Return Dialog2ListTemplate.SelectedItem
	Else
		Return ""
	End If
End Sub

Private Sub SetListTemplateTheme
	If Dialog2ListTemplate.IsInitialized = False Then Return
	ViewsCache1.SetCLVBackground(Dialog2ListTemplate.CustomListView1, False)
	Dim lbl As B4XView = Dialog2ListTemplate.CustomListView1.DesignerLabel
	lbl.Font = xui.CreateFontAwesome(15)
	lbl.SetTextAlignment("CENTER", "LEFT")
End Sub



Private Sub B4XPage_KeyboardStateChanged (Height As Float)
	If B4iKeyboardHeight = Height Then Return
	B4iKeyboardHeight = Height
	If Statuses.IsInitialized And Statuses.Chat.IsInitialized And Statuses.ListGoesUp Then
		Statuses.Chat.KeyboardStateChanged
	End If
	UpdateHamburgerIcon
End Sub

Public Sub getIsKeyboardVisible As Boolean
	Return B4iKeyboardHeight > 0
End Sub

Private Sub IME_HeightChanged(NewHeight As Int, OldHeight As Int)
	#if B4A
	Dim h As Int
	If GetDeviceLayoutValues.Height - NewHeight > 200dip Then
		h = 1
	Else
		h = 0
	End If
	B4AKeyboardActivityHeight = NewHeight
	B4XPage_KeyboardStateChanged(h)
	#End If
End Sub



Public Sub UserDetailsChanged
	Wait For (auth.VerifyUser(GetServer)) Complete (Result As PLMResult)
	Log($"User verified: ${Result.Success}"$)
	If Result.Success Then
		DrawerManager1.UpdateAvatarAndDisplayName
	End If
End Sub


Public Sub CreatePLMResult (Success As Boolean, Exception As Exception) As PLMResult
	If Exception.IsInitialized Then
		Return CreatePLMResult2(Success, Exception.Message)
	Else
		Return CreatePLMResult2(Success, "Unknown")
	End If
End Sub

Public Sub CreatePLMResult2 (Success As Boolean, ErrorMessage As String) As PLMResult
	Dim t1 As PLMResult
	t1.Initialize
	t1.Success = Success
	t1.ErrorMessage = ErrorMessage
	Return t1
End Sub

Public Sub NotificationClicked (chat As Boolean)
	If User.SignedIn = False Then
		Sleep(3000)
	End If
	If User.SignedIn Then
		Sleep(1000)
		If chat Then
			Statuses.Refresh2(User, LinksManager.LINK_CHATS_LIST, True, False)
		Else
			Statuses.Refresh2(User, LinksManager.LINK_NOTIFICATIONS, True, False)
		End If
	End If
End Sub

Private Sub Drawer_StateChanged (Open As Boolean)
	UpdateHamburgerIcon
End Sub

Public Sub HideKeyboard
	#if B4i
	B4XPages.GetNativeParent(Me).ResignFocus
	B4XPage_KeyboardStateChanged(0)
	#Else If B4A
	IME.HideKeyboard
	#End If
End Sub
