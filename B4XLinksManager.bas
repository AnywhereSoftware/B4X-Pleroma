B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public LINK_PUBLIC, LINK_LOCAL As PLMLink
	Public LINK_HOME As PLMLink
	Private DefaultLinks As List
	Private DefaultLinksTitles As B4XSet
End Sub

Public Sub Initialize
	CreateInitialLinks
	DefaultLinks = Array(LINK_HOME, LINK_LOCAL, LINK_PUBLIC)
	DefaultLinksTitles.Initialize
	For Each link As PLMLink In DefaultLinks
		DefaultLinksTitles.Add(link.Title)
	Next
End Sub

Private Sub CreateInitialLinks
	Dim tu As TextUtils = B4XPages.MainPage.TextUtils1
	LINK_PUBLIC = tu.CreatePLMLink("/api/v1/timelines/public", Constants.LINKTYPE_TIMELINE, "Public")
	LINK_LOCAL = tu.CreatePLMLink("/api/v1/timelines/public", Constants.LINKTYPE_TIMELINE, "Local")
	LINK_LOCAL.Extra = CreateMap("params": CreateMap("local": "true"))
	LINK_HOME = tu.CreatePLMLink("/api/v1/timelines/home", Constants.LINKTYPE_TIMELINE, "Home")
End Sub

Public Sub IsRecentLink (link As PLMLink) As Boolean
	If link.LinkType = Constants.LINKTYPE_USER Then
		If "@" & B4XPages.MainPage.User.DisplayName = link.Title Then
			Return False
		End If
	End If
	Return DefaultLinksTitles.Contains(link.Title) = False 
End Sub

Public Sub GetDefaultLinksWithoutHome As List
	Dim res As List
	res.Initialize
	For i = 1 To DefaultLinks.Size - 1
		res.Add(DefaultLinks.Get(i))
	Next
	Return res
End Sub

