B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public LINK_PUBLIC, LINK_LOCAL, LINK_NOTIFICATIONS As PLMLink
	Public LINK_HOME, LINK_CHATS_LIST As PLMLink
	Private DefaultLinks As List
	Private DefaultLinksTitles As B4XSet
	Public LinksWithStreamerEvents As B4XSet
End Sub

Public Sub Initialize
	CreateInitialLinks
	DefaultLinks = Array(LINK_HOME, LINK_NOTIFICATIONS, LINK_CHATS_LIST, LINK_LOCAL, LINK_PUBLIC)
	DefaultLinksTitles.Initialize
	For Each LINK As PLMLink In DefaultLinks
		DefaultLinksTitles.Add(LINK.Title)
	Next
	LinksWithStreamerEvents.Initialize
End Sub

Public Sub AfterLinksWithStreamerChanged
	LinksWithStreamerEvents.Remove(LINK_CHATS_LIST.URL)
	For Each link As String In LinksWithStreamerEvents.AsList
		If link.StartsWith("/api/v1/pleroma/chats") Then
			LinksWithStreamerEvents.Add(LINK_CHATS_LIST.URL)
			Exit
		End If
	Next
End Sub

Private Sub CreateInitialLinks
	Dim tu As TextUtils = B4XPages.MainPage.TextUtils1
	LINK_PUBLIC = tu.CreatePLMLink(Constants.URL_PUBLIC, Constants.LINKTYPE_TIMELINE, "Public")
	LINK_LOCAL = tu.CreatePLMLink(Constants.URL_PUBLIC, Constants.LINKTYPE_TIMELINE, "Local")
	LINK_LOCAL.Extra = CreateMap("params": CreateMap("local": "true"))
	LINK_HOME = tu.CreatePLMLink(Constants.URL_HOME, Constants.LINKTYPE_TIMELINE, "Home")
	LINK_CHATS_LIST = tu.CreatePLMLink(Constants.URL_CHATS_LIST, Constants.LINKTYPE_CHATS_LIST, "Chats")
	LINK_NOTIFICATIONS = tu.CreatePLMLink(Constants.URL_NOTIFICATIONS, Constants.LINKTYPE_NOTIFICATIONS, "Notifications")
End Sub

Public Sub IsRecentLink (LINK As PLMLink) As Boolean
	If LINK.IsInitialized = False Then Return False
	If LINK.LinkType = Constants.LINKTYPE_USER And B4XPages.MainPage.User.SignedIn Then
		If LINK.URL.Contains(B4XPages.MainPage.User.Id) Then
			Return False
		End If
	End If
	Return DefaultLinksTitles.Contains(LINK.Title) = False
End Sub

Public Sub GetDefaultLinksWithoutHome As List
	Dim res As List
	res.Initialize
	For i = 3 To DefaultLinks.Size - 1
		res.Add(DefaultLinks.Get(i))
	Next
	Return res
End Sub

