B4J=true
Group=Network
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
Sub Class_Globals
	Type PLMContent (RootHtmlNode As HtmlNode)
	Type PLMAccount (Avatar As String, Id As String, Url As String, UserName As String, DisplayName As String, Acct As String, _
		Note As String, FollowersCount As Int, FollowingCount As Int, StatusesCount As Int, HeaderURL As String, Emojis As List)
	Type PLMTag (Name As String, Url As String)
	Type PLMStatus (Account As PLMAccount, Content As PLMContent, _
		id As String, CreatedAt As Long, Tags As List, URI As String, Url As String, Visibility As String, Attachments As List, _
		Sensitive As Boolean, InReplyToAccountAcct As String, RepliesCount As Int, ReblogsCount As Int, FavouritedCount As Int, _
		Mentions As List, Emojis As List, InReplyToAccountId As String, InReplyToId As String)
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
End Sub

Public Sub Initialize (Callback As Object)
	mCallback = Callback
	Statuses.Initialize
	DateTime.DateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
	Timer1.Initialize("Timer1", 100)
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
	If CallSub(mCallback, "IsWaitingForItems") = True Then
		Dim settings As Map = CreateMap("limit": 10, "only_media": False)
		If (mLink.FirstURL = "" And Statuses.Size > 0) Or (mLink.FirstURL <> "" And Statuses.Size > 1) Then
			Dim LastStatus As Object = Statuses.Get(Statuses.Keys.Get(Statuses.Size - 1))
			If LastStatus = NoMoreItems Then Return
			Dim sm As PLMStatus = LastStatus
			settings.Put("max_id", sm.id)
		Else
			settings.Put("limit", 5)
'			settings.Put("max_id", "9xvcPl6v8Us9Z4ZTEW")
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
	If user.SignedIn Then
		j.GetRequest.SetHeader("Authorization", "Bearer " & user.AccessToken)
	End If
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
	DownloadingTimeLines = False
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

Private Sub ParseAccount (s As String)
	Dim parser As JSONParser
	parser.Initialize(s)
	Dim account As PLMAccount = CreateAccount(parser.NextObject)
	Statuses.Put(account.Id, account)
End Sub

Private Sub ParseThread (s As String) As B4XOrderedMap
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	Dim parser As JSONParser
	parser.Initialize(s)
	Dim m As Map = parser.NextObject
	FillStatuses(res, m.Get("ancestors"))
	Dim status As PLMStatus = mLink.Extra.Get("current")
	res.Put(status.id, status)
	FillStatuses(res, m.Get("descendants"))
	Return res
End Sub

Private Sub ParseTimelines(s As String) As B4XOrderedMap
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	Dim parser As JSONParser
	parser.Initialize(s)
	FillStatuses (res, parser.NextArray)
	Return res
End Sub

Private Sub FillStatuses (res As B4XOrderedMap, RawItems As List)
	For Each StatusMap As Map In RawItems
		Dim status As PLMStatus
		status.Initialize
		status.Account = CreateAccount(StatusMap.Get("account"))
		status.Emojis = GetEmojies(StatusMap, 32)
		status.Content = CreateContent(StatusMap.Get("content"))
		status.Visibility = StatusMap.GetDefault("visibility", "")
		status.URI = StatusMap.Get("uri")
		status.Url = StatusMap.Get("url")
		status.id = StatusMap.Get("id")
		status.CreatedAt = ParseDate(StatusMap.Get("created_at"))
		status.Sensitive = StatusMap.GetDefault("sensitive", False)
		status.ReblogsCount = StatusMap.GetDefault("reblogs_count", 0)
		status.FavouritedCount = StatusMap.GetDefault("favourites_count", 0)
		status.RepliesCount = StatusMap.GetDefault("replies_count", 0)
		status.Mentions = StatusMap.Get("mentions")
		status.Attachments.Initialize
		Dim attachments As List = StatusMap.Get("media_attachments")
		For Each attachment As Map In attachments
			status.Attachments.Add(CreateAttachment(attachment))
		Next
		If StatusMap.ContainsKey("pleroma") Then
			Dim plm As Map = StatusMap.Get("pleroma")
			status.InReplyToAccountAcct = plm.GetDefault("in_reply_to_account_acct", "")
		End If
		status.InReplyToAccountId = StatusMap.Get("in_reply_to_account_id")
		status.InReplyToId = StatusMap.Get("in_reply_to_id")
		res.Put(status.id, status)
	Next
End Sub

Private Sub GetEmojies (Raw As Map, Size As Int) As List
	Dim res As List
	Dim emojis As List = Raw.Get("emojis")
	If emojis.Size > 0 Then
		res.Initialize
		For Each e As Map In emojis
			res.Add(CreatePLMEmoji(e.Get("shortcode"), e.Get("url"), Size))
		Next
	End If
	Return res
End Sub

Private Sub CreateAttachment (Attachment As Map) As PLMMedia
	Dim m As PLMMedia
	m.Initialize
	m.TType = Attachment.Get("type")
	m.Url = Attachment.Get("url")
	m.PreviewUrl = Attachment.Get("preview_url")
	Return m
End Sub

Private Sub ParseDate(s As String) As Long
	Return DateTime.DateParse(s.Replace("Z", "+0000"))
End Sub

Private Sub CreateAccount (Account As Map) As PLMAccount
	Dim ac As PLMAccount
	ac.Initialize
	ac.Avatar = Account.GetDefault("avatar", "")
	ac.Id = Account.Get("id")
	ac.Url = Account.Get("url")
	ac.UserName = Account.Get("username")
	ac.DisplayName = Account.Get("display_name")
	ac.Emojis = GetEmojies(Account, 14)
	ac.Note = Account.Get("note")
	ac.StatusesCount = Account.Get("statuses_count")
	ac.FollowersCount = Account.Get("followers_count")
	ac.FollowingCount = Account.Get("following_count")
	ac.HeaderURL = Account.Get("header")
	ac.Acct = Account.Get("acct")
	
	Return ac
End Sub


Private Sub CreateContent (RawContent As String) As PLMContent
	Dim pc As PLMContent
	pc.Initialize
	pc.RootHtmlNode = B4XPages.MainPage.TextUtils1.HtmlParser.Parse(RawContent)
	Return pc
End Sub

Private Sub CreatePLMEmoji (Shortcode As String, URL As String, Size As Int) As PLMEmoji
	Dim t1 As PLMEmoji
	t1.Initialize
	t1.Shortcode = Shortcode
	t1.URL = URL
	t1.Size = Size
	Return t1
End Sub