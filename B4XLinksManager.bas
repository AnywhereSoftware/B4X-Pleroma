B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public LINK_PUBLIC, LINK_LOCAL, LINK_NOTIFICATIONS As PLMLink
	Public LINK_HOME As PLMLink
	Private DefaultLinks As List
	Private DefaultLinksTitles As B4XSet
End Sub

Public Sub Initialize
	CreateInitialLinks
	DefaultLinks = Array(LINK_HOME, LINK_NOTIFICATIONS, LINK_LOCAL, LINK_PUBLIC)
	DefaultLinksTitles.Initialize
	For Each LINK As PLMLink In DefaultLinks
		DefaultLinksTitles.Add(LINK.Title)
	Next
End Sub

Private Sub CreateInitialLinks
	Dim tu As TextUtils = B4XPages.MainPage.TextUtils1
	LINK_PUBLIC = tu.CreatePLMLink(Constants.URL_PUBLIC, Constants.LINKTYPE_TIMELINE, "Public")
	LINK_LOCAL = tu.CreatePLMLink(Constants.URL_PUBLIC, Constants.LINKTYPE_TIMELINE, "Local")
	LINK_LOCAL.Extra = CreateMap("params": CreateMap("local": "true"))
	LINK_HOME = tu.CreatePLMLink(Constants.URL_HOME, Constants.LINKTYPE_TIMELINE, "Home")
	LINK_NOTIFICATIONS = tu.CreatePLMLink(Constants.URL_NOTIFICATIONS, Constants.LINKTYPE_NOTIFICATIONS, "Notifications")
End Sub

Public Sub IsRecentLink (LINK As PLMLink) As Boolean
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
	For i = 2 To DefaultLinks.Size - 1
		res.Add(DefaultLinks.Get(i))
	Next
	Return res
End Sub

