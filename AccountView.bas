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
End Sub

Public Sub Initialize (Parent As B4XView, Callback As Object, EventName As String)
	mBase = Parent
	mBase.LoadLayout("AccountView")
	bbTop.TextEngine = B4XPages.MainPage.TextUtils1.TextEngine
	BBListItem1.TextEngine = bbTop.TextEngine
	
	ImagesCache1 = B4XPages.MainPage.ImagesCache1
	mCallBack = Callback
	mEventName = EventName
	#if B4A
	Dim jo As JavaObject = ImageView1
	Dim alpha As Float = 0.7
	jo.RunMethod("setAlpha", Array(alpha))
	#End If
	B4XPages.MainPage.ViewsCache1.SetCircleClip(imgAvatar.Parent)
	tu = B4XPages.MainPage.TextUtils1
End Sub

Public Sub SetContent(Account As PLMAccount)
	mAccount = Account
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
	bbTop.PrepareBeforeRuns
	Dim runs As List
	runs.Initialize
	tu.TextWithEmojisToRuns(Account.DisplayName & " ", runs, Account.Emojis, bbTop.ParseData, xui.CreateDefaultBoldFont(14))
	Dim r As BCTextRun = tu.CreateUrlRun("@", Account.Acct, bbTop.ParseData)
	runs.Add(r)
	For Each run As BCTextRun In runs
		run.TextColor = xui.Color_White
	Next
	bbTop.SetRuns(runs)
	
	Dim node As HtmlNode = mp.TextUtils1.HtmlParser.Parse(Account.Note)
	Dim bbcode As String = $"[color=white]
${TableRow(WrapURL("statuses", "Statuses"), WrapURL("following", "Following"), WrapURL("followers", "Followers"))}
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
	bbTop.UpdateVisibleRegion(0, bbTop.mBase.Height)
	BBListItem1.UpdateVisibleRegion(0, 10000)
	pnlLine.Top = mBase.Height - 2dip
	pnlLine.Visible = Not(mDialog.IsInitialized)
	tu.UpdateFollowButton(btnFollow, mAccount)
End Sub

Private Sub WrapURL(method As String, text As String) As String
	Return $"[url=~@${method}:${mAccount.Id}][color=white]${text}[/color][/url]"$
End Sub

Private Sub btnFollow_Click
	tu.FollowButtonClicked(btnFollow, mAccount)
End Sub

Private Sub TableRow(Field1 As String, Field2 As String, Field3 As String) As String
	Return $"[Span MinWidth=33%x Alignment=center][b]${Field1}[/b][/Span][Span MinWidth=33%x Alignment=center][b]${Field2}[/b][/Span][Span MinWidth=33%x Alignment=center][b]${Field3}[/b][/Span]"$
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
	CallSub2(mCallBack, mEventName & "_LinkClicked", B4XPages.MainPage.TextUtils1.ManageLink(Null, mAccount, URL, Text))
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub
