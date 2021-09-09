B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@
Sub Class_Globals
	Private xui As XUI
	Public mBase As B4XView
	Private ImagesCache1 As ImagesCache
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Private mTheme As ThemeManager
	Private BBListItem1 As BBListItem
	Private tu As TextUtils
	Public mChatMessage As PLMChatMessage 'ignore
	Private root As B4XView
	Private lblTime As B4XView
	Private IsUserMessage As Boolean
End Sub

Public Sub Initialize (Parent As B4XView, Callback As Object, EventName As String)
	mBase = Parent
	root = xui.CreatePanel("")
	mBase.AddView(root, 5dip, 0, mBase.Width, mBase.Height)
	root.LoadLayout("ChatView")
	
	BBListItem1.TextEngine = B4XPages.MainPage.TextUtils1.TextEngine
	ImagesCache1 = B4XPages.MainPage.ImagesCache1
	mCallBack = Callback
	mEventName = EventName
	tu = B4XPages.MainPage.TextUtils1
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	Theme_Changed
End Sub

Private Sub Theme_Changed
	BBListItem1.ParseData.DefaultColor = mTheme.DefaultText
	lblTime.TextColor = mTheme.SecondTextColor
	
End Sub

Public Sub SetContent(ChatMessage As PLMChatMessage, ListItem As PLMCLVItem)
	mChatMessage = ChatMessage
	IsUserMessage = mChatMessage.AccountId = B4XPages.MainPage.User.Id
	BBListItem1.PrepareBeforeRuns
	BBListItem1.mBase.Width = 0.7 * mBase.Width
	Dim runs As List = tu.HtmlConverter.ConvertHtmlToRuns(ChatMessage.Content, BBListItem1.ParseData, ChatMessage.Emojies)
	BBListItem1.SetRuns(runs)
	
	BBListItem1.UpdateVisibleRegion(0, 10000)
	Dim h As Int = BBListItem1.mBase.Height + 20dip
	root.Width = Max(5dip * 2 + BBListItem1.Paragraph.Width / tu.TextEngine.mScale + 50dip, 80dip)
	root.Height = h
	If IsUserMessage Then
		root.SetColorAndBorder(mTheme.ChatMeBackground, 0, 0, 5dip)	
		root.Left = mBase.Width - root.Width - 10dip
	Else
		root.Left = 10dip
		root.SetColorAndBorder(mTheme.SecondBackground, 0, 0, 5dip)	
	End If
	lblTime.SetLayoutAnimated(0, root.Width - 30dip, root.Height - 20dip, 30dip, 20dip)
	lblTime.Text = tu.TicksToTimeString(mChatMessage.CreateAt, False)
	mBase.Height = h + 5dip
	#if B4A
	Dim p As Panel = root
	p.Elevation = 4dip
	#Else If B4i
	Dim p As Panel = root
	p.SetShadow(mTheme.PrefSeparatorColor, 1dip, 1dip, 0.6, False)
	#End If
End Sub

Private Sub BBListItem1_LinkClicked (URL As String, Text As String)
	CallSub2(mCallBack, mEventName & "_LinkClicked", tu.ManageLink(Null, Null, URL, Text))
End Sub

Public Sub SetVisibility (visible As Boolean)
	BBListItem1.ChangeVisibility(visible)
End Sub

Public Sub RemoveFromParent
	ImagesCache1.RemovePanelChildImageViews(mBase)
	mBase.RemoveViewFromParent
	BBListItem1.ReleaseInlineImageViews
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub
