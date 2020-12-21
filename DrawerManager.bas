B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private root As B4XView
	Private lstDrawer As CustomListView
	Private mDrawer As B4XDrawer
	Private mp As B4XMainPage
	Private xui As XUI
	Private UserItem As B4XView
	Private Divider As B4XView
	Private LinksManager As B4XLinksManager
	Private mTheme As ThemeManager
	Private lblSettings As B4XView
End Sub

Public Sub Initialize (Drawer As B4XDrawer)
	mDrawer = Drawer
	mp = B4XPages.MainPage
	root = mDrawer.LeftPanel
	root.LoadLayout("LeftDrawer")
	'create user item
	Divider = xui.CreatePanel("")
	Divider.SetLayoutAnimated(0, 0, 0, lstDrawer.AsView.Width, 4dip)
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	Dim p As B4XView = xui.CreatePanel("")
	Divider.AddView(p, 0, 0, lstDrawer.AsView.Width, Divider.Height)
	LinksManager = B4XPages.MainPage.LinksManager
	Theme_Changed
End Sub


Private Sub lstDrawer_ItemClick (Index As Int, Value As Object)
	mDrawer.LeftOpen = False
	Select Value
		Case "sign in"
			mp.SignIn
		Case ""
		Case Else
			Dim Link As PLMLink = Value
			mp.Statuses.Refresh2(mp.User, Link, True, True)
	End Select
End Sub



#if B4J
Sub lblDrawerClose_MouseClicked (EventData As MouseEvent)
	mDrawer.LeftOpen = False
End Sub
#end if

Public Sub UpdateLeftDrawerList
	lstDrawer.Clear
	Dim weHaveAUser As Boolean = Not(mp.User.SignedIn = False Or UserItem.IsInitialized = False)
	If weHaveAUser = False Then
		AddDrawerItem(0xF090, "Sign in", Null)
		lstDrawer.GetRawListItem(lstDrawer.Size - 1).Value = "sign in"
	Else
		UserItem.RemoveViewFromParent
		UserItem.Color = mTheme.SecondBackground
		lstDrawer.Add(UserItem, mp.TextUtils1.CreateUserLink(mp.User.id, mp.User.DisplayName, "statuses"))
	End If
	If weHaveAUser Then
		AddDrawerItem(0xF015, "Home", LinksManager.LINK_HOME)
		AddDrawerItem(0xF0F3, "Notifications", LinksManager.LINK_NOTIFICATIONS)
	End If
	For Each Link As PLMLink In LinksManager.GetDefaultLinksWithoutHome
		AddDrawerItem(0xF1D7, Link.Title, Link)
	Next
	
	Divider.RemoveViewFromParent
	lstDrawer.Add(Divider, "")
	If mp.Statuses.IsInitialized = False Then Return
	Dim currentlink As PLMLink = mp.Statuses.feed.mLink
	Dim CurrentTitle As String
	If currentlink.IsInitialized And currentlink.Title <> "" Then
		AddLink(currentlink, True)
		CurrentTitle = currentlink.Title
	End If
	Dim Links As List = mp.Statuses.Stack.GetLinks
	Dim bookmarks As B4XSet = mp.Statuses.Stack.BookmarkedTitles
	For Each Link As PLMLink In Links
		If bookmarks.Contains(Link.Title) And CurrentTitle <> Link.Title Then
			AddLink(Link, False)
		End If
	Next
	For i = Links.Size - 1 To 0 Step - 1
		Dim Link As PLMLink = Links.Get(i)
		If bookmarks.Contains(Link.Title) = False And CurrentTitle <> Link.Title Then
			AddLink(Link, False)
		End If
	Next
End Sub

Private Sub AddLink (link As PLMLink, CurrentOne As Boolean)
	If LinksManager.IsRecentLink(link) = False Then Return
	Dim icon As Int = 0
	If link.LINKTYPE = Constants.LINKTYPE_SEARCH Then
		icon = 0xF002
	End If
	AddDrawerItem(icon, link.Title, link)
	Dim p As B4XView = lstDrawer.GetPanel(lstDrawer.Size - 1)
	Dim lbl As B4XView = CreateXLabel ("lblDelete", Chr(0xF00D))
	lbl.Visible = CurrentOne = False
	p.AddView(lbl, lstDrawer.AsView.Width - 2dip - lbl.Width, p.Height / 2 - lbl.Height / 2, lbl.Width, lbl.Height)
	Dim lbl As B4XView = CreateXLabel ("lblBookmark", GetLinkBookmarkIcon(link))
	'there is an assumption that this is the last view (toggle bookmark)
	p.AddView(lbl, lstDrawer.AsView.Width - (2dip + lbl.Width) * 2, p.Height / 2 - lbl.Height / 2, lbl.Width, lbl.Height)
	
End Sub

Private Sub GetLinkBookmarkIcon (Link As PLMLink) As String
	If mp.Statuses.Stack.BookmarkedTitles.Contains(Link.Title) Then
		Return Chr(0xF02E)
	Else
		Return Chr(0xF097)
	End If
End Sub

Private Sub AddDrawerItem (icon As Int, Title As String, Link As PLMLink)
	Dim s As String
	If icon > 0 Then
		s = $"${"" & Chr(icon)}   "$
	End If
	Dim p1 As Int = Title.IndexOf("(") 'ignore 
	Dim p2 As Int = Title.IndexOf2(")", p1 + 1) 'ignore
	
#if B4A or B4i
	If p1 > 0 And p2 > 0 Then
		Dim cs As CSBuilder
		cs.Initialize.Append(s).Append(Title.SubString2(0, p1 - 1)).Append(" ")
		#if B4A
		cs.RelativeSize(0.7)
		#Else If B4i
		cs.Font(Font.CreateNew(11))
		#End If
		cs.Append(Title.SubString(p1)).PopAll
		lstDrawer.AddTextItem(cs, Link)
	Else
		lstDrawer.AddTextItem($"${s}${Title}"$, Link)
	End If
#else if B4J
	lstDrawer.AddTextItem($"${s}${Title}"$, Link)
#End If
	Dim p As B4XView = lstDrawer.GetPanel(lstDrawer.Size - 1)
	p.GetView(0).Width = p.Width - 62dip
	#if B4A
	Dim lbl As Label = p.GetView(0)
	lbl.SingleLine = True
	lbl.Ellipsize = "END"
	#Else If B4i
	Dim lbl As Label = p.GetView(0)
	lbl.Multiline = False
	#End If
	If Link <> Null And LinksManager.LinksWithStreamerEvents.Contains(Link.URL) Then
		Dim circle As B4XView = B4XPages.MainPage.ViewsCache1.CreateNotificationPanel
		p.AddView(circle, p.Width - 20dip, p.Height / 2 - circle.Height / 2, circle.Width, circle.Height)
	End If
End Sub

Private Sub CreateXLabel (EventName As String, Text As String) As B4XView
	Dim lbl As Label
	lbl.Initialize(EventName)
	Dim xlbl As B4XView = lbl
	xlbl.SetLayoutAnimated(0, 0, 0, 30dip, 30dip)
	xlbl.Text = Text
	xlbl.Font = xui.CreateFontAwesome(16)
	xlbl.SetTextAlignment("CENTER", "CENTER")
	xlbl.TextColor = mTheme.DefaultText

'	xlbl.Color = mTheme.Background
	Return xlbl
End Sub

Public Sub SignIn
	If UserItem.IsInitialized = False Then
		Dim UserItem As B4XView = xui.CreatePanel("")
		UserItem.SetLayoutAnimated(0, 0, 0, lstDrawer.AsView.Width, 42dip)
		UserItem.LoadLayout("lstDrawerUser")
		Dim iv As B4XView = mp.CreateImageView
		UserItem.GetView(0).AddView(iv, 0, 0, UserItem.GetView(0).Width, UserItem.GetView(0).Height)
		UserItem.Tag = iv
		Dim consumer As ImageConsumer = iv.Tag
		consumer.IsVisible = True
		consumer.NoAnimation = True
		Theme_Changed
	End If
	UpdateAvatarAndDisplayName
End Sub

Public Sub UpdateAvatarAndDisplayName
	UserItem.GetView(1).Text = mp.User.DisplayName
	Dim iv As B4XView = UserItem.Tag
	mp.ImagesCache1.ReleaseImage(iv.Tag)
	mp.ImagesCache1.SetImage(mp.User.Avatar, iv.Tag, mp.ImagesCache1.RESIZE_NONE)
End Sub

Sub Theme_Changed
	Divider.GetView(0).Color = mTheme.Divider
	root.Color = mTheme.Background
	B4XPages.MainPage.ViewsCache1.SetCLVBackground(lstDrawer, True)
	If UserItem.IsInitialized Then
		UserItem.GetView(1).TextColor = mTheme.DefaultText
		UserItem.GetView(2).TextColor = mTheme.DefaultText
		UserItem.GetView(0).Color = mTheme.AttachmentPanelBackground
	End If
	UpdateLeftDrawerList
End Sub


Public Sub StackChanged
	UpdateLeftDrawerList
End Sub

#if B4J
Private Sub lblDelete_MouseClicked (EventData As MouseEvent)
	Delete(lstDrawer.GetItemFromView(Sender))
	EventData.Consume
End Sub
#Else
Private Sub lblDelete_Click
	Delete(lstDrawer.GetItemFromView(Sender))
End Sub
#End If

#if B4J
Private Sub lblBookmark_MouseClicked (EventData As MouseEvent)
	EventData.Consume
#Else
Private Sub lblBookmark_Click
#End If
	Dim index As Int = lstDrawer.GetItemFromView(Sender)
	Dim link As PLMLink = lstDrawer.GetValue(index)
	mp.Statuses.Stack.ToggleBookmark(link)
	Dim p As B4XView = lstDrawer.GetPanel(index)
	Dim bookmarkLabel As B4XView = p.GetView(p.NumberOfViews - 1)
	bookmarkLabel.Text = GetLinkBookmarkIcon(link)
End Sub


Private Sub Delete(index As Int)
	Dim link As PLMLink = lstDrawer.GetValue(index)
	mp.Statuses.Stack.Delete(link)
	lstDrawer.RemoveAt(index)
End Sub

Private Sub lblSettings_Click
	mDrawer.LeftOpen = False
	B4XPages.MainPage.Settings.ShowSettings
End Sub