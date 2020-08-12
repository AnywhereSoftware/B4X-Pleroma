B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private Stack As List
	Type StackItem (User As PLMUser, Server As PLMServer, Link As PLMLink, Statuses As B4XOrderedMap, CLVItems As List, _
		CurrentScrollOffset As Int, Extra As Map)
End Sub

Public Sub Initialize
	Stack.Initialize
End Sub

Public Sub Push (Feed As PleromaFeed, CLV As CustomListView, Extra As Map)
	Dim clvitems As List
	clvitems.Initialize
	For i = 0 To CLV.Size - 1
		clvitems.Add(CLV.GetValue(i))
	Next
	Dim item As StackItem = CreateStackItem(Feed.user, Feed.server, Feed.mLink, Feed.Statuses, clvitems, CLV.sv.ScrollViewOffsetY)
	item.Extra = Extra
	Stack.Add(item)
End Sub

Public Sub Pop (Feed As PleromaFeed, list As ListOfStatuses) As StackItem
	Dim item As StackItem = Stack.Get(Stack.Size - 1)
	Stack.RemoveAt(Stack.Size - 1)
	Feed.user = item.User
	Feed.server = item.Server
	Feed.mLink = item.Link
	Feed.Statuses = item.Statuses
	list.CreateItemsFromStack(item.CLVItems, item.CurrentScrollOffset)
	Return item
End Sub

Public Sub getIsEmpty As Boolean
	Return Stack.Size = 0
End Sub

Private Sub CreateStackItem (User As PLMUser, Server As PLMServer, Link As PLMLink, Statuses As B4XOrderedMap, CLVItems As List, CurrentScrollOffset As Int) As StackItem
	Dim t1 As StackItem
	t1.Initialize
	t1.User = User
	t1.Server = Server
	t1.Link = Link
	t1.Statuses = Statuses
	t1.CLVItems = CLVItems
	t1.CurrentScrollOffset = CurrentScrollOffset
	Return t1
End Sub

Public Sub Clear
	Stack.Clear
End Sub

