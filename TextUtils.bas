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
End Sub

Public Sub Initialize
	TextEngine.Initialize (xui.CreatePanel(""))
	TextEngine.WordBoundaries = "&*+-/<>=\ ,:{}" & TAB & CRLF & Chr(13)
	TextEngine.TagParser.UrlColor = UrlColor
	HtmlParser.Initialize
	HtmlConverter.Initialize(TextEngine, HtmlParser)
	NBSP = Chr(0x202F)
End Sub

Public Sub ManageLink (Status As PLMStatus, Account As PLMAccount, URL As String, Text As String) As PLMLink
	If Status <> Null Then
		If URL = "~time" Then
			Dim u As String = B4XPages.MainPage.URL_THREAD.Replace(":id", Status.Id)
			Dim link As PLMLink = CreatePLMLink2(u, B4XPages.MainPage.LINKTYPE_THREAD, "Conversation", "")
			link.Extra = CreateMap("current": Status)
			Return link
		Else If URL.StartsWith("@@") Then
			Dim id As String = URL.SubString(2)
			Return CreateUserLink(id, Text)
		Else If Text.Length > 1 And Text.StartsWith("@") Then
			Dim name As String = Text.SubString(1)
			For Each m As Map In Status.Mentions
				If name = m.Get("username") Then
					Return CreateUserLink(m.Get("id"), name)
				End If
				If name = Status.Account.UserName Then
					Return ManageLink(Status, Account, "@", Text)
				End If
			Next
		End If
	End If
	If URL = "@" Then
		Dim u As String = B4XPages.MainPage.URL_USER.Replace(":id", Account.Id)
		Return CreatePLMLink2(u & "/statuses", B4XPages.MainPage.LINKTYPE_USER, "@" & Account.UserName, u)
	Else If Regex.IsMatch("#\w+", Text) Then
		Return CreatePLMLink(B4XPages.MainPage.URL_TAG & Text.SubString(1), B4XPages.MainPage.LINKTYPE_TAG, Text)
	End If
	Return CreatePLMLink(URL, B4XPages.MainPage.LINKTYPE_OTHER, URL)
End Sub


Public Sub CreateUserLink (id As String, name As String) As PLMLink
	Dim u As String = B4XPages.MainPage.URL_USER.Replace(":id", id)
	Return CreatePLMLink2(u & "/statuses", B4XPages.MainPage.LINKTYPE_USER, "@" & name, u)
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
				Data.ViewsPanel.AddView(iv, 0, 0, Emoji.Size, Emoji.Size)
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
		status.ExtraContent = CreateMap("reblog": CreateAccount(StatusMap.Get("account")))
		StatusMap = reblog
	End If
	If StatusMap.Get("card") <> Null Then
		If status.ExtraContent.IsInitialized = False Then status.ExtraContent.Initialize
		status.ExtraContent.Put("card", StatusMap.Get("card"))
	End If
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
	status.FavouritesCount = StatusMap.GetDefault("favourites_count", 0)
	status.Favourited = StatusMap.Get("favourited")
	status.Reblogged = StatusMap.Get("reblogged")
	status.RepliesCount = StatusMap.GetDefault("replies_count", 0)
	status.Mentions = StatusMap.Get("mentions")
	status.Attachments.Initialize
	Dim attachments As List = StatusMap.Get("media_attachments")
	For Each attachment As Map In attachments
		status.Attachments.Add(CreateAttachment(attachment))
	Next
	If StatusMap.ContainsKey("pleroma") Then
		Dim plm As Map = StatusMap.Get("pleroma")
		status.EmojiReactions = plm.Get("emoji_reactions")
		status.InReplyToAccountAcct = plm.GetDefault("in_reply_to_account_acct", "")
	End If
	status.InReplyToAccountId = StatusMap.Get("in_reply_to_account_id")
	status.InReplyToId = StatusMap.Get("in_reply_to_id")
	Return status
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

Public Sub CreateAccount (Account As Map) As PLMAccount
	Dim ac As PLMAccount
	If Account.IsInitialized = False Then Return ac
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

Public Sub AddRelationship (account As PLMAccount) As ResumableSub
	If B4XPages.MainPage.User.SignedIn = False Then Return False
	Dim j As HttpJob
	j.Initialize("", Me)
	j.Download(B4XPages.MainPage.GetServer.URL & "/api/v1/accounts/relationships?id[]=" & account.Id)
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Dim r As List = JsonParseList(j.GetString)
		If r.IsInitialized And r.Size > 0 Then
			Dim m As Map = r.Get(0)
			GetRelationshipFromRelationshipObject(account, m)
		End If
	End If
	j.Release
	Return False
End Sub

Public Sub GetRelationshipFromRelationshipObject (Account As PLMAccount, m As Map)
	Account.RelationshipAdded = True
	Account.Following = m.Get("following")
	Account.FollowRequested = m.Get("requested")
End Sub

Public Sub FollowOrUnfollow (Account As PLMAccount) As ResumableSub
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then Return False
	B4XPages.MainPage.ShowProgress
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/accounts/${Account.id}/"$
	If Account.Following Or Account.FollowRequested Then
		link = link & "unfollow"
	Else
		link = link & "follow"
	End If
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

