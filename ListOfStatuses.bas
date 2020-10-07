B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
#Event: AvatarClicked (Account As PLMAccount)
#Event: LinkClicked (URL As PLMLink)
#Event: TitleChanged (Title As String)
Sub Class_Globals
	Private CLV As CustomListView
	Type StatusesListUsedManager (UsedStatusViews As Map, UnusedStatusViews As B4XSet)
	Private WaitingForItems As Boolean
	Public mBase As B4XView 'ignore
	Private xui As XUI 'ignore
	Public feed As PleromaFeed
	Private pnlLargeImage As B4XView
	Type PLMCLVItem (Content As Object, ItemHeight As Int, Empty As Boolean, Expanded As Boolean)
	Private ZoomImageView1 As ZoomImageView
	Private RefreshIndex As Int
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Public Stack As StackManager
	Private btnBack As B4XView
	Private AccountView1 As AccountView
	Private LastScrollPosition As Int
	Private StatusesViewsManager As StatusesListUsedManager
	Private MiniAccountsManager As StatusesListUsedManager	
	Private ViewsManagers As List
	Private TargetId As String
	Private PostView1 As PostView
	Private PostViewListIndex As Int = -1
	
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Root1 As B4XView)
	mEventName = EventName
	mCallBack = Callback
	mBase = Root1
	mBase.LoadLayout("StatusList")
	StatusesViewsManager = CreateStatusesListUsedManager
	MiniAccountsManager = CreateStatusesListUsedManager
	ViewsManagers = Array(StatusesViewsManager, MiniAccountsManager)
	Stack.Initialize (Me)
	feed.Initialize (Me)
	AddMoreItems
End Sub

Public Sub ResizeVisibleList
	
End Sub

Public Sub Refresh
	feed.mLink.NextURL = ""
	Refresh2(feed.user, feed.mLink, False, False)
End Sub

Public Sub Refresh2 (User As PLMUser, NewLink As PLMLink, AddCurrentToStack As Boolean, GetFromStackIfAvailable As Boolean)
	If GetFromStackIfAvailable And Stack.ContainsTitle(NewLink.Title) Then
		Dim item As StackItem = Stack.GetFromTitle(NewLink.Title)
		Stack.RemoveTitle(NewLink.Title)
		RefreshImpl(User, Null, AddCurrentToStack, item)
	Else
		RefreshImpl(User, NewLink, AddCurrentToStack, Null)
	End If
End Sub

Private Sub RefreshImpl (User As PLMUser, NewLink As PLMLink, AddCurrentToStack As Boolean, GoToItem As StackItem)
	btnBack.Visible = False
	RemovePostView (False)
	If AddCurrentToStack Then
		If GoToItem = Null Or GoToItem.Link.Title <> feed.mLink.Title Then
			Stack.PushToStack(feed, CLV)
		End If
	End If
	Wait For (StopAndClear) Complete (unused As Boolean)
	TargetId = ""
	Dim KeepOldStatuses As Boolean
	If GoToItem <> Null Then
		NewLink = GoToItem.Link
		feed.user = GoToItem.User
		feed.server = GoToItem.Server
		feed.mLink = GoToItem.Link
		If GoToItem.Time + Constants.StackItemRelevantPeriod > DateTime.Now Then
			feed.Statuses = GoToItem.Statuses
			CreateItemsFromStack(GoToItem.CLVItems, GoToItem.CurrentScrollOffset)
			KeepOldStatuses = True
		End If
	Else
		feed.user = User
		feed.mLink = NewLink
		If NewLink.Extra.IsInitialized And NewLink.Extra.ContainsKey("targetId") Then
			TargetId = NewLink.Extra.Get("targetId")
			B4XPages.MainPage.ShowProgress
		End If
	End If
	feed.Start (KeepOldStatuses)
	CallSub2(mCallBack, mEventName & "_TitleChanged", NewLink.Title)
	If CLV.Size = 0 Then
		AddMoreItems
	End If
	UpdateBackKey
End Sub

Public Sub UpdateBackKey
	btnBack.Visible = Stack.IsEmpty = False And B4XPages.MainPage.MadeWithLove1.mBase.Visible = False
End Sub

Public Sub StopAndClear As ResumableSub
	Wait For (WaitForWaitingForItemsToBeFalse) Complete (Success As Boolean)
	If Success = False Then Return False
	feed.Stop
	RemoveInvisibleItems(0, 0, True)
	CLV.Clear
	CLV.sv.ScrollViewOffsetY = 0
	CloseLargeImage
	Return True
End Sub

Private Sub WaitForWaitingForItemsToBeFalse As ResumableSub
	RefreshIndex = RefreshIndex + 1
	Dim MyIndex As Int = RefreshIndex
	Do While WaitingForItems
		Sleep(50)
		If RefreshIndex <> MyIndex Then Return False
	Loop
	Return True
End Sub


Private Sub GoBack
	Dim items As B4XOrderedMap = Stack.Items
	Dim LastItem As StackItem = items.Get(items.Keys.Get(items.Keys.Size - 1))
	Stack.Items.Remove(LastItem.Link)
	RefreshImpl(Null, Null, False, LastItem)
End Sub

Public Sub CreateItemsFromStack(Items As List, Offset As Int)
	For Each ci As PLMCLVItem In Items
		Dim pnl As B4XView = xui.CreatePanel("")
		pnl.SetLayoutAnimated(0, 0, 0, CLV.AsView.Width, ci.ItemHeight)
		AddItemToCLVAndRemoveTouchEvent(pnl, ci, CLV.Size)
	Next
	Sleep(20)
	CLV.sv.ScrollViewOffsetY = Offset
	Sleep(0)
	CLV_VisibleRangeChanged(CLV.FirstVisibleIndex, CLV.LastVisibleIndex)
End Sub

Public Sub GetCurrentIndex As Int
	Return CLV.LastVisibleIndex
End Sub

Public Sub TickAndIsWaitingForItems As Boolean
	If TargetId <> "" Then
		Return True
	End If
	#if RELEASE
	If LastScrollPosition = Floor(CLV.sv.ScrollViewOffsetY) Then
		If WaitingForItems = False And CLV.LastVisibleIndex + 30 > CLV.Size Then
			AddMoreItems
		End If
	End If
	#end if
	LastScrollPosition = CLV.sv.ScrollViewOffsetY
	Return WaitingForItems Or feed.Statuses.Size < CLV.Size + 30
End Sub

Private Sub PostView1_NewPost (Status As PLMStatus)
	Dim ReplyId As String = PostView1.mReplyToId
	RemovePostView(False)
	Wait For (WaitForWaitingForItemsToBeFalse) Complete (Success As Boolean)
	Dim index As Int = feed.InsertItem(ReplyId, Status, Status.id)
	If Success = False Then Return
	UpdateIndicesAboveIndex(index - 1, 1)
	InsertNewItem(index)
	CLV_ScrollChanged(CLV.sv.ScrollViewOffsetY)
End Sub



Private Sub JumpToTarget
	Log("jump to target")
	Sleep(0)
	B4XPages.MainPage.HideProgress
	Dim i As Int = feed.Statuses.Keys.IndexOf(TargetId)
	If i > 0 And i < CLV.Size Then
		CLV.JumpToItem(i)
	End If
	TargetId = ""
End Sub

Private Sub AreThereMoreItems As Boolean
	If CLV.Size = 0 Then Return True
	Dim last As PLMCLVItem = CLV.GetValue(CLV.Size - 1)
	Return last.Content <> feed.NoMoreItems
End Sub

Private Sub AddMoreItems
	If WaitingForItems Then Return
	If AreThereMoreItems = False Then Return
	WaitingForItems = True
	Dim MyRefreshIndex As Int = RefreshIndex
	Dim ProgressBar As Boolean
	If CLV.LastVisibleIndex = CLV.Size - 1 Then
		ProgressBar = True
		B4XPages.MainPage.ShowProgress
	End If
	Do Until feed.Statuses.Size > CLV.Size
		Sleep(100)
		If MyRefreshIndex <> RefreshIndex Then
			WaitingForItems = False
			If ProgressBar Then B4XPages.MainPage.HideProgress
			Return
		End If
	Loop
	Dim NewList As Boolean = CLV.Size = 0 And TargetId = ""
	Dim MaxIndex As Int = Min(feed.Statuses.Size - 1, CLV.Size + 10)
	If TargetId <> "" Then MaxIndex = feed.Statuses.Size - 1
	For i = CLV.Size To MaxIndex
		InsertNewItem(i)
		If i = 5 And NewList Then Exit
	Next
	CLV_ScrollChanged(CLV.sv.ScrollViewOffsetY)
	If ProgressBar Then B4XPages.MainPage.HideProgress
	WaitingForItems = False
	If TargetId <> "" And feed.Statuses.ContainsKey(TargetId) Then
		JumpToTarget
	End If
End Sub

Private Sub InsertNewItem (Index As Int)
	Dim Content As Object = feed.Statuses.Get(feed.Statuses.Keys.Get(Index))
	Dim Value As PLMCLVItem = CreatePLMCLVItem(Content)
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, CLV.AsView.Width, 20dip)
	Dim ContentView As Object = GetContentView(Index, Content)
	CallSub3(ContentView, "SetContent", Content, Value)
	Dim ContentBase As B4XView = CallSub(ContentView, "GetBase")
	pnl.AddView(ContentBase , 0, 0, ContentBase.Width, ContentBase.Height)
	pnl.Height = ContentBase.Height
	Value.ItemHeight = pnl.Height
	Value.Empty = False
	AddItemToCLVAndRemoveTouchEvent(pnl, Value, Index)
	CallSub2(ContentView, "SetVisibility", IsVisible(Index, CLV.FirstVisibleIndex, CLV.LastVisibleIndex))
End Sub

Private Sub AddItemToCLVAndRemoveTouchEvent(pnl As B4XView, value As PLMCLVItem, Index As Int)
	CLV.InsertAt(Index, pnl, value)
	#if B4i
	RemoveClickRecognizer(pnl)
	#End If
End Sub

Public Sub RemoveClickRecognizer (pnl As B4XView)
#if B4i
	Dim no As NativeObject = pnl.Parent
	Dim recs As List = no.GetField("gestureRecognizers")
	For Each rec As Object In recs
		no.RunMethod("removeGestureRecognizer:", Array(rec))
	Next
#End If
End Sub

Private Sub AddContentView (Index As Int)
	Dim value As PLMCLVItem = CLV.GetValue(Index)
	Dim ContentView As Object = GetContentView(Index, value.Content)
	Dim parent As B4XView = CLV.GetPanel(Index)
	parent.AddView(CallSub(ContentView, "GetBase"), 0, 0, parent.Width, parent.Height)
	CallSub2(ContentView, "SetVisibility", IsVisible(Index, CLV.FirstVisibleIndex, CLV.LastVisibleIndex))
	CallSub3(ContentView, "SetContent", value.Content, value)
	value.Empty = False
	If ContentView Is StatusView Then
		Dim sv As StatusView = ContentView
		sv.ParentScrolled(CLV.sv.ScrollViewOffsetY, CLV.sv.Height)
	End If
End Sub

Private Sub RemoveView (manager As StatusesListUsedManager, sv As Object)
	Dim Index As Int = GetUsedItemIndex(manager, sv)
	Dim value As PLMCLVItem = CLV.GetValue(Index)
	value.Empty = True
	CallSub(sv, "RemoveFromParent")
	manager.UsedStatusViews.Remove(sv)
	manager.UnusedStatusViews.Add(sv)
End Sub

Private Sub GetUsedItemIndex (Manager As StatusesListUsedManager, sv As Object) As Int
	Dim o() As Int = Manager.UsedStatusViews.Get(sv)
	Return o(0)
End Sub

Private Sub RemoveInvisibleItems (FirstIndex As Int, LastIndex As Int, All As Boolean)
	For Each manager As StatusesListUsedManager In ViewsManagers
		Dim ItemsToRemove As List
		For Each sv As Object In manager.UsedStatusViews.Keys
			Dim ListIndex As Int = GetUsedItemIndex(manager, sv)
			If All Or IsVisible(ListIndex, FirstIndex, LastIndex + 10) = False Then
				If ItemsToRemove.IsInitialized = False Then ItemsToRemove.Initialize
				ItemsToRemove.Add(sv)
			Else
				CallSub2(sv, "SetVisibility", IsVisible(ListIndex, FirstIndex, LastIndex))
			End If
		Next

		If ItemsToRemove.IsInitialized Then
			For Each sv As Object In ItemsToRemove
				RemoveView(manager, sv)
			Next
		End If
	Next
	If AccountView1.IsInitialized And AccountView1.mBase.Parent.IsInitialized Then
		If All Or IsVisible(0, FirstIndex, LastIndex) = False Then
			AccountView1.RemoveFromParent
			Dim value As PLMCLVItem = CLV.GetValue(0)
			value.Empty = True
		End If
	End If
	If All And AreThereMoreItems = False Then
		Dim value As PLMCLVItem = CLV.GetValue(CLV.Size - 1)
		value.Empty = True
	End If
	If PostViewListIndex >= 0 And (All Or IsVisible(PostViewListIndex, FirstIndex, LastIndex) = False) Then
		RemovePostView(False)	
	End If
End Sub

Sub CLV_VisibleRangeChanged (FirstIndex As Int, LastIndex As Int)
	If LastIndex >= CLV.Size Then Return
	FirstIndex = Max(0, FirstIndex - 2)
	LastIndex = Min(CLV.Size - 1, LastIndex + 2)
	RemoveInvisibleItems(FirstIndex, LastIndex, False)
	For i = FirstIndex To LastIndex
		Dim value As PLMCLVItem = CLV.GetValue(i)
		If value.Empty Then
			AddContentView(i)
		End If
	Next
	If LastIndex > = CLV.Size - 5 Then
		AddMoreItems
	End If
End Sub

Private Sub CLV_ScrollChanged (ScrollViewOffset As Int)
	For Each sv As StatusView In StatusesViewsManager.UsedStatusViews.Keys
		sv.ParentScrolled(ScrollViewOffset, CLV.sv.Height)
	Next
End Sub

Private Sub GetContentView (ListIndex As Int, Content As Object) As Object
	If Content Is PLMStatus Then
		Return GetStatusView(ListIndex)
	Else if Content Is PLMAccount Then
		If AccountView1.IsInitialized = False Then
			Dim p As B4XView = xui.CreatePanel("")
			p.SetLayoutAnimated (0, 0, 0, CLV.AsView.Width, 104dip)
			AccountView1.Initialize(p, Me, "StatusView1")
		End If
		Return AccountView1
	Else If Content Is PLMMiniAccount Then
		Dim mini As MiniAccountView = GetViewFromManager(MiniAccountsManager)
		If mini = Null Then
			Dim mini As MiniAccountView
			Dim p As B4XView = xui.CreatePanel("")
			p.SetLayoutAnimated (0, 0, 0, CLV.AsView.Width, 70dip)
			mini.Initialize(p, Me, "StatusView1")
		End If
		MiniAccountsManager.UsedStatusViews.Put(mini, Array As Int(ListIndex))
		Return mini
	Else
		Dim stub As StubView
		stub.Initialize(CLV.AsView.Width)
		Return stub
	End If
End Sub

Private Sub GetStatusView (ListIndex As Int) As StatusView
	Dim sv As StatusView = GetViewFromManager(StatusesViewsManager)
	If sv = Null Then
		Dim sv As StatusView
		Dim pnl As B4XView = xui.CreatePanel("")
		pnl.SetLayoutAnimated(0, 0, 0, CLV.AsView.Width, 300dip)
		sv.Initialize(Me, "StatusView1")
		sv.Create(pnl)
		sv.mBase.RemoveViewFromParent
	End If
	StatusesViewsManager.UsedStatusViews.Put(sv, Array As Int(ListIndex)) 'by using an array as the value, we can later modify it easily.
	Return sv
	
End Sub

Private Sub GetViewFromManager (Manager As StatusesListUsedManager) As Object
	If Manager.UnusedStatusViews.Size > 0 Then
		Dim o As Object = Manager.UnusedStatusViews.AsList.Get(0)
		Manager.UnusedStatusViews.Remove(o)
		Return o
	End If
	Return Null
End Sub


Private Sub IsVisible(Index As Int, FirstIndex As Int, LastIndex As Int) As Boolean
	Return Index >= FirstIndex And Index <= LastIndex
End Sub

Sub CLV_ItemClick (Index As Int, Value As Object)
	Dim st As PLMCLVItem = Value
	If st.Content Is PLMStatus Then
		Dim s As PLMStatus = st.Content
		Log(s.id)
	End If
End Sub

Private Sub StatusView1_ShowLargeImage (URL As String)
	B4XPages.MainPage.Drawer.GestureEnabled = False
	If ZoomImageView1.Tag Is ImageConsumer Then
		B4XPages.MainPage.ImagesCache1.ReleaseImage(ZoomImageView1.Tag)
	End If
	Dim Consumer As ImageConsumer
	Consumer.Initialize
	Consumer.CBitmaps.Initialize
	Consumer.Target = ZoomImageView1.mBase
	Consumer.IsVisible = True
	ZoomImageView1.Tag = Consumer
	Dim ic As ImagesCache = B4XPages.MainPage.ImagesCache1
	If ic.IsImageReady(URL) = False Then
		ic.SetPermImageImmediately(ic.EMPTY, ZoomImageView1.Tag, ic.RESIZE_NONE)
		Consumer.NoAnimation = True		
	End If
	ic.SetImage(URL, ZoomImageView1.Tag, ic.RESIZE_NONE)
End Sub


Private Sub btnShare_Click
	Dim consumer As ImageConsumer = ZoomImageView1.Tag
	If consumer.CBitmaps.Size = 0 Then
		Log("image not ready")
		Return
	End If
	Dim cb As CachedBitmap = consumer.CBitmaps.Get(0)
	If cb.Bmp.IsInitialized = False Then Return
	#if B4A
	Dim provider As FileProvider = B4XPages.MainPage.Provider
	Dim f As String = provider.SharedFolder
	Dim name As String =Constants.TempImageFileName
	If cb.IsGif Then
		name = name & ".gif"
		File.Copy(xui.DefaultFolder, cb.GifFile, f, name)
	Else
		name = name & ".jpg"
		Dim out As OutputStream = File.OpenOutput(f, name, False)
		cb.Bmp.WriteToStream(out, 100, "JPEG")
		out.Close
	End If
	Dim in As Intent
	in.Initialize(in.ACTION_SEND, "")
	in.PutExtra("android.intent.extra.STREAM", provider.GetFileUri(name))
	in.SetType("image/*")
	in.Flags = 1
	StartActivity(in)
	#Else if B4A
	Dim avc As ActivityViewController
	avc.Initialize("avc", Array(cb.Bmp))
	avc.Show(B4XPages.GetNativeParent(B4XPages.MainPage), B4XPages.MainPage.Root)
	#End If
End Sub

Private Sub StatusView1_AvatarClicked (Account As PLMAccount)
	CallSub2(mCallBack, mEventName & "_AvatarClicked", Account)
End Sub

Private Sub StatusView1_LinkClicked (URL As PLMLink)
	CallSub2(mCallBack, mEventName & "_LinkClicked", URL)
End Sub

Private Sub CreatePLMCLVItem (Content As Object) As PLMCLVItem
	Dim t1 As PLMCLVItem
	t1.Initialize
	t1.Content = Content
	t1.Empty = True
	Return t1
End Sub

Private Sub CloseLargeImage
	If pnlLargeImage.Visible Then
		B4XPages.MainPage.Drawer.GestureEnabled = True
		pnlLargeImage.SetVisibleAnimated(100, False)
	End If
End Sub

Private Sub btnLargeImageClose_Click
	CloseLargeImage
End Sub

Public Sub BackKeyPressedShouldClose As Boolean
	If pnlLargeImage.Visible Then
		CloseLargeImage
		Return False
	Else If PostViewListIndex >= 0 Then
		If PostView1.BackKeyPressed Then Return False
		RemovePostView(False)
		Return False
	Else If btnBack.Visible Then
		GoBack
		Return False
	End If
	Return True
End Sub

Sub ZoomImageView1_Click
	CloseLargeImage
End Sub

Private Sub btnBack_Click
	GoBack
	XUIViewsUtils.PerformHapticFeedback(mBase)
End Sub

Private Sub CreateStatusesListUsedManager As StatusesListUsedManager
	Dim t1 As StatusesListUsedManager
	t1.Initialize
	t1.UsedStatusViews.Initialize
	t1.UnusedStatusViews.Initialize
	Return t1
End Sub

Private Sub StatusView1_HeightChanged
	Dim sv As StatusView = Sender
	Dim ItemIndex As Int = GetUsedItemIndex(StatusesViewsManager, sv)
	CLV.ResizeItem(ItemIndex, sv.mBase.Height)
	RemoveClickRecognizer(CLV.GetPanel(ItemIndex))
	Dim i As PLMCLVItem = CLV.GetValue(ItemIndex)
	i.ItemHeight = sv.mBase.Height
	i.Expanded = True
End Sub

Private Sub StatusView1_Reply
	Dim sv As StatusView = Sender
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then Return
	If RemovePostView (False) And PostView1.mReplyToId = sv.mStatus.id Then Return
	Dim ListIndex As Int = GetUsedItemIndex(StatusesViewsManager, sv)
	InsertPostView(ListIndex, sv.mStatus.id)
End Sub

Private Sub InsertPostView (ParentIndex As Int, ReplyToId As String)
	If PostView1.IsInitialized = False Then
		PostView1.Initialize(Me, "PostView1", mBase.Width)
	End If
	Dim content As PLMPost = feed.CreatePLMPost(ReplyToId)
	feed.InsertItem(ReplyToId, content, feed.NewPostId)
	Dim Value As PLMCLVItem = CreatePLMCLVItem(PostView1)
	Value.Empty = False
	PostViewListIndex = ParentIndex + 1
	CLV.InsertAt(PostViewListIndex, PostView1.mBase, Value)
	UpdateIndicesAboveIndex (ParentIndex, 1)
	PostView1.SetContent(content, Null)
	MakePostViewVisible
End Sub

Private Sub MakePostViewVisible
	Dim raw As CLVItem = CLV.GetRawListItem(PostViewListIndex)
	Dim TargetY As Int = raw.Offset - 80dip
	#if B4J
	CLV.sv.ScrollViewOffsetY = TargetY	
	#else if B4i
	Dim sv As ScrollView = CLV.sv
	sv.ScrollTo(0, TargetY, True)
	#Else If B4A
	Sleep(0) 
	Dim sv As ScrollView = CLV.sv
	sv.ScrollPosition = TargetY
	#End If
End Sub

'returns true if it was open
Private Sub RemovePostView (Animated As Boolean) As Boolean
	If PostViewListIndex < 0 Then Return False
	RemoveItemFromList(Animated, PostViewListIndex)
	feed.Statuses.Remove(feed.NewPostId)
	PostView1.RemoveFromParent
	PostViewListIndex = -1
	Return True
End Sub

Private Sub StatusView1_StatusDeleted
	Dim sv As StatusView = Sender
	RemoveItemFromList(True, GetUsedItemIndex(StatusesViewsManager, sv))
	RemoveView(StatusesViewsManager, sv)
	feed.Statuses.Remove(sv.mStatus.id)
End Sub

Private Sub RemoveItemFromList  (animated As Boolean, index As Int)
	If animated = False Then CLV.AnimationDuration = 0
	CLV.RemoveAt(index)
	CLV.AnimationDuration = Constants.CLVAnimationDuration
	UpdateIndicesAboveIndex(index, -1)
End Sub

Private Sub UpdateIndicesAboveIndex (Index As Int, Delta As Int)
	For Each manager As StatusesListUsedManager In ViewsManagers
		For Each sv As Object In manager.UsedStatusViews.Keys
			Dim o() As Int = manager.UsedStatusViews.Get(sv)
			If o(0) > Index Then
				o(0) = o(0) + Delta
			End If
		Next
	Next
End Sub

Private Sub PostView1_Close
	RemovePostView (True)
End Sub
