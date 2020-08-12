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
End Sub

Public Sub Initialize
	TextEngine.Initialize (xui.CreatePanel(""))
	TextEngine.WordBoundaries = "&*+-/<>=\ ,:{}" & TAB & CRLF & Chr(13)
	TextEngine.TagParser.UrlColor = UrlColor
	HtmlParser.Initialize
	HtmlConverter.Initialize(TextEngine, HtmlParser)
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

