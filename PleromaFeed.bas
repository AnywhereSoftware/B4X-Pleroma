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
		FollowedBy As Boolean, Following As Boolean, RelationshipAdded As Boolean, FollowRequested As Boolean, Muted As Boolean, Blocked As Boolean)
	Type PLMTag (Name As String, Url As String)
	Type PLMNotification (NotificationType As String, Id As String, CreatedAt As Long, Account As PLMAccount)
	Type PLMStatus (StatusAuthor As PLMAccount, Content As PLMContent, _
		id As String, CreatedAt As Long, Tags As List, URI As String, Url As String, Visibility As String, Attachments As List, _
		Sensitive As Boolean, InReplyToAccountAcct As String, RepliesCount As Int, ReblogsCount As Int, FavouritesCount As Int, _
		Mentions As List, Emojis As List, InReplyToAccountId As String, InReplyToId As String, ExtraContent As Map, _
		EmojiReactions As List, Favourited As Boolean, Reblogged As Boolean, StubForDuplicatedNotification As Boolean, Poll As PLMPoll)
	Type PLMMedia (Id As String, TType As String, Url As String, PreviewUrl As String)
	Type PLMLink (URL As String, LinkType As Int, Title As String, FirstURL As String, Extra As Map, NextURL As String)
	Type PLMEmoji (Shortcode As String, URL As String, Size As Int)
	Type PLMPost (ReplyToStatusId As String, Mentions As B4XSet, Visibility As String)
	Type PLMMiniAccount (Account As PLMAccount, Notification As PLMNotification, MetaChat As PLMMetaChat)
	Type PLMMetaChat (Id As String, Account As PLMAccount, Unread As Int, LastMessage As PLMChatMessage, UpdatedAt As Long)
	Type PLMChatMessage (ChatId As String, CreateAt As Long, Unread As Boolean, Emojies As List, Content As PLMContent, _
		Id As String, AccountId As String)
	Type PLMStub (Id As String, Height As Int, Text As String)
	Type PLMPoll (Id As String, ExpiresAt As Long, Expired As Boolean, Multiple As Boolean, VotesCount As Int, VotersCount As Int, UserVoted As Boolean, _
		Options As List, OwnVotes As List)
	Public Statuses As B4XOrderedMap
	Private Timer1 As Timer
	Private mCallback As Object
	Private DownloadingTimeLines As Boolean	
	Private DownloadIndex As Int
	Public mLink As PLMLink
	Public user As PLMUser
	Public server As PLMServer
	Public mTitle As String
	Public NoMoreItems As PLMStub
	Private tu As TextUtils
	Public Const NewPostId = "newpost", LastPostId = "last", ReactionsId = "reactions", FirstStubId = "first" As String
	Private ChatMan As ChatManager
	Public Const IndexOfFirstChatMessage As Int = 1
End Sub

Public Sub Initialize (Callback As ListOfStatuses)
	mCallback = Callback
	Statuses.Initialize
	
	Timer1.Initialize("Timer1", 100)
	tu = B4XPages.MainPage.TextUtils1
	ChatMan = Callback.Chat
	NoMoreItems = CreatePLMStub(LastPostId, 300dip, "No more items")
End Sub

'returns the new item index
Public Sub InsertItemAfter (AfterId As String, Status As Object, Id As String) As Int
	Dim i As Int = Statuses.Keys.IndexOf(AfterId)
	Statuses.Remove(Id)
	Statuses.Put(Id, Status)
	Statuses.Keys.RemoveAt(Statuses.Keys.Size - 1)
	Statuses.Keys.InsertAt(i + 1, Id)
	Return i + 1
End Sub

Public Sub InsertItemAt (Index As Int, Id As String, status As Object)
	Statuses.Remove(Id)
	Statuses.Put(Id, status)
	Statuses.Keys.RemoveAt(Statuses.Keys.Size - 1)
	Statuses.Keys.InsertAt(Index, Id)
End Sub

Public Sub Start (KeepStatuses As Boolean)
	DownloadIndex = DownloadIndex + 1
	Dim MyIndex As Int = DownloadIndex
	server = B4XPages.MainPage.GetServer
	If KeepStatuses = False Then
		Dim Statuses As B4XOrderedMap
		Statuses.Initialize
		mLink.NextURL = ""
	End If
	DownloadingTimeLines = False
	Wait For (B4XPages.MainPage.ServerManager1.VerifyInstanceFeatures(server)) Complete (Success As Boolean)
	If MyIndex <> DownloadIndex Then Return
	If user.SignedIn And user.Verified = False Then
		B4XPages.MainPage.VerifyUser
		Success = False
	End If
	Timer1.Enabled = Success
	If Success Then
		Dim features As PLMInstanceFeatures = B4XPages.MainPage.ServerManager1.GetServerFeatures(server)
		B4XPages.MainPage.ServerSupportsEmojiReactions = features.Features.Contains("pleroma_emoji_reactions")
		B4XPages.MainPage.ServerFeatures = features
		ChatMan.AfterServerVerified(features)
		Dim IsChat As Boolean = mLink.LinkType = Constants.LINKTYPE_CHAT
		If IsChat Then NoMoreItems.Height = 0dip Else NoMoreItems.Height = 300dip
	End If
End Sub

Public Sub Stop
	Timer1.Enabled = False
	DownloadIndex = DownloadIndex + 1
End Sub

Private Sub Timer1_Tick
	If CallSub(mCallback, "TickAndIsWaitingForItems") = True Then
		Dim LastStatus As Object
		If Statuses.Size > 0 Then LastStatus = Statuses.Get(Statuses.Keys.Get(Statuses.Size - 1))
		If LastStatus = NoMoreItems Then Return
		Dim settings As Map = CreateMap()
		Dim linktype As Int
		Dim ShouldAddMaxId As Boolean = True
		If mLink.NextURL <> "" Then
			'no parameters
			linktype = -1
			ShouldAddMaxId = False
		Else If mLink.FirstURL <> "" Then
			'user
			linktype = Constants.LINKTYPE_USER
			ShouldAddMaxId = False
		Else
			linktype = mLink.LinkType
		End If
		Select linktype
			Case Constants.LINKTYPE_SEARCH
				settings.Put("q", mLink.Extra.Get("query"))
				settings.Put("limit", 20)
			Case Constants.LINKTYPE_THREAD, Constants.LINKTYPE_TIMELINE, Constants.LINKTYPE_TAG
				settings.Put("limit", 10)
				settings.Put("only_media", False)
			Case Constants.LINKTYPE_NOTIFICATIONS
				settings.Put("limit", 10)
			Case Constants.LINKTYPE_CHATS_LIST
				ShouldAddMaxId = False
			Case Constants.LINKTYPE_DIRECTMESSAGES_LIST
				ShouldAddMaxId = False
		End Select
		If ShouldAddMaxId Then
			If LastStatus Is PLMStatus Then
				Dim sm As PLMStatus = LastStatus
				settings.Put("max_id", sm.id)
			Else If LastStatus Is PLMChatMessage Then
				Dim cm As PLMChatMessage = LastStatus
				settings.Put("max_id", cm.Id)
			Else
				settings.Put("limit", 5)
			End If
		End If
		
		If mLink.Extra.IsInitialized And mLink.Extra.ContainsKey("params") Then
			Dim p As Map = mLink.Extra.Get("params")
			For Each k As String In p.Keys
				settings.Put(k, p.Get(k))
			Next
		End If
		Download(settings)
	End If
End Sub

Private Sub Download (Params As Map)
	If DownloadingTimeLines Then Return
	DownloadingTimeLines = True
	Dim MyIndex As Int = DownloadIndex
	Dim j As HttpJob
	j.Initialize("", Me)
	Dim IsFirst As Boolean
	Dim url As String
	If Statuses.Size = 0 And mLink.FirstURL <> "" Then
		IsFirst = True
		url = server.URL & mLink.FirstURL
	Else If mLink.NextURL <> "" Then
		url = mLink.NextURL
	Else
		url = server.URL & mLink.URL
	End If
	j.Download2(url, MapToArray(Params))
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If MyIndex <> DownloadIndex Then
		j.Release
		Return
	End If
	If j.Success Then
		Dim res As B4XOrderedMap
		Dim CurrentSize As Int = Statuses.Size
		Dim str As String = j.GetString
		Select mLink.LINKTYPE
			Case Constants.LINKTYPE_SEARCH
				Wait For (ParseSearch(str)) Complete (res2 As B4XOrderedMap)
				res = res2
			Case Constants.LINKTYPE_THREAD
				res = ParseThread(str)
			Case Constants.LINKTYPE_TAG, Constants.LINKTYPE_TIMELINE
				res = ParseTimelines(str)
			Case Constants.LINKTYPE_NOTIFICATIONS
				Wait For (ParseNotifications(str, mLink.NextURL = "")) Complete (res2 As B4XOrderedMap)
				res = res2
				SetNextLink(j)
			Case Constants.LINKTYPE_USER
				Dim IsStatuses As Boolean = mLink.URL.EndsWith("statuses")
				If IsFirst Then
					Dim acct As PLMAccount = ParseAccount (str)
					If IsStatuses = False Then acct.Note = ""
				Else If IsStatuses Then
					res = ParseTimelines(j.GetString)
				Else
					SetNextLink(j)
					Wait For (ParseFollowersOrFollowing(tu.JsonParseList(str))) Complete (res2 As B4XOrderedMap)
					res = res2
				End If
			Case Constants.LINKTYPE_CHAT
				ParseChat(str) 'fills Statuses internally
			Case Constants.LINKTYPE_CHATS_LIST
				ParseChatsList(str)
			Case Constants.LINKTYPE_DIRECTMESSAGES_LIST
				ParseDirectMessagesList(str)
				SetNextLink(j)
		End Select
		If MyIndex = DownloadIndex Then
			If res.IsInitialized Then
				For Each id As String In res.Keys
					Statuses.Put(id, res.Get(id))
				Next
			End If
			If Statuses.Size = CurrentSize Then
				If mLink.LinkType = Constants.LINKTYPE_CHAT Then
					If Statuses.Size > 1 Then
						Dim LastMessage As PLMChatMessage = Statuses.Get(Statuses.Keys.Get(Statuses.Size - 1))
						AddDateStubIfNeeded(LastMessage.CreateAt, 0, False)
					End If
				End If
				Statuses.Put(LastPostId, NoMoreItems)
			End If
		End If
	End If
	If MyIndex = DownloadIndex Then
		DownloadingTimeLines = False
	End If
	j.Release
End Sub

Private Sub SetNextLink (job As HttpJob)
	Dim h As Map = job.Response.GetHeaders
	If h.ContainsKey("link") Then
		#if B4J or B4A
		Dim items As List = h.Get("link")
		Dim raw As String = items.Get(0)
		#else if B4i
		Dim raw As String = h.Get("link")
		#end if
		Dim m As Matcher = Regex.Matcher("<([^>]+)>;\s*rel=\""next\""", raw)
		If m.Find Then
			mLink.NextURL = m.Group(1)
		End If
	End If
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

Private Sub ParseSearch (s As String) As ResumableSub
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	Dim m As Map = tu.JsonParseMap(s)
	
	If m.IsInitialized Then
		Dim accounts As List = m.Get("accounts")
		If accounts.Size > 0 Then
			Wait For (ParseFollowersOrFollowing(accounts)) Complete (AccountsRes As B4XOrderedMap)
		End If
		Dim stats As B4XOrderedMap = B4XCollections.CreateOrderedMap
		FillStatuses(stats, m.Get("statuses"))
		If AccountsRes = Null Or AccountsRes.IsInitialized = False Then
			res = stats
		Else
			Dim arr() As Object = Array(AccountsRes, stats)
			For i = 0 To Max(AccountsRes.Size - 1, stats.Size - 1) Step 5
				For Each map As B4XOrderedMap In arr
					For x = i To Min(i + 4, map.Size - 1)
						Dim key As String = map.Keys.Get(x)
						res.Put(key, map.get(key))
					Next
				Next
			Next
		End If
	End If
	res.Put("last", NoMoreItems)
	Return res
End Sub

Private Sub ParseThread (s As String) As B4XOrderedMap
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	Dim m As Map = tu.JsonParseMap(s)
	If m.IsInitialized = False Then Return res
	FillStatuses(res, m.Get("ancestors"))
	Dim status As PLMStatus = mLink.Extra.Get(Constants.LinkExtraCurrentStatus)
	res.Put(status.id, status)
	FillStatuses(res, m.Get("descendants"))
	Return res
End Sub

Private Sub ParseNotifications (s As String, UpdateMostRecent As Boolean) As ResumableSub
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	Dim list As List = tu.JsonParseList(s)
	If list.IsInitialized = False Then Return res
	Dim StatusNotifications As List = Array("mention", "reblog", "poll", "favourite")
	Dim AccountForRelationship As Map
	AccountForRelationship.Initialize
	Dim MostRecent As Long
	For Each m As Map In list
		Dim notif As PLMNotification = CreatePLMNotification(m.Get("type"), m.Get("id"), tu.ParseDate(m.GetDefault("created_at", "")), _
			tu.CreateAccount(m.Get("account")))
		If MostRecent = 0 Then MostRecent = notif.CreatedAt
		If StatusNotifications.IndexOf(notif.NotificationType) > -1 Then
			If m.ContainsKey("status") Then
				Dim St As PLMStatus = tu.ParseStatus(m.Get("status"))
				If res.ContainsKey(St.id) Then
					St.StubForDuplicatedNotification = True
					res.Put(notif.Id, St)
				Else
					res.Put(St.id, St)
				End If
				tu.PutExtraInStatus(St, Constants.ExtraContentKeyNotification, notif)
			Else
				Log("Status missing from notification: " & s)
			End If
		Else
			Dim mp As PLMMiniAccount
			mp.Initialize
			mp.Account = notif.Account
			mp.Notification = notif
			AccountForRelationship.Put(mp.Account.Id, mp.Account)
			res.Put(notif.Id, mp)
		End If
	Next
	If AccountForRelationship.Size > 0 Then
		Wait For (tu.AddRelationship(AccountForRelationship)) Complete (Success As Boolean)
	End If
	If UpdateMostRecent Then
		B4XPages.MainPage.Stream.MostRecentNotification = MostRecent
	End If
	Return res
End Sub

Private Sub ParseFollowersOrFollowing (accounts As List) As ResumableSub
	Dim res As B4XOrderedMap = B4XCollections.CreateOrderedMap
	If accounts.IsInitialized = False Then Return res
	Dim ParsedAccounts As Map
	ParsedAccounts.Initialize
	For Each m As Map In accounts
		Dim account As PLMAccount = tu.CreateAccount(m)
		Dim mp As PLMMiniAccount
		mp.Initialize
		mp.Account = account
		res.Put(account.Id, mp)
		ParsedAccounts.Put(account.Id, account)
	Next
	If ParsedAccounts.Size > 0 Then
		Wait For (tu.AddRelationship(ParsedAccounts)) Complete (Success As Boolean)
	End If
	Return res
End Sub

Private Sub ParseChat (s As String)
	Dim messages As List = tu.JsonParseList(s)
	If Statuses.Size = 0 Then
		Statuses.Put(FirstStubId, CreatePLMStub(FirstStubId, 120dip, ""))
	End If
	Dim LastMessage As PLMChatMessage
	If Statuses.Size > IndexOfFirstChatMessage Then
		LastMessage = Statuses.Get(Statuses.Keys.Get(Statuses.Size - 1))
	End If
	If messages.IsInitialized Then
		For i = 0 To messages.Size - 1
			Dim message As Map = messages.Get(i)
			Dim cm As PLMChatMessage = tu.ParseChatMessage(message)
			If LastMessage.IsInitialized Then
				AddDateStubIfNeeded(LastMessage.CreateAt, cm.CreateAt, False)
			End If
			LastMessage = cm
			Statuses.Put(cm.Id, cm)
		Next
	End If
End Sub

Private Sub ParseChatsList (s As String)
	Dim messages As List = tu.JsonParseList(s)
	For Each message As Map In messages
		Dim cm As PLMMetaChat = tu.ParseMetaChat(message)
		Dim MiniAccount As PLMMiniAccount
		MiniAccount.Initialize
		MiniAccount.Account = cm.Account
		MiniAccount.MetaChat = cm
		Statuses.Put(cm.Id, MiniAccount)
	Next
	Statuses.Put(LastPostId, NoMoreItems)
End Sub

Private Sub ParseDirectMessagesList (s As String)
	Dim conversations As List = tu.JsonParseList(s)
	If conversations.IsInitialized Then
		For Each conv As Map In conversations
			If conv.ContainsKey("last_status") Then
				Dim rawaccounts As List = conv.Get("accounts")
				Dim accounts As List
				accounts.Initialize
				For Each acct As Map In rawaccounts
					accounts.Add(tu.CreateAccount(acct))
				Next
				Dim st As Map = conv.Get("last_status")
				Dim status As PLMStatus = tu.ParseStatus(st)
				status.StatusAuthor = accounts.Get(0)
				tu.PutExtraInStatus(status, Constants.ExtraContentKeyDirectMessageAccounts, accounts)
				Statuses.Put(status.id, status)
			End If
		Next
	End If
End Sub

Public Sub AddDateStubIfNeeded (LastDate As Long, CurrentDate As Long, InsertAtTheBeginning As Boolean) As Boolean
	If DateTime.GetDayOfYear(LastDate) <> DateTime.GetDayOfYear(CurrentDate) Then
		Dim s As String
		If DateUtils.IsSameDay(DateTime.Now, LastDate) Then
			s = "Today"
		Else If DateUtils.IsSameDay(DateTime.Now - DateTime.TicksPerDay, LastDate) Then 'not 100% accurate
			s = "Yesterday"
		Else
			s = $"$1.0{DateTime.GetMonth(LastDate)}/$1.0{DateTime.GetDayOfMonth(LastDate)}/${NumberFormat2(DateTime.GetYear(LastDate), 1, 0, 0, False)}"$
		End If
		Dim id As String = "date-" & s
		Dim stub As PLMStub = CreatePLMStub(id, 30dip, s)
		If InsertAtTheBeginning Then
			InsertItemAt(IndexOfFirstChatMessage, id, stub)
		Else
			Statuses.Put(id, stub)
		End If
		Return True
	End If
	Return False
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


Public Sub CreatePLMPost (ReplyId As String, Visibility As String) As PLMPost
	Dim t1 As PLMPost
	t1.Initialize
	t1.ReplyToStatusId = ReplyId
	t1.Mentions.Initialize
	t1.Visibility = Visibility
	Return t1
End Sub

Public Sub getIsRunning As Boolean
	Return Timer1.Enabled
End Sub

Public Sub CreatePLMNotification (NotificationType As String, Id As String, CreatedAt As Long, Account As PLMAccount) As PLMNotification
	Dim t1 As PLMNotification
	t1.Initialize
	t1.NotificationType = NotificationType
	t1.Id = Id
	t1.CreatedAt = CreatedAt
	t1.Account = Account
	Return t1
End Sub



Public Sub CreatePLMStub (Id As String, Height As Int, Text As String) As PLMStub
	Dim t1 As PLMStub
	t1.Initialize
	t1.Id = Id
	t1.Height = Height
	t1.Text = Text
	Return t1
End Sub