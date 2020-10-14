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
End Sub

Public Sub Initialize (Drawer As B4XDrawer)
	mDrawer = Drawer
	mp = B4XPages.MainPage
	root = mDrawer.LeftPanel
	root.LoadLayout("LeftDrawer")
	'create user item
	Divider = xui.CreatePanel("")
	Divider.SetLayoutAnimated(0, 0, 0, lstDrawer.AsView.Width, 4dip)
	Dim p As B4XView = xui.CreatePanel("")
	Divider.AddView(p, 5dip, 0, lstDrawer.AsView.Width - 10dip, Divider.Height)
	p.Color = xui.Color_Black
	LinksManager = B4XPages.MainPage.LinksManager
End Sub

Private Sub lstDrawer_ItemClick (Index As Int, Value As Object)
	mDrawer.LeftOpen = False
	Select Value
		Case "sign in"
			mp.SignIn
		Case "settings"
			B4XPages.MainPage.ShowMessage("not implemented...")
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
	Dim spaces As String = "   "
	lstDrawer.Clear
	Dim weHaveAUser As Boolean = Not(mp.User.SignedIn = False Or UserItem.IsInitialized = False)
	If weHaveAUser = False Then
		lstDrawer.AddTextItem($"${"" & Chr(0xF090)}${spaces}Sign in"$, "sign in")
	Else
		UserItem.RemoveViewFromParent
		lstDrawer.Add(UserItem, mp.TextUtils1.CreateUserLink(mp.User.id, mp.User.DisplayName, "statuses"))
	End If
	lstDrawer.AddTextItem($"${"" & Chr(0xF013)}${spaces}${Constants.AppName} ${NumberFormat2(Constants.Version, 1, 2, 2, False)}"$, "settings")
	If weHaveAUser Then
		lstDrawer.AddTextItem($"${"" & Chr(0xF015)}${spaces}Home"$, LinksManager.LINK_HOME)
		lstDrawer.AddTextItem($"${"" & Chr(0xF0A2)}${spaces}Notifications"$, LinksManager.LINK_NOTIFICATIONS)
	End If
	For Each Link As PLMLink In LinksManager.GetDefaultLinksWithoutHome
		lstDrawer.AddTextItem($"${"" & Chr(0xF1D7)}${spaces}${Link.Title}"$, Link)
	Next
	
	Divider.RemoveViewFromParent
	Divider.GetView(0).Width = lstDrawer.AsView.Width - 10dip
	lstDrawer.Add(Divider, "")
	Dim Links As List = mp.Statuses.Stack.Items.Keys
	For i = Links.Size - 1 To 0 Step - 1
		Dim Link As PLMLink = Links.Get(i)
		If LinksManager.IsRecentLink(Link) = False Then Continue
		Dim Si As StackItem = mp.Statuses.Stack.Items.Get(Link)
		Dim Title As String = Link.Title
		If Si.Link.LINKTYPE = Constants.LINKTYPE_SEARCH Then
			Title = Constants.SearchIconChar & spaces & Title
		End If
		lstDrawer.AddTextItem(Title, Si.Link)
		Dim lbl As B4XView = CreateXLabel
		Dim p As B4XView = lstDrawer.GetPanel(lstDrawer.Size - 1)
		p.AddView(lbl, lstDrawer.AsView.Width - 2dip - lbl.Width, p.Height / 2 - lbl.Height / 2, lbl.Width, lbl.Height)
	Next
End Sub

Private Sub CreateXLabel As B4XView
	Dim lbl As Label
	lbl.Initialize("lblDelete")
	Dim xlbl As B4XView = lbl
	xlbl.SetLayoutAnimated(0, 0, 0, 30dip, 30dip)
	xlbl.Text = "" & Chr(0xF00D)
	xlbl.Font = xui.CreateFontAwesome(16)
	xlbl.SetTextAlignment("CENTER", "CENTER")
	xlbl.TextColor = Constants.ColorDefaultText
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
	End If
	UpdateAvatarAndDisplayName
End Sub

Public Sub UpdateAvatarAndDisplayName
	UserItem.GetView(1).Text = mp.User.DisplayName
	Dim iv As B4XView = UserItem.Tag
	mp.ImagesCache1.ReleaseImage(iv.Tag)
	mp.ImagesCache1.SetImage(mp.User.Avatar, iv.Tag, mp.ImagesCache1.RESIZE_NONE)
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


Private Sub Delete(index As Int)
	Dim link As PLMLink = lstDrawer.GetValue(index)
	mp.Statuses.Stack.Delete(link)
	lstDrawer.RemoveAt(index)
End Sub

