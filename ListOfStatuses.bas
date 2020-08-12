B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
#Event: AvatarClicked (Account As PLMAccount)
#Event: LinkClicked (URL As String)
#Event: StackPush (Extra As Map)
#Event: StackPop (Extra As Map)
#Event: TitleChanged (Title As String)
Sub Class_Globals
	Private CLV As CustomListView
	Private AnotherProgressBar1 As AnotherProgressBar
	Private UsedStatusViews, UnusedStatusViews As B4XSet
	Private WaitingForItems As Boolean
	Public Root As B4XView 'ignore
	Private xui As XUI 'ignore
	Private feed As PleromaFeed
	Private pnlLargeImage As B4XView
	Type PLMCLVItem (Content As Object, Height As Int, Empty As Boolean)
	Private ZoomImageView1 As ZoomImageView
	Private RefreshIndex As Int
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Public Stack As StackManager
	Private btnBack As B4XView
	Private AccountView1 As AccountView
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Root1 As B4XView)
	mEventName = EventName
	mCallBack = Callback
	Root = Root1
	Root.LoadLayout("StatusList")
	UsedStatusViews.Initialize
	UnusedStatusViews.Initialize
	Stack.Initialize
	feed.Initialize (Me)
	AddMoreItems
End Sub

Public Sub Resize (Width As Int, Height As Int)
	
End Sub

Public Sub Refresh
	Refresh2(feed.user, feed.mLink, False)
End Sub

Public Sub Refresh2 (User As PLMUser, NewLink As PLMLink, AddCurrentToStack As Boolean)
	RefreshImpl(User, NewLink, AddCurrentToStack, False)
End Sub

Private Sub RefreshImpl (User As PLMUser, NewLink As PLMLink, AddCurrentToStack As Boolean, Back As Boolean)
	btnBack.Visible = False
	If AddCurrentToStack Then
		Dim extra As Map = CreateMap()
		CallSub2(mCallBack, mEventName & "_StackPush", extra)
		Stack.Push(feed, CLV, extra)
	End If
	Wait For (StopAndClear) Complete (unused As Boolean)
	If Back Then
		Dim StackItem As StackItem = Stack.Pop(feed, Me)
		NewLink = StackItem.Link
		CallSub2(mCallBack, mEventName & "_StackPop", StackItem.Extra)
	Else
		feed.user = User
		feed.mLink = NewLink
	End If
	feed.Start (Back)
	CallSub2(mCallBack, mEventName & "_TitleChanged", NewLink.Title)
	If CLV.Size = 0 Then
		AddMoreItems
	End If
	btnBack.Visible = Stack.IsEmpty = False
End Sub

Public Sub StopAndClear As ResumableSub
	RefreshIndex = RefreshIndex + 1
	Dim MyIndex As Int = RefreshIndex
	Do While WaitingForItems
		Sleep(50)
		If RefreshIndex <> MyIndex Then Return False
	Loop
	feed.Stop
	RemoveInvisibleItems(0, 0, True)
	CLV.Clear
	CLV.sv.ScrollViewOffsetY = 0
	CloseLargeImage
	Return True
End Sub

Private Sub GoBack
	RefreshImpl(Null, Null, False, True)
End Sub

Public Sub CreateItemsFromStack(Items As List, Offset As Int)
	For Each ci As PLMCLVItem In Items
		Dim pnl As B4XView = xui.CreatePanel("")
		pnl.SetLayoutAnimated(0, 0, 0, CLV.AsView.Width, ci.Height)
		AddItemToCLVAndRemoveTouchEvent(pnl, ci)
	Next
	Sleep(20)
	CLV.sv.ScrollViewOffsetY = Offset
	Sleep(0)
	CLV_VisibleRangeChanged(CLV.FirstVisibleIndex, CLV.LastVisibleIndex)
End Sub

Public Sub GetCurrentIndex As Int
	Return CLV.LastVisibleIndex
End Sub

Public Sub IsWaitingForItems As Boolean
	Return WaitingForItems Or feed.Statuses.Size < CLV.Size + 30
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
	If CLV.LastVisibleIndex = CLV.Size - 1 Then
		AnotherProgressBar1.Visible = True
	End If
	Do Until feed.Statuses.Size > CLV.Size
		Sleep(100)
		If MyRefreshIndex <> RefreshIndex Then
			WaitingForItems = False
			Return
		End If
	Loop
	Dim NewList As Boolean = CLV.Size = 0
	Dim MaxIndex As Int = Min(feed.Statuses.Size - 1, CLV.Size + 10)
	For i = CLV.Size To MaxIndex
		Dim Content As Object = feed.Statuses.Get(feed.Statuses.Keys.Get(i))
		Dim pnl As B4XView = xui.CreatePanel("")
		pnl.SetLayoutAnimated(0, 0, 0, CLV.AsView.Width, 20dip)
		Dim ContentView As Object = GetContentView(i, Content)
		CallSub2(ContentView, "SetContent", Content)
		Dim ContentBase As B4XView = CallSub(ContentView, "GetBase")
		pnl.AddView(ContentBase , 0, 0, ContentBase.Width, ContentBase.Height)
		pnl.Height = ContentBase.Height
		Dim Value As PLMCLVItem = CreatePLMCLVItem(Content)
		Value.Empty = False
		Value.Height = pnl.Height
		AddItemToCLVAndRemoveTouchEvent(pnl, Value)
		CallSub2(ContentView, "SetVisibility", IsVisible(i, CLV.FirstVisibleIndex, CLV.LastVisibleIndex))
		
		If i = 5 And NewList Then Exit
		If CLV.LastVisibleIndex < CLV.Size - 1 Then
			Sleep(100)
		End If
	Next
	StopScroll
	CLV_ScrollChanged(CLV.sv.ScrollViewOffsetY)
	AnotherProgressBar1.Visible = False
	WaitingForItems = False
End Sub

Private Sub AddItemToCLVAndRemoveTouchEvent(pnl As B4XView, value As PLMCLVItem)
	CLV.Add(pnl, value)
	#if B4i
	RemoveClickRecognizer(pnl)
	#End If
End Sub

#if B4i
Public Sub RemoveClickRecognizer (pnl As B4XView)
	Dim no As NativeObject = pnl.Parent
	Dim recs As List = no.GetField("gestureRecognizers")
	For Each rec As Object In recs
		no.RunMethod("removeGestureRecognizer:", Array(rec))
	Next
End Sub
#End If

Private Sub AddContentView (Index As Int)
	Dim value As PLMCLVItem = CLV.GetValue(Index)
	Dim ContentView As Object = GetContentView(Index, value.Content)
	Dim parent As B4XView = CLV.GetPanel(Index)
	parent.AddView(CallSub(ContentView, "GetBase"), 0, 0, parent.Width, parent.Height)
	CallSub2(ContentView, "SetVisibility", IsVisible(Index, CLV.FirstVisibleIndex, CLV.LastVisibleIndex))
	CallSub2(ContentView, "SetContent", value.Content)
	value.Empty = False
	If ContentView Is StatusView Then
		Dim sv As StatusView = ContentView
		sv.ParentScrolled(CLV.sv.ScrollViewOffsetY, CLV.sv.Height)
	End If
End Sub

Private Sub RemoveStatusView (sv As StatusView)
	Dim value As PLMCLVItem = CLV.GetValue(sv.ListIndex)
	value.Empty = True
	sv.RemoveFromParent
	UsedStatusViews.Remove(sv)
	UnusedStatusViews.Add(sv)
End Sub

Private Sub RemoveInvisibleItems (FirstIndex As Int, LastIndex As Int, All As Boolean)
	Dim ItemsToRemove As List
	For Each sv As StatusView In UsedStatusViews.AsList
		If All Or IsVisible(sv.ListIndex, FirstIndex, LastIndex + 10) = False Then
			If ItemsToRemove.IsInitialized = False Then ItemsToRemove.Initialize
			ItemsToRemove.Add(sv)
		Else
			sv.SetVisibility(IsVisible(sv.ListIndex, FirstIndex, LastIndex))
		End If
	Next
	If ItemsToRemove.IsInitialized Then
		For Each sv As StatusView In ItemsToRemove
			RemoveStatusView(sv)
		Next
	End If
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
	For Each sv As StatusView In UsedStatusViews.AsList
		sv.ParentScrolled(ScrollViewOffset, CLV.sv.Height)
	Next
End Sub

Private Sub StopScroll
	#if B4A
	Dim jsv As JavaObject = CLV.sv
	jsv.RunMethod("smoothScrollBy", Array(0, 0))
	#End If
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
	Else
		Dim stub As StubView
		stub.Initialize(CLV.AsView.Width)
		Return stub
	End If
End Sub

Private Sub GetStatusView (ListIndex As Int) As StatusView
	Dim sv As StatusView	
	If UnusedStatusViews.Size > 0 Then
		sv = UnusedStatusViews.AsList.Get(0)
		UnusedStatusViews.Remove(sv)
	Else
		Dim pnl As B4XView = xui.CreatePanel("")
		pnl.SetLayoutAnimated(0, 0, 0, CLV.AsView.Width, 300dip)
		sv.Initialize(Me, "StatusView1")
		sv.Create(pnl)
		sv.mBase.RemoveViewFromParent
	End If
	sv.ListIndex = ListIndex
	UsedStatusViews.Add(sv)
	Return sv
End Sub


Private Sub IsVisible(Index As Int, FirstIndex As Int, LastIndex As Int) As Boolean
	Return Index >= FirstIndex And Index <= LastIndex
End Sub

Sub CLV_ItemClick (Index As Int, Value As Object)
	Dim St As PLMCLVItem = Value
	If St.Content Is PLMStatus Then
		Dim s As PLMStatus = St.Content
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
	ic.SetImage(URL, ZoomImageView1.Tag, ic.RESIZE_NONE)
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

Public Sub BackKeyPressedShouldClose As Boolean
	If pnlLargeImage.Visible Then
		CloseLargeImage
		Return False
	End If
	If btnBack.Visible Then
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
	B4XPages.MainPage.PerformHapticFeedback
End Sub