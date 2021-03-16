B4J=true
Group=Text
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
Sub Class_Globals
	Public TextEngine As BCTextEngine
	Private xui As XUI
	Public UrlColor As Int = 0xFF007EA9
	Public HtmlParser As MiniHtmlParser
	Public HtmlConverter As HtmlToRuns
	Public NBSP As String
	Private JParser As JSONParser
	Public Const MultipartBoundary As String = "---------------------------14623423412"
	Private mTheme As ThemeManager
End Sub

Public Sub Initialize
	TextEngine.Initialize (xui.CreatePanel(""))
	TextEngine.WordBoundaries = "&*+-/<>=\ ,:{}" & TAB & CRLF & Chr(13)
	TextEngine.TagParser.UrlColor = UrlColor
	HtmlParser.Initialize
	HtmlConverter.Initialize(TextEngine, HtmlParser)
	NBSP = Chr(0x202F)
	mTheme = B4XPages.MainPage.Theme
End Sub

Public Sub ManageLink (Status As PLMStatus, Account As PLMAccount, URL As String, Text As String) As PLMLink
	If URL.StartsWith("~@") Then
		Dim c As Int = URL.IndexOf(":")
		Dim Method As String = URL.SubString2(2, c)
		Dim id As String = URL.SubString(c + 1)
		Return CreateUserLink(id, Text, Method)
	End If
	If Status <> Null Then
		If URL = Constants.TextRunThreadLink Then
			Dim u As String = Constants.URL_THREAD.Replace(":id", Status.Id)
			Dim link As PLMLink = CreatePLMLink2(u, Constants.LINKTYPE_THREAD, "Conversation", "")
			Dim NewStatus As PLMStatus = DuplicateStatus(Status)
			If NewStatus.ExtraContent.IsInitialized Then
				NewStatus.ExtraContent.Remove(Constants.ExtraContentKeyNotification)
				NewStatus.ExtraContent.Remove(Constants.ExtraContentKeyReblog)
				NewStatus.ExtraContent.Remove(Constants.ExtraContentKeyDirectMessageAccounts)
			End If
			link.Extra = CreateMap(Constants.LinkExtraCurrentStatus: NewStatus, "targetId": Status.id)
			Return link
		Else If Text.Length > 1 And Text.StartsWith("@") Then
			Dim name As String = Text.SubString(1)
			For Each m As Map In Status.Mentions
				If name = m.Get("username") Then
					Return CreateUserLink(m.Get("id"), name, "statuses")
				End If
				If name = Status.StatusAuthor.UserName Then
					Return ManageLink(Status, Account, "@", Text)
				End If
			Next
		End If
	End If
	If URL = "@" Then
		Return CreateUserLink(Account.Id, Account.UserName, "statuses")
	Else If Regex.IsMatch("#\w+", Text) Then
		Return CreatePLMLink(Constants.URL_TAG & Text.SubString(1), Constants.LINKTYPE_TAG, Text)
	End If
	Return CreatePLMLink(URL, Constants.LINKTYPE_OTHER, URL)
End Sub

Public Sub CreateSpecialUrl(Method As String, Id As String) As String
	Return "~@" & Method & ":" & Id
End Sub


Public Sub CreateUserLink (id As String, name As String, Method As String) As PLMLink
	Dim u As String = Constants.URL_USER.Replace(":id", id)
	Return CreatePLMLink2(u & "/" & Method, Constants.LINKTYPE_USER, "@" & name & MethodToTitle (Method), u)
End Sub

Private Sub MethodToTitle (method As String) As String
	If method = "" Then Return ""
	Return " (" & method.SubString2(0, 1).ToUpperCase & method.SubString(1) & ")"
End Sub

Public Sub CreateUserLinkWithMutedOrSimilar (id As String, name As String, link As String, method As String) As PLMLink
	Dim u As String = Constants.URL_USER.Replace(":id", id)
	Return CreatePLMLink2(link, Constants.LINKTYPE_USER, "@" & name & MethodToTitle(method), u)
End Sub


Public Sub CreatePLMLink (URL As String, LINKTYPE As Int, Title As String) As PLMLink
	Return CreatePLMLink2(URL, LINKTYPE, Title, "")	
End Sub

Public Sub CreatePLMLink2 (URL As String, LINKTYPE As Int, Title As String, FirstUrl As String) As PLMLink
	Dim t1 As PLMLink
	t1.Initialize
	t1.URL = URL
	t1.LINKTYPE = LINKTYPE
	t1.Title = Title
	t1.FirstUrl = FirstUrl
	Return t1
End Sub

Public Sub TextWithEmojisToRuns(Input As String, RunsList As List, Emojis As List, Data As BBCodeParseData, Fnt As B4XFont)
	If Emojis.IsInitialized = False Then
		RunsList.Add(CreateRun(Input, Fnt))
		Return
	End If
	Dim m As Matcher = Regex.Matcher(":(\w+):", Input)
	Dim lastMatchEnd As Int = 0
	Do While m.Find
		Dim currentStart As Int = m.GetStart(0)
		RunsList.Add(CreateRun(Input.SubString2(lastMatchEnd, currentStart).Replace(Chr(0x200d), ""), Fnt))
		lastMatchEnd = m.GetEnd(0)
		'apply styling here
		For Each Emoji As PLMEmoji In Emojis
			If Emoji.Shortcode = m.Group(1) Then
				Dim views As Map = Data.Views
				Dim id As String = views.Size
				Dim iv As B4XView = B4XPages.MainPage.ViewsCache1.GetImageView
				Dim consumer As ImageConsumer = iv.Tag
				consumer.NoAnimation = True
				B4XPages.MainPage.ImagesCache1.SetImage(Emoji.URL, consumer, B4XPages.MainPage.ImagesCache1.RESIZE_NONE)
				views.Put(id, iv)
				Data.ViewsPanel.AddView(iv, 0, 0, DipToCurrent(Emoji.Size), DipToCurrent(Emoji.Size))
				Dim run As BCTextRun = TextEngine.CreateRun("")
				run.View = iv
				RunsList.Add(run)
			End If
		Next
	Loop
	If lastMatchEnd < Input.Length Then RunsList.Add(CreateRun(Input.SubString(lastMatchEnd), Fnt))
End Sub

Public Sub CreateRun(Text As String, Fnt As B4XFont) As BCTextRun
	Dim r As BCTextRun = TextEngine.CreateRun(Text)
	r.TextFont = Fnt
	r.TextColor = mTheme.DefaultText
	Return r
End Sub

Public Sub CreateUrlRun (URL As String, Text As String, Data As BBCodeParseData) As BCTextRun
	Dim Run As BCTextRun = TextEngine.CreateRun(Text)
	Data.URLs.Put(Run, URL)
	Run.Underline = True
	Run.TextColor = Data.UrlColor
	Return Run
End Sub


Public Sub ParseStatus (StatusMap As Map) As PLMStatus
	Dim status As PLMStatus
	If StatusMap.IsInitialized = False Then Return status
	status.Initialize
	If StatusMap.Get("reblog") <> Null Then
		Dim reblog As Map = StatusMap.Get("reblog")
		PutExtraInStatus(status, Constants.ExtraContentKeyReblog, CreateAccount(StatusMap.Get("account")))
		StatusMap = reblog
	End If
	If StatusMap.Get("card") <> Null Then
		PutExtraInStatus(status, Constants.ExtraContentKeyCard, StatusMap.Get("card"))
	End If
	status.StatusAuthor = CreateAccount(StatusMap.Get("account"))
	status.Emojis = GetEmojies(StatusMap, 32)
	status.Content = CreateContent(StatusMap.Get("content"))
	status.Visibility = StatusMap.GetDefault("visibility", "")
	status.URI = StatusMap.GetDefault("uri", "")
	status.Url = StatusMap.GetDefault("url", "")
	status.id = StatusMap.Get("id")
	status.CreatedAt = ParseDate(StatusMap.GetDefault("created_at", ""))
	status.Sensitive = StatusMap.GetDefault("sensitive", False)
	status.ReblogsCount = StatusMap.GetDefault("reblogs_count", 0)
	status.FavouritesCount = StatusMap.GetDefault("favourites_count", 0)
	status.Favourited = StatusMap.GetDefault("favourited", False)
	status.Reblogged = StatusMap.GetDefault("reblogged", False)
	status.RepliesCount = StatusMap.GetDefault("replies_count", 0)
	status.Mentions = StatusMap.Get("mentions")
	status.Poll = CreatePoll(StatusMap.Get("poll"))
	status.Attachments.Initialize
	Dim attachments As List = StatusMap.Get("media_attachments")
	If attachments.IsInitialized Then
		For Each attachment As Map In attachments
			status.Attachments.Add(CreateAttachment(attachment))
		Next
	End If
	If StatusMap.ContainsKey("pleroma") Then
		Dim plm As Map = StatusMap.Get("pleroma")
		status.EmojiReactions = plm.GetDefault("emoji_reactions", Constants.EmptyList)
		status.InReplyToAccountAcct = plm.GetDefault("in_reply_to_account_acct", "")
	End If
	status.InReplyToAccountId = StatusMap.Get("in_reply_to_account_id")
	status.InReplyToId = StatusMap.Get("in_reply_to_id")
	Return status
End Sub

Public Sub CreatePoll (raw As Map) As PLMPoll
	Dim poll As PLMPoll
	If raw.IsInitialized = False Or raw.ContainsKey("options") = False Then Return poll
	poll.Initialize
	poll.Expired = raw.GetDefault("expired", True)
	poll.ExpiresAt = ParseDate(raw.GetDefault("expires_at", ""))
	poll.Id = raw.Get("id")
	poll.Multiple = raw.GetDefault("multiple", False)
	poll.Options = raw.Get("options")
	poll.UserVoted = raw.GetDefault("voted", False)
	poll.OwnVotes = raw.GetDefault("own_votes", Constants.EmptyList)
	Dim v As Object = raw.Get("voters_count")
	If v <> Null And IsNumber(v) Then
		poll.VotersCount = v
	End If
	poll.VotesCount = raw.GetDefault("votes_count", 0)
	Return poll
End Sub

Public Sub DuplicateStatus(OldStatus As PLMStatus) As PLMStatus
	Dim status As PLMStatus
	status.Initialize
	If OldStatus.ExtraContent.IsInitialized Then
		status.ExtraContent.Initialize
		For Each k As String In OldStatus.ExtraContent.Keys
			status.ExtraContent.Put(k, OldStatus.ExtraContent.Get(k))
		Next
	End If
	status.StatusAuthor = OldStatus.StatusAuthor
	status.Emojis = OldStatus.Emojis
	status.Content = OldStatus.Content
	status.Visibility = OldStatus.Visibility
	status.URI = OldStatus.URI
	status.Url = OldStatus.Url
	status.id = OldStatus.id
	status.CreatedAt = OldStatus.CreatedAt
	status.Sensitive = OldStatus.Sensitive
	status.ReblogsCount = OldStatus.ReblogsCount
	status.FavouritesCount = OldStatus.FavouritesCount
	status.Favourited = OldStatus.Favourited
	status.Reblogged = OldStatus.Reblogged
	status.RepliesCount = OldStatus.RepliesCount
	status.Mentions = OldStatus.Mentions
	status.Attachments = OldStatus.Attachments
	status.EmojiReactions = OldStatus.EmojiReactions
	status.InReplyToAccountAcct = OldStatus.InReplyToAccountAcct
	status.InReplyToAccountId = OldStatus.InReplyToAccountId
	status.InReplyToId = OldStatus.InReplyToId
	Return status
End Sub

Public Sub PutExtraInStatus(Status As PLMStatus, Key As String, Value As Object)
	If Status.ExtraContent.IsInitialized = False Then Status.ExtraContent.Initialize
	Status.ExtraContent.Put(Key, Value)
End Sub

Public Sub ParseChatMessage (Message As Map) As PLMChatMessage
	Dim cm As PLMChatMessage
	cm.Initialize
	cm.ChatId = Message.Get("chat_id")
	cm.Id = Message.Get("id")
	cm.Unread = Message.GetDefault("unread", False)
	cm.Content = CreateContent(Message.Get("content"))
	cm.Emojies = GetEmojies(Message, 32)
	cm.CreateAt = ParseDate(Message.GetDefault("created_at", ""))
	cm.AccountId = Message.GetDefault("account_id", "")
	Return cm
End Sub

Private Sub GetEmojies (Raw As Map, Size As Int) As List
	Dim res As List
	Dim emojis As List = Raw.Get("emojis")
	If emojis.IsInitialized And emojis.Size > 0 Then
		res.Initialize
		For Each e As Map In emojis
			res.Add(CreatePLMEmoji(e.Get("shortcode"), e.GetDefault("url", ""), Size))
		Next
	End If
	Return res
End Sub

Public Sub CreateAttachment (Attachment As Map) As PLMMedia
	Dim m As PLMMedia
	m.Initialize
	m.TType = Attachment.Get("type")
	m.Url = Attachment.GetDefault("url", "")
	m.PreviewUrl = Attachment.GetDefault("preview_url", "")
	m.Id = Attachment.GetDefault("id", "")
	Return m
End Sub

Public Sub ParseDate(s As String) As Long
	Dim res As Long
	Try
		If s = "" Then Return DateTime.Now
		If Regex.IsMatch(".*\.\d\d\d.*", s) = False Then
			Dim i As Int = s.IndexOf("+")
			If i = -1 Then i = s.LastIndexOf("-")
			s = s.SubString2(0, i) & ".000" & s.SubString(i)
		End If
		DateTime.DateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		res = DateTime.DateParse(s.Replace("Z", "+0000"))
	Catch
		Log(LastException)
		res = DateTime.Now
	End Try
	DateTime.DateFormat = Constants.DateFormat
	Return res
End Sub

Public Sub CreateAccount (Account As Map) As PLMAccount
	Dim ac As PLMAccount
	If Account.IsInitialized = False Then Return ac
	ac.Initialize
	ac.Avatar = Account.GetDefault("avatar", "")
	ac.Id = Account.Get("id")
	ac.Url = Account.GetDefault("url", "")
	ac.UserName = Account.Get("username")
	ac.DisplayName = Account.Get("display_name")
	ac.Emojis = GetEmojies(Account, 14)
	ac.Note = Account.Get("note")
	ac.StatusesCount = Account.GetDefault("statuses_count", 0)
	ac.FollowersCount = Account.GetDefault("followers_count", 0)
	ac.FollowingCount = Account.GetDefault("following_count", 0)
	ac.HeaderURL = Account.GetDefault("header", "")
	ac.Acct = Account.Get("acct")
	Return ac
End Sub


Private Sub CreateContent (RawContent As String) As PLMContent
	Dim pc As PLMContent
	pc.Initialize
	pc.RootHtmlNode = HtmlParser.Parse(RawContent)
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

Public Sub DownloadStatus (id As String) As ResumableSub
	Dim j As HttpJob
	j.Initialize("", Me)
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses/${id}"$
	j.Download(link)
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Dim status As PLMStatus = ParseStatus(JsonParseMap(j.GetString))
		j.Release
		Return status
	End If
	j.Release
	Return Null
End Sub

Public Sub JsonParseList (s As String) As List
	Dim res As List
	Try
		JParser.Initialize(s)
		res = JParser.NextArray
	Catch
		Log(LastException)
	End Try
	Return res
End Sub

Public Sub JsonParseMap (s As String) As Map
	Dim res As Map
	Try
		JParser.Initialize(s)
		res = JParser.NextObject
	Catch
		Log(LastException)
	End Try
	Return res
End Sub

Public Sub ParseMetaChat (m As Map) As PLMMetaChat
	Dim Chat As PLMMetaChat
	Chat.Initialize
	Chat.ID = m.Get("id")
	Chat.Account = CreateAccount(m.Get("account"))
	Chat.Unread = m.GetDefault("unread", 0)
	Chat.UpdatedAt = ParseDate(m.GetDefault("updated_at", ""))
	Dim last As Map = m.Get("last_message")
	If last.IsInitialized Then
		Chat.LastMessage = ParseChatMessage(last)
	End If
	Return Chat
End Sub

Public Sub AddRelationship (accounts As Map) As ResumableSub
	If B4XPages.MainPage.User.SignedIn = False Then Return False
	Dim j As HttpJob
	j.Initialize("", Me)
	Dim ids As StringBuilder
	ids.Initialize
	For Each key As String In accounts.Keys
		If ids.Length > 0 Then ids.Append("&")
		ids.Append("id[]=").Append(key)
	Next
	j.Download(B4XPages.MainPage.GetServer.URL & "/api/v1/accounts/relationships?" & ids.ToString)
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Dim r As List = JsonParseList(j.GetString)
		If r.IsInitialized Then
			For Each m As Map In r
				GetRelationshipFromRelationshipObject(accounts.Get(m.Get("id")), m)
			Next
		End If
	End If
	j.Release
	Return False
End Sub

Public Sub GetRelationshipFromRelationshipObject (Account As PLMAccount, m As Map)
	Account.RelationshipAdded = True
	Account.Following = m.GetDefault("following", False)
	Account.FollowRequested = m.GetDefault("requested", False)
	Account.Muted = m.GetDefault("muting", False)
	Account.Blocked = m.GetDefault("blocking", False)
End Sub

Private Sub VerbOrUnverb (Account As PLMAccount, Verb As String) As ResumableSub
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then Return False
	Select Verb
		Case "follow"
			If Account.Following Or Account.FollowRequested Then
				Verb = "unfollow"
			End If
		Case "mute"
			If Account.Muted Then
				Verb = "unmute"
			End If
		Case "block"
			If Account.Blocked Then
				Verb = "unblock"
			End If
	End Select
	B4XPages.MainPage.ShowProgress
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/accounts/${Account.id}/${Verb}"$
	Dim j As HttpJob
	j.Initialize("", Me)
	j.PostString(link, "")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Dim m As Map = JsonParseMap(j.GetString)
		If m.IsInitialized Then
			GetRelationshipFromRelationshipObject(Account, m)
		End If
	End If
	j.Release
	B4XPages.MainPage.HideProgress
	Return False
End Sub

Public Sub UpdateFollowButton (btnFollow As B4XView, mAccount As PLMAccount, Mini As Boolean) As ResumableSub
	btnFollow.Tag = mAccount
	Dim WasAlreadyInvisible As Boolean = btnFollow.Visible = False
	btnFollow.Visible = False
	If mAccount.Id = B4XPages.MainPage.User.Id Then Return False
	Dim ShouldUpddate As Boolean = False
	If mAccount.RelationshipAdded = False Then
		B4XPages.MainPage.ShowProgress
		Wait For (B4XPages.MainPage.TextUtils1.AddRelationship(CreateMap(mAccount.Id: mAccount))) Complete (Unused As Boolean)
		If btnFollow.Tag <> mAccount Then Return False
		B4XPages.MainPage.HideProgress
		ShouldUpddate = True
	End If
	If mAccount.Following Then
		btnFollow.Text = "Unfollow"
	Else If mAccount.FollowRequested Then
		btnFollow.Text = "Requested"
	Else
		btnFollow.Text = "Follow"
	End If
	If WasAlreadyInvisible = False Then
		btnFollow.Visible = True
	End If
	Return ShouldUpddate
End Sub

Public Sub SetAccountTopText (bbTop As BBListItem, Account As PLMAccount, Notif As PLMNotification, Mini As Boolean, MetaChat As PLMMetaChat)
	bbTop.PrepareBeforeRuns
	Dim runs As List
	runs.Initialize
	Dim displayname As String = Account.DisplayName & " "
	If Account.RelationshipAdded Then
		If Account.Blocked Then 
			displayname = displayname & "(blocked) "
		Else If Account.Muted Then
			displayname = displayname & "(muted) "
		End If
	End If
	TextWithEmojisToRuns(displayname, runs, Account.Emojis, bbTop.ParseData, xui.CreateDefaultBoldFont(14))
	If MetaChat <> Null And MetaChat.IsInitialized Then
		If MetaChat.Unread > 0 Then
			Dim run As BCTextRun = CreateRun(" (" & MetaChat.Unread & ")", xui.CreateDefaultBoldFont(12))
			run.TextColor = xui.Color_Red
			runs.Add(run)
		End If
		If MetaChat.LastMessage.IsInitialized And MetaChat.LastMessage.Content.IsInitialized Then
		runs.Add(TextEngine.CreateRun(CRLF))
			runs.AddAll(HtmlConverter.ConvertHtmlToRuns(MetaChat.LastMessage.Content.RootHtmlNode, bbTop.ParseData, MetaChat.LastMessage.Emojies))
		End If
	Else
		Dim r As BCTextRun = CreateUrlRun("@", Account.Acct, bbTop.ParseData)
		runs.Add(r)
	End If
	If Notif <> Null And Notif.IsInitialized Then
		runs.Add(TextEngine.CreateRun(CRLF))
		runs.Add(CreateRun(Chr(0xF234) & " followed you", xui.CreateFontAwesome(14)))
	End If
	If Mini = False Then
		For Each run As BCTextRun In runs
			run.TextColor = mTheme.DefaultText
		Next
	End If
	bbTop.SetRuns(runs)
	bbTop.UpdateVisibleRegion(0, 300dip)
	bbTop.ChangeVisibility(True)
End Sub

Public Sub OtherAccountMoreClicked (btnFollow As B4XView, AccountHolder() As PLMAccount, Mini As Boolean, bbtob As BBListItem, notif As PLMNotification, MetaChat As PLMMetaChat)
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then Return
	Dim Account As PLMAccount = AccountHolder(0)
	Dim items As List
	items.Initialize
	items.Add(CreateMenuItem(0xF086, "Chat"))
	items.Add(CreateMenuItem(0xF003, "Direct message"))
	Dim text As String
	If Account.Muted Then text = "Unmute" Else text = "Mute"
	items.Add(CreateMenuItem(0xF028, text))
	If Account.Blocked Then text = "Unblock" Else text = "Block"
	items.Add(CreateMenuItem(0xF235, text))
	items.Add(CreateMenuItem(0xF024, "Report"))
	Wait For (B4XPages.MainPage.ShowListDialog(items, Not(Mini))) Complete (result As String)
	If Account <> AccountHolder(0) Then Return
	Dim i As Int = items.IndexOf(result)
	Dim verb As String
	Select i
		Case 0
			Dim statuses As ListOfStatuses = B4XPages.MainPage.Statuses
			Dim cm As ChatManager = statuses.Chat
			If cm.ChatSupported = False Then
				B4XPages.MainPage.ShowMessage("Instance does not support this feature.")
			Else
				cm.StartChat(Account)
			End If
			Return
		Case 1
			B4XPages.MainPage.ShowCreatePostInDialog (Account.Acct, "direct")
			Return
		Case 2
			verb = "mute"
		Case 3
			verb = "block"
		Case 4
			B4XPages.MainPage.Report.Show(Account, "")
			Return
		Case Else
			Return
	End Select
	Wait For (VerbOrUnverb(Account, verb)) Complete (unused As Boolean)
	If Account <> AccountHolder(0) Then Return
	SetAccountTopText(bbtob, Account, notif, Mini, MetaChat)
	
	
End Sub

Public Sub FollowButtonClicked (btnFollow As B4XView, AccountHolder() As PLMAccount, Verb As String, Mini As Boolean) As ResumableSub
	Dim Account As PLMAccount = AccountHolder(0)
	Wait For (VerbOrUnverb(Account, Verb)) Complete (unused As Boolean)
	If Account <> AccountHolder(0) Then Return False
	UpdateFollowButton(btnFollow, Account, Mini)
	If Account.Following = False And Account.FollowRequested Then
		Sleep(1000)
		Wait For (AddRelationship(CreateMap(Account.Id: Account))) Complete (unused As Boolean)
		If Account <> AccountHolder(0) Then Return False
		UpdateFollowButton(btnFollow, Account, Mini)
	End If
	Return True
End Sub

Public Sub CreateHttpJob (target As Object, HapticView As B4XView, UserRequired As Boolean) As HttpJob
	If HapticView.IsInitialized Then
		XUIViewsUtils.PerformHapticFeedback(HapticView)
	End If
	If UserRequired And B4XPages.MainPage.MakeSureThatUserSignedIn = False Then 
		Return Null
	End If
	B4XPages.MainPage.ShowProgress
	Dim j As HttpJob
	j.Initialize("", target)
	Return j
End Sub

'Taken from HttpJob.PostMultipart
Public Sub CreateMultipart(NameValues As Map, Files As List) As Byte()
	Dim stream As OutputStream
	stream.InitializeToBytesArray(0)
	Dim b() As Byte
	Dim eol As String = Chr(13) & Chr(10)
	Dim empty As Boolean = True
	If NameValues <> Null And NameValues.IsInitialized Then
		For Each key As String In NameValues.Keys
			Dim value As String = NameValues.Get(key)
			empty = MultipartStartSection (stream, empty)
			Dim s As String = _
$"--${MultipartBoundary}
Content-Disposition: form-data; name="${key}"

${value}"$
			b = s.Replace(CRLF, eol).GetBytes("UTF8")
			stream.WriteBytes(b, 0, b.Length)
		Next
	End If
	If Files <> Null And Files.IsInitialized Then
		For Each fd As MultipartFileData In Files
			empty = MultipartStartSection (stream, empty)
			Dim s As String = _
$"--${MultipartBoundary}
Content-Disposition: form-data; name="${fd.KeyName}"; filename="${fd.FileName}"
Content-Type: ${fd.ContentType}

"$
			b = s.Replace(CRLF, eol).GetBytes("UTF8")
			stream.WriteBytes(b, 0, b.Length)
			Dim in As InputStream = File.OpenInput(fd.Dir, fd.FileName)
			File.Copy2(in, stream)
		Next
	End If
	empty = MultipartStartSection (stream, empty)
	s = _
$"--${MultipartBoundary}--
"$
	b = s.Replace(CRLF, eol).GetBytes("UTF8")
	stream.WriteBytes(b, 0, b.Length)
	Return stream.ToBytesArray
End Sub

Private Sub MultipartStartSection (stream As OutputStream, empty As Boolean) As Boolean
	If empty = False Then
		stream.WriteBytes(Array As Byte(13, 10), 0, 2)
	Else
		empty = False
	End If
	Return empty
End Sub

Public Sub CheckPostMediaSize (pm As PostMedia) As Boolean
	Dim FileSize As Long = File.Size(pm.FileName, "")
	If pm.IsImage And FileSize > 8 * 1024 * 1024 Then
		B4XPages.MainPage.ShowMessage($"Maximum image size: 8 MB. Current image size: $1.0{FileSize / 1024 / 1024} MB."$)
		Return False
	Else If FileSize > 40 * 1024 * 1024 Then
		B4XPages.MainPage.ShowMessage($"Maximum video size: 40 MB. Current video size: $1.0{FileSize / 1024 / 1024} MB."$)
		Return False
	End If
	Return True
End Sub

Public Sub CreateMenuItem(IconCodePoint As Int, Text As String) As String
	Return Chr(IconCodePoint) & "  " & Text
End Sub

Public Sub TicksToTimeString (ticks As Long, ShowDaysAndMonths As Boolean) As String
	Dim DeltaSeconds As Int = (DateTime.Now - ticks) / DateTime.TicksPerSecond
	Dim s As String
	Select True
		Case DeltaSeconds <= 30
			s = "now"
		Case DeltaSeconds < 3600
			s = $"$1.0{DeltaSeconds / 60}m"$
		Case DeltaSeconds < 3600 * 24
			s = $"$1.0{DeltaSeconds / 3600}h"$
		Case DeltaSeconds < 3600 * 24 * 30
			If ShowDaysAndMonths Then s = $"$1.0{DeltaSeconds / 3600 / 24}d"$
		Case Else
			If ShowDaysAndMonths Then s = $"$1.0{DeltaSeconds / 3600 / 24 / 30}mo"$
	End Select
	Return s
End Sub


