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
	Private Const MaxNumberOfItems As Int = 6
	Private mList As ListOfStatuses
End Sub

Public Sub Initialize (list As ListOfStatuses)
	Stack.Initialize
	mList = list
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
	If Stack.Size > MaxNumberOfItems Then
		Stack.Remove(Stack.Keys.Get(0))
	End If
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
	mList.UpdateBackKey
End Sub

Public Sub Delete (link As PLMLink)
	Stack.Remove(link.Title)
	mList.UpdateBackKey
End Sub

Public Sub GetDataToStore As Object
	Dim links As List
	links.Initialize
	For Each item As StackItem In Stack.Values
		links.Add(item.Link)	
	Next
	links.Add(mList.feed.mLink)
	For Each link As PLMLink In links
		If link.Extra.IsInitialized = False Then link.Extra.Initialize 'required for serialization
	Next
	Return links
End Sub

Public Sub SetDataFromStore(o As Object)
	Dim links As List = o
	Dim server As PLMServer = B4XPages.MainPage.GetServer
	For Each link As PLMLink In links
		If link = B4XPages.MainPage.LINK_HOME Or link = B4XPages.MainPage.LINK_PUBLIC Then Continue
		Stack.Put(link.Title, CreateStackItem(B4XPages.MainPage.User, server, link, B4XCollections.CreateOrderedMap, _
			Constants.EmptyList, 0))
	Next
	
End Sub

