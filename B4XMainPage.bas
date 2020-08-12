B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.31
@EndOfDesignText@
#Region Shared Files Synchronization
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'github desktop ide://run?file=%WINDIR%\System32\cmd.exe&Args=/c&Args=github&Args=..\..\


Sub Class_Globals
	Type PLMServer (URL As String, Name As String, AppClientId As String, AppClientSecret As String, _
		AccessToken As String)
	Type PLMUser (AccessToken As String, TypeVersion As Float, _
		ServerName As String, MeURL As String, DisplayName As String, Avatar As String, _
		SignedIn As Boolean, Id As String)
	Public LINKTYPE_TAG = 1, LINKTYPE_USER = 2, LINKTYPE_OTHER = 3, LINKTYPE_TIMELINE = 4, LINKTYPE_THREAD = 5 As Int
	Private Root As B4XView 'ignore
	Private xui As XUI 'ignore
	Public TextUtils1 As TextUtils
	Public Statuses As ListOfStatuses
	Public ImagesCache1 As ImagesCache
	Public ViewsCache1 As ViewsCache
	Public VERSION As Float = 1.09
	Public store As KeyValueStore
	Public auth As OAuth
	Public User As PLMUser
	Public AppName As String = "B4X Pleroma"
	Private pnlList As B4XView
	Public Drawer As B4XDrawer
	Private HamburgerIcon As B4XBitmap
	
	Public Servers As B4XOrderedMap
	Private DefaultServer As String = "mas.to"
	Private Dialog As B4XDialog
	Private lstTemplate As B4XListTemplate
	Private PrefDialog As PreferencesDialog
	Public LINK_PUBLIC, LINK_HOME As PLMLink
	Public URL_TAG As String = "/api/v1/timelines/tag/"
	Public URL_USER As String = "/api/v1/accounts/:id"
	Public URL_THREAD As String = "/api/v1/statuses/:id/context"
	
	Private AccountView1 As AccountView
	Private wvdialog As WebViewDialog
	#if B4i
	Private FeedbackGenerator As NativeObject
	#End If
	Private DialogContainer As B4XView
	Private DialogListOfStatuses As ListOfStatuses
	Private DialogBtnExit As B4XView
	Private DialogIndex As Int
	Private DrawerManager1 As DrawerManager
End Sub

Public Sub Initialize
	Log($"Version:${NumberFormat2(VERSION, 0, 2, 2, False)}"$)
	xui.SetDataFolder("b4x_pleroma")
	Servers.Initialize
	store.Initialize(xui.DefaultFolder, "store.dat")
	TextUtils1.Initialize
	ImagesCache1.Initialize
	ViewsCache1.Initialize
	auth.Initialize(Me, "auth")
	xui.SetDataFolder("B4X_Pleroma")
	CreateInitialLinks
	LoadSavedData
	#if B4I
	FeedbackGenerator.Initialize("UIImpactFeedbackGenerator")
	If FeedbackGenerator.IsInitialized Then
		FeedbackGenerator = FeedbackGenerator.RunMethod("alloc", Null).RunMethod("initWithStyle:", Array(0)) 'light
	End If
	#End If
	
End Sub

Private Sub CreateInitialLinks
	LINK_PUBLIC = TextUtils1.CreatePLMLink("/api/v1/timelines/public", LINKTYPE_TIMELINE, NumberFormat2(B4XPages.MainPage.VERSION, 0, 2, 2, False))
	LINK_HOME = TextUtils1.CreatePLMLink("/api/v1/timelines/home", LINKTYPE_TIMELINE, "Home")
End Sub

Private Sub LoadSavedData
'	store.Remove("user")
'	store.Remove("servers")
	If store.ContainsKey("servers") Then
		Dim s As List = store.Get("servers")
		For Each server As PLMServer In s
			Servers.Put(server.Name, server)
		Next
	Else
		CreateServersList
		PersistUserAndServers
	End If
	If store.ContainsKey("user") Then
		User = store.Get("user")
		If User.SignedIn = True Then
			VerifyUser
		End If
	Else
		User = CreateNewUser
		PersistUserAndServers
	End If
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Drawer.Initialize(Me, "Drawer", Root, 200dip)
	Drawer.CenterPanel.LoadLayout("MainPage")
	DrawerManager1.Initialize(Drawer)
	#if B4A
	Drawer.ExtraWidth = 30dip
	#end if
	Statuses.Initialize(Me, "Statuses", pnlList)
	HamburgerIcon = xui.LoadBitmapResize(File.DirAssets, "hamburger.png", 32dip, 32dip, True)
	B4XPages.SetTitle(Me, AppName)
	#if B4A
	Dim cs As CSBuilder
	Dim mi As B4AMenuItem = B4XPages.AddMenuItem(Me, cs.Initialize.Typeface(Typeface.FONTAWESOME).Size(20).Append(Chr(0xF021)).PopAll)
	mi.AddToBar = True
	mi.Tag = "refresh"
	#Else if B4i
	Dim bb As BarButton
	bb.InitializeBitmap(HamburgerIcon, "hamburger")
	B4XPages.GetNativeParent(Me).TopLeftButtons = Array(bb)
	bb.InitializeText("" & Chr(0xF021), "refresh")
	bb.SetFont(Font.CreateFontAwesome(22))
	B4XPages.GetNativeParent(Me).TopRightButtons = Array(bb)
	#Else If B4J
	Dim iv As ImageView
	iv.Initialize("imgHamburger")
	iv.SetImage(HamburgerIcon)
	Drawer.CenterPanel.AddView(iv, 2dip, 2dip, 32dip, 32dip)
	iv.PickOnBounds = True
	#end if
	Dialog.Initialize(Root)
	lstTemplate.Initialize
	PrefDialog.Initialize(Root, AppName, 300dip, 50dip)
	PrefDialog.Dialog.OverlayColor = 0x64000000
	Statuses.Refresh2(User, LINK_PUBLIC, False, False)
	DrawerManager1.UpdateLeftDrawerList
	DialogSetLightTheme
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
End Sub

Private Sub CreateServersList
	For Each ser As PLMServer In Array(CreatePLMServer("https://mas.to/", "mas.to"), CreatePLMServer("https://pleroma.com", "pleroma.com"))
		Servers.Put(ser.Name, ser)
	Next
End Sub

#if B4J
Private Sub imgHamburger_MouseClicked (EventData As MouseEvent)
	Drawer.LeftOpen = True
End Sub
#else

Private Sub B4XPage_MenuClick (Tag As String)
	If Tag = "hamburger" Then
		Drawer.LeftOpen = Not(Drawer.LeftOpen)
	Else If Tag = "refresh" Then
		btnRefresh_Click
	End If
End Sub
#end if

Private Sub CreateNewUser As PLMUser
	Dim u As PLMUser
	u.Initialize
	u.ServerName = DefaultServer
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
	store.Put("servers", Servers.Values)
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	#if B4A
	'home button
	If Main.ActionBarHomeClicked Then
		Drawer.LeftOpen = Not(Drawer.LeftOpen)
		Return False	
	End If
	'back key
	If Drawer.LeftOpen Then
		Drawer.LeftOpen = False
		Return False
	End If
	If Dialog.Visible Then
		Dialog.Close(xui.DialogResponse_Cancel)
		Return False
	End If
	Return Statuses.BackKeyPressedShouldClose
	#end if
	Return True 'ignore
End Sub

Private Sub B4XPage_Appear
	#if B4A
	Sleep(0)
	B4XPages.GetManager.ActionBar.RunMethod("setDisplayHomeAsUpEnabled", Array(True))
	Dim bd As BitmapDrawable
	bd.Initialize(HamburgerIcon)
	B4XPages.GetManager.ActionBar.RunMethod("setHomeAsUpIndicator", Array(bd))
	auth.CallFromResume(B4XPages.GetNativeParent(Me).GetStartingIntent)
	#End If
	Drawer.LeftOpen = False
End Sub

Private Sub B4XPage_Disappear
	#if B4A
	B4XPages.GetManager.ActionBar.RunMethod("setHomeAsUpIndicator", Array(0))
	#end if
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	Drawer.Resize(Width, Height)
End Sub



Public Sub SignIn
	lstTemplate.Options = Servers.Keys
	Dialog.Title = "Select Server"
	Dialog.ButtonsHeight = 40dip
	lstTemplate.Resize(300dip, 150dip)
	lstTemplate.CustomListView1.AsView.Height = 150dip
	Wait For (Dialog.ShowTemplate(lstTemplate, "", "", "Cancel")) Complete (Result As Int)
	If Result = xui.DialogResponse_Cancel Then
		Return
	End If
	User.ServerName = lstTemplate.SelectedItem
	If GetServer.AppClientSecret = "" Then
		Wait For (auth.RegisterApp) Complete (Success As Boolean)
		If Success = False Then
			ShowMessage("Error registering app.")
			Return
		Else
			PersistUserAndServers
		End If
	End If
	auth.SignIn(User)
	Wait For Auth_SignedIn (Success As Boolean)
	If Success Then
		AfterSignIn
	Else
		ShowMessage("Failed to sign in.")
		User.SignedIn = False
		Dim server As PLMServer = GetServer
		server.AppClientSecret = ""
	End If
End Sub

Public Sub SignOut
	User.SignedIn = False
	User.DisplayName = ""
	User.AccessToken = ""
	PersistUserAndServers
	Statuses.Stack.Clear
	Statuses.Refresh2(User, LINK_PUBLIC, False, False)
	DrawerManager1.UpdateLeftDrawerList
End Sub

Private Sub ShowMessage(str As String)
	xui.MsgboxAsync(str, AppName)
End Sub

Private Sub VerifyUser
	Wait For (auth.VerifyUser) Complete (Success As Boolean)
	If Success Then
		AfterSignIn
	End If
End Sub

Private Sub AfterSignIn
	Log("after sign in!")
	User.SignedIn = True
	PersistUserAndServers
	Statuses.Stack.Clear
	Statuses.Refresh2(User, LINK_HOME, False, False)
	DrawerManager1.SignIn
	DrawerManager1.UpdateLeftDrawerList
End Sub

Public Sub GetServer As PLMServer
	Return Servers.Get(User.ServerName)
End Sub


Public Sub CreatePLMServer (URL As String, Name As String) As PLMServer
	Dim t1 As PLMServer
	t1.Initialize
	t1.URL = URL
	t1.Name = Name
	Return t1
End Sub

Private Sub btnRefresh_Click
	Statuses.Refresh
End Sub


Private Sub DialogSetLightTheme
	Dim TextColor As Int = 0xFF5B5B5B
	Dialog.BackgroundColor = xui.Color_White
	Dialog.ButtonsColor = xui.Color_White
	Dialog.TitleBarColor = 0xFF007EA9
	Dialog.ButtonsTextColor = Dialog.TitleBarColor
	Dialog.BorderColor = xui.Color_Transparent
	
	lstTemplate.CustomListView1.DefaultTextBackgroundColor = xui.Color_White
	lstTemplate.CustomListView1.DefaultTextColor = TextColor
	lstTemplate.CustomListView1.AsView.Color = xui.Color_White
	Dialog.BorderWidth = 0dip
	lstTemplate.CustomListView1.sv.ScrollViewInnerPanel.Color = 0xFFC3C3C3
End Sub

Private Sub Statuses_AvatarClicked (Account As PLMAccount)
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	If AccountView1.IsInitialized = False Then
		AccountView1.Initialize(CreatePanelForDialog, Me, "Statuses")
		AccountView1.mDialog = Dialog
	End If
	AccountView1.SetContent(Account)
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
	Wait For (ShowDialogWithoutButtons(DialogListOfStatuses.Root, False)) Complete (Result As Int)
	For Each v As B4XView In DialogListOfStatuses.Root.GetAllViewsRecursive
		v.Enabled = True
	Next
	DialogListOfStatuses.StopAndClear
End Sub

Private Sub Statuses_LinkClicked (Link As PLMLink)
	B4XPages.MainPage.PerformHapticFeedback
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	LinkClickedShared(Link)
End Sub


Private Sub LinkClickedShared (Link As PLMLink)
	Wait For (ClosePrevDialog) Complete (ShouldReturn As Boolean)
	If ShouldReturn Then Return
	If Link.LINKTYPE = LINKTYPE_OTHER Then
		If wvdialog.IsInitialized = False Then
			wvdialog.Initialize(CreatePanelForDialog)
		End If
		wvdialog.Show(Dialog, Link)
		Wait For (ShowDialogWithoutButtons(wvdialog.mParent, False)) Complete (Result As Int)
		wvdialog.Close
	Else If Link.LINKTYPE = LINKTYPE_THREAD Then
		ShowThreadInDialog(Link)
	Else
		Statuses.Refresh2(User, Link, True, False)
	End If
End Sub

Private Sub ClosePrevDialog As ResumableSub
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
	Dialog.VisibleAnimationDuration = 500
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
		DialogContainer.AddView(pnl, 0, 0, DialogContainer.Width, DialogContainer.Height)
		DialogBtnExit.BringToFront
	End If
	DialogBtnExit.Top = DialogContainer.Height - DialogBtnExit.Height
	Dim rs As Object = Dialog.ShowCustom(DialogContainer, "", "", "")
	Dialog.VisibleAnimationDuration = 0
	#if B4i
	Statuses.RemoveClickRecognizer(Dialog.Base)
	#End If
	Wait For (rs) Complete (Result As Int)
	pnl.RemoveViewFromParent
	If xui.IsB4J Then Statuses.Root.RequestFocus
	Return Result
End Sub


Private Sub CreatePanelForDialog As B4XView
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, Root.Width * 0.9, Root.Height * 0.9)
	Return pnl
End Sub

Public Sub ShowExternalLink (link As String)
	#if B4J
	Dim fx As JFX
	fx.ShowExternalDocument(link)
	#else if B4A
	Dim pi As PhoneIntents
	StartActivity(pi.OpenBrowser(link))
	#else if B4i
	Main.App.OpenURL(link)
	#end if
End Sub

Public Sub PerformHapticFeedback
   #if B4A
	Dim jo As JavaObject = Root
	jo.RunMethod("performHapticFeedback", Array(1))
	#Else if B4i
	If FeedbackGenerator.IsInitialized Then
		FeedbackGenerator.RunMethod("impactOccurred", Null)
	End If
	#end if
End Sub

Private Sub Statuses_TitleChanged (Title As String)
	Dim st As ListOfStatuses = Sender
	If st = DialogListOfStatuses Then Return
	B4XPages.SetTitle(Me, AppName & " - " & Title)
	DrawerManager1.StackChanged
End Sub


Private Sub DialogBtnExit_Click
	Dialog.Close(xui.DialogResponse_Cancel)
End Sub