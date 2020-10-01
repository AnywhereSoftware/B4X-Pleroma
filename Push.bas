B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private tu As TextUtils
	Private Endpoint As String = "https://b4x.com:51051/push/test"
End Sub

Public Sub Initialize
	tu = B4XPages.MainPage.TextUtils1	
End Sub

Public Sub Subscribe
'	CurrentSubscriptions
	Dim pb As String = "BHDfTUyMS9YZ2HHSivY98uXUNcSfsTaDMFUlNBSFYxoZQSIcihVNOsOKIyaPPsbWNeTlCuelJnPvAZDIPPLTJoo="
	Dim auth As String = "MTIzNDU2Nzg5MDEyMzQ1"
	Dim j As HttpJob = tu.CreateHttpJob(Me, B4XPages.MainPage.Root)
	Dim m As Map = CreateMap("subscription": CreateMap("endpoint": Endpoint, "keys": CreateMap("p256dh": pb, "auth": auth)))
	m.Put("data", CreateMap("alerts": CreateMap("follow": True, "favourite": True)))
	Dim gen As JSONGenerator
	gen.Initialize(m)
	Log(gen.ToPrettyString(4))
	j.PostString(B4XPages.MainPage.GetServer.URL & "/api/v1/push/subscription", gen.ToString)
	B4XPages.MainPage.auth.AddAuthorization(j)
	j.GetRequest.SetContentType("application/json")
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Log(j.GetString)
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

'Private Sub CurrentSubscriptions
'	Dim j As HttpJob = tu.CreateHttpJob(Me, B4XPages.MainPage.Root)
'	j.Download(B4XPages.MainPage.GetServer.URL & "/api/v1/push/subscription")
'	B4XPages.MainPage.auth.AddAuthorization(j)
'	Wait For (j) JobDone (j As HttpJob)
'	If j.Success Then
'		Log(j.GetString)
'	End If
'	j.Release
'	B4XPages.MainPage.HideProgress
'End Sub