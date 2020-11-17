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
	Private ImagesCache1 As ImagesCache
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Private pnlLine As B4XView
	Private mAccount As PLMAccount
	Private btnFollow As B4XView
	Private tu As TextUtils
	Private Notif As PLMNotification
	Private btnMore As B4XView
	Private AccountHolder(1) As PLMAccount
	Private mTheme As ThemeManager
End Sub

Public Sub Initialize (Parent As B4XView, Callback As Object, EventName As String)
	mBase = Parent
	mBase.LoadLayout("MiniAccountView")
	bbTop.TextEngine = B4XPages.MainPage.TextUtils1.TextEngine
	ImagesCache1 = B4XPages.MainPage.ImagesCache1
	mCallBack = Callback
	mEventName = EventName
	B4XPages.MainPage.ViewsCache1.SetCircleClip(imgAvatar.Parent)
	tu = B4XPages.MainPage.TextUtils1
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	Theme_Changed
End Sub

Private Sub Theme_Changed
	mBase.Color = mTheme.Background
	pnlLine.Color = mTheme.Divider
	imgAvatar.Parent.Color = mTheme.AttachmentPanelBackground
End Sub

Public Sub SetContent(Account As PLMMiniAccount, ListItem As PLMCLVItem)
	Notif = Account.Notification
	mAccount = Account.Account
	AccountHolder(0) = mAccount
	Dim mp As B4XMainPage = B4XPages.MainPage
	Dim consumer As ImageConsumer = mp.SetImageViewTag(imgAvatar)
	consumer.IsVisible = True
	Dim tu As TextUtils = B4XPages.MainPage.TextUtils1
	ImagesCache1.SetImage(mAccount.Avatar, imgAvatar.Tag, ImagesCache1.RESIZE_NONE)
	tu.SetAccountTopText(bbTop, mAccount, Notif, True)
	tu.UpdateFollowButton(btnFollow, mAccount, True)
End Sub

Private Sub btnFollow_Click
	tu.FollowButtonClicked(btnFollow, AccountHolder, "follow", True)
End Sub

Private Sub btnMore_Click
	tu.OtherAccountMoreClicked(btnFollow, AccountHolder, True, bbTop, Notif)
End Sub

Public Sub RemoveFromParent
	ImagesCache1.RemovePanelChildImageViews(mBase)
	mBase.RemoveViewFromParent
	bbTop.ReleaseInlineImageViews
End Sub

Public Sub SetVisibility (visible As Boolean)
	If mAccount.IsInitialized = False Then Return
	Dim cache As ImagesCache = B4XPages.MainPage.ImagesCache1
	cache.SetConsumerVisibility(imgAvatar.Tag, visible)
	bbTop.ChangeVisibility(visible)
End Sub

#if B4J
Private Sub imgAvatar_MouseClicked (EventData As MouseEvent)
#else
Private Sub imgAvatar_Click
#end if
	BBTOP_LinkClicked("@", mAccount.DisplayName)
End Sub

Private Sub BBTOP_LinkClicked (URL As String, Text As String)
	CallSub2(mCallBack, mEventName & "_LinkClicked", B4XPages.MainPage.TextUtils1.ManageLink(Null, mAccount, URL, Text))
End Sub


Public Sub GetBase As B4XView
	Return mBase
End Sub
