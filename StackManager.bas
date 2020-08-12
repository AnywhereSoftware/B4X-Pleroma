B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public Stack As B4XOrderedMap
	Type StackItem (User As PLMUser, Server As PLMServer, Link As PLMLink, Statuses As B4XOrderedMap, CLVItems As List, _
		CurrentScrollOffset As Int)
End Sub

Public Sub Initialize
	Stack.Initialize
End Sub

Public Sub Push (Feed As PleromaFeed, CLV As CustomListView)
	Dim clvitems As List
	clvitems.Initialize
	For i = 0 To CLV.Size - 1
		clvitems.Add(CLV.GetValue(i))
	Next
	Dim item As StackItem = CreateStackItem(Feed.user, Feed.server, Feed.mLink, Feed.Statuses, clvitems, CLV.sv.ScrollViewOffsetY)
	Stack.Remove(item.Link.Title)
	Stack.Put(item.Link.Title, item)
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

