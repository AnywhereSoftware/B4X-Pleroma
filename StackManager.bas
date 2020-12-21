B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private Items As B4XOrderedMap '<PLMLink, StackItem>
	Type StackItem (User As PLMUser, Server As PLMServer, Link As PLMLink, Statuses As B4XOrderedMap, CLVItems As List, _
		CurrentScrollOffset As Int, Time As Long)
	
	Private mList As ListOfStatuses
	Public BookmarkedTitles As B4XSet
End Sub

Public Sub Initialize (list As ListOfStatuses)
	Items.Initialize
	mList = list
	BookmarkedTitles.Initialize
End Sub

Public Sub PushToStack (Feed As PleromaFeed, CLV As CustomListView, AddToBottom As Boolean)
	Dim clvitems As List
	clvitems.Initialize
	For i = 0 To CLV.Size - 1
		clvitems.Add(CLV.GetValue(i))
	Next
	Dim NewItem As StackItem = CreateStackItem(Feed.user, Feed.server, Feed.mLink, Feed.Statuses, clvitems, CLV.sv.ScrollViewOffsetY, DateTime.Now)
	If NewItem.Link.LinkType = Constants.LINKTYPE_NOTIFICATIONS Or NewItem.Link.URL = B4XPages.MainPage.LinksManager.LINK_HOME.URL Then
		NewItem.Time = 0 'always reload
	End If
	Items.Remove(NewItem.Link)
	RemoveTitle(NewItem.Link.Title)
	Items.Put(NewItem.Link, NewItem)
	If AddToBottom Then
		Items.Keys.InsertAt(0, NewItem.Link)
		Items.Keys.RemoveAt(Items.Keys.Size - 1)
	End If
	If Items.Size > Constants.StackMaximumNumberOfItems + BookmarkedTitles.Size Then
		For i = 0 To Items.Size - 1
			Dim it As PLMLink = Items.Keys.Get(i)
			If BookmarkedTitles.Contains(it.Title) = False Then
				Items.Remove(it)
				Exit
			End If
		Next
	End If
End Sub

Public Sub getIsEmpty As Boolean
	Return Items.Size = 0
End Sub

Private Sub CreateStackItem (User As PLMUser, Server As PLMServer, Link As PLMLink, Statuses As B4XOrderedMap, CLVItems As List, _
		CurrentScrollOffset As Int, Time As Long) As StackItem
	Dim t1 As StackItem
	t1.Initialize
	t1.User = User
	t1.Server = Server
	t1.Link = Link
	t1.Statuses = Statuses
	t1.CLVItems = CLVItems
	t1.CurrentScrollOffset = CurrentScrollOffset
	t1.Time = Time
	Return t1
End Sub

Public Sub Clear
	Items.Clear
	mList.UpdateBackKey
End Sub

Public Sub ContainsTitle (LinkTitle As String) As Boolean
	Return GetFromTitle(LinkTitle) <> Null
End Sub

Public Sub GetFromTitle (Title As String) As StackItem
	For Each link As PLMLink In Items.Keys
		If link.Title = Title Then Return Items.Get(link)
	Next
	Return Null
End Sub

Public Sub RemoveTitle (Title As String)
	Dim item As StackItem = GetFromTitle(Title)
	If item <> Null Then
		Items.Remove(item.Link)
	End If
End Sub

Public Sub Delete (link As PLMLink)
	Items.Remove(link)
	BookmarkedTitles.Remove(link.Title)
	mList.UpdateBackKey
End Sub

Public Sub ToggleBookmark (link As PLMLink)
	If BookmarkedTitles.Contains(link.Title) Then
		BookmarkedTitles.Remove(link.Title)
	Else
		BookmarkedTitles.Add(link.Title)
	End If
End Sub

'Returns a list of PLMLinks
Public Sub GetLinks As List
	Return Items.Keys
End Sub

Public Sub Pop As StackItem
	Dim LastItem As StackItem = Items.Get(Items.Keys.Get(Items.Keys.Size - 1))
	Items.Remove(LastItem.Link)
	Return LastItem
End Sub

Public Sub GetDataForStore As Object
	Dim TitlesAndLinks As B4XOrderedMap
	TitlesAndLinks.Initialize
	Dim linksmanager As B4XLinksManager =  B4XPages.MainPage.LinksManager
	For Each item As StackItem In Items.Values
		Dim link As PLMLink = item.Link
		If linksmanager.IsRecentLink(link) Then TitlesAndLinks.Put(link.Title, link)
	Next
	If linksmanager.IsRecentLink(mList.feed.mLink) Then TitlesAndLinks.put(mList.feed.mLink.Title, mList.feed.mLink)
	Dim links As List = TitlesAndLinks.Values
	For Each link As PLMLink In links
		If link.Extra.IsInitialized = False Then link.Extra.Initialize 'required for serialization
	Next
	Return CreateMap("links": links, "bookmarks": BookmarkedTitles.AsList)
End Sub

Public Sub SetDataFromStore(o As Object)
	Dim m As Map = o
	Dim links As List = m.Get("links")
	Dim server As PLMServer = B4XPages.MainPage.GetServer
	For Each link As PLMLink In links
		Items.Put(link, CreateStackItem(B4XPages.MainPage.User, server, link, B4XCollections.CreateOrderedMap, _
			Constants.EmptyList, 0, 0))
	Next
	Dim bookmarks As List = m.Get("bookmarks")
	For Each title As String In bookmarks
		If GetFromTitle(title) <> Null Then
			BookmarkedTitles.Add(title)
		End If
	Next
End Sub



