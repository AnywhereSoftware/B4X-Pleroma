B4J=true
Group=Network
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
Sub Class_Globals
	Type PLMContent (RootHtmlNode As HtmlNode)
	Type PLMAccount (Avatar As String, Id As String, Url As String, UserName As String, DisplayName As String, Acct As String, _
		Note As String, FollowersCount As Int, FollowingCount As Int, StatusesCount As Int, HeaderURL As String, Emojis As List, _
		FollowedBy As Boolean, Following As Boolean, RelationshipAdded As Boolean, FollowRequested As Boolean)
	Type PLMTag (Name As String, Url As String)
	Type PLMStatus (Account As PLMAccount, Content As PLMContent, _
		id As String, CreatedAt As Long, Tags As List, URI As String, Url As String, Visibility As String, Attachments As List, _
		Sensitive As Boolean, InReplyToAccountAcct As String, RepliesCount As Int, ReblogsCount As Int, FavouritesCount As Int, _
		Mentions As List, Emojis As List, InReplyToAccountId As String, InReplyToId As String, ExtraContent As Map, _
		EmojiReactions As List, Favourited As Boolean, Reblogged As Boolean)
	Type PLMMedia (Id As String, TType As String, Url As String, PreviewUrl As String)
	Type PLMLink (URL As String, LINKTYPE As Int, Title As String, FirstURL As String, Extra As Map)
	Type PLMEmoji (Shortcode As String, URL As String, Size As Int)
	
	Public Statuses As B4XOrderedMap
	Private Timer1 As Timer
	Private mCallback As Object
	Private DownloadingTimeLines As Boolean	
	Private DownloadIndex As Int
	Public mLink As PLMLink
	Public user As PLMUser
	Public server As PLMServer
	Public mTitle As String
	Public NoMoreItems As Object
	Private tu As TextUtils
End Sub

Public Sub Initialize (Callback As Object)
	mCallback = Callback
	Statuses.Initialize
	DateTime.DateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
	Timer1.Initialize("Timer1", 100)
	tu = B4XPages.MainPage.TextUtils1
End Sub

Public Sub Start (KeepStatuses As Boolean)
	Timer1.Enabled = True
	DownloadIndex = DownloadIndex + 1
	server = B4XPages.MainPage.Servers.Get(user.ServerName)
	If KeepStatuses = False Then
		Dim Statuses As B4XOrderedMap
		Statuses.Initialize
	End If
	DownloadingTimeLines = False
End Sub

Public Sub Stop
	Timer1.Enabled = False
	DownloadIndex = DownloadIndex + 1
End Sub

Private Sub Timer1_Tick
	If CallSub(mCallback, "TickAndIsWaitingForItems") = True Then
		Dim settings As Map = CreateMap("limit": 10, "only_media": False)
		If (mLink.FirstURL = "" And Statuses.Size > 0) Or (mLink.FirstURL <> "" And Statuses.Size > 1) Then
			Dim LastStatus As Object = Statuses.Get(Statuses.Keys.Get(Statuses.Size - 1))
			If LastStatus = NoMoreItems Then Return
			Dim sm As PLMStatus = LastStatus
			settings.Put("max_id", sm.id)
		Else
			settings.Put("limit", 5)
'			settings.Put("max_id", "9vJPAPHWZtnn9bwIls")
		End If
		DownloadTimelines(settings)
	End If
End Sub

Private Sub DownloadTimelines (Params As Map)
	If DownloadingTimeLines Then Return
	DownloadingTimeLines = True
	Dim MyIndex As Int = DownloadIndex
	Dim j As HttpJob
	j.Initialize("", Me)
	Dim url As String = server.URL & mLink.URL
	Dim DownloadingAccount As Boolean = Statuses.Size = 0 And mLink.FirstURL <> ""
	If DownloadingAccount Then url = server.URL & mLink.FirstURL
	j.Download2(url, MapToArray(Params))
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If MyIndex <> DownloadIndex Then
		j.Release
		Return
	End If
	If j.Success Then
		Dim CurrentSize As Int = Statuses.Size
		If DownloadingAccount Then
			ParseAccount (j.GetString)
		Else
			Dim res As B4XOrderedMap
			If mLink.LINKTYPE = B4XPages.MainPage.LINKTYPE_THREAD Then
				res = ParseThread(j.GetString)
			Else
				res = ParseTimelines(j.GetString)
			End If
			For Each id As String In res.Keys
				Statuses.Put(id, res.Get(id))
			Next
		End If
		If Statuses.Size = CurrentSize Then
			Log("no more items")
			Statuses.Put("last", NoMoreItems)
		End If
	End If
	If MyIndex = DownloadIndex Then
		DownloadingTimeLines = False
	End If
	j.Release
End Sub

Private Sub MapToArray(m As Map) As String()
	Dim s(m.Size * 2) As String
	Dim counter As Int
	For Each key As String In m.Keys
		s(counter) = key
		s(counter + 1) = m.Get(key)
		counter = counter + 2
	Next
	Return s
End Sub

Private Sub ParseAccount (s As String) As PLMAccount
	Dim account As PLMAccount = tu.CreateAccount(tu.JsonParseMap(s))
	Statuses.Put(account.Id, account)
	Return account
End Sub

Private Sub ParseThread (s As String) As B4XOrderedMap
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	Dim m As Map = tu.JsonParseMap(s)
	If m.IsInitialized = False Then Return res
	FillStatuses(res, m.Get("ancestors"))
	Dim status As PLMStatus = mLink.Extra.Get("current")
	res.Put(status.id, status)
	FillStatuses(res, m.Get("descendants"))
	Return res
End Sub

Private Sub ParseTimelines(s As String) As B4XOrderedMap
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	FillStatuses (res, tu.JsonParseList(s))
	Return res
End Sub

Private Sub FillStatuses (res As B4XOrderedMap, RawItems As List)
	If RawItems.IsInitialized = False Then Return
	For Each StatusMap As Map In RawItems
		Dim status As PLMStatus = tu.ParseStatus(StatusMap)
		res.Put(status.id, status)
	Next
End Sub





