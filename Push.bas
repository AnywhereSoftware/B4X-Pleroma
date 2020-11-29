B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private tu As TextUtils
	Private su As StringUtils
	Type PLMNotificationSettings (Auth() As Byte, KeysValues As Map)
	Private PushSettingsStoreVersion As Float
End Sub

Public Sub Initialize
	tu = B4XPages.MainPage.TextUtils1	
End Sub

Public Sub Subscribe
	Dim settings As PLMNotificationSettings = GetSettings
	#if B4J
	Return
	#Else If B4A
	CallSubDelayed2(FirebaseMessaging, "SubscribeToTopic", UrlSafeAuth(settings.Auth))
	#else if B4i
	B4iSubscribe(UrlSafeAuth(settings.Auth))
	#End If
	Dim j As HttpJob = tu.CreateHttpJob(Me, B4XPages.MainPage.Root, True) 'ignore
	Dim m As Map = CreateMap("subscription": CreateMap("endpoint": CreateEndpoint(settings.Auth) _
		,"keys": CreateMap("p256dh": Constants.PushPublicKey, "auth": su.EncodeBase64(settings.Auth))))
	m.Put("data", CreateMap("alerts": settings.KeysValues))
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

Private Sub UrlSafeAuth (auth() As Byte) As String
	Return su.EncodeUrl(su.EncodeBase64(auth), "UTF8")
End Sub

Public Sub GetSettings As PLMNotificationSettings
	Dim settings As PLMNotificationSettings
	If PushSettingsStoreVersion = 0 Then PushSettingsStoreVersion = B4XPages.MainPage.StoreVersion
	If PushSettingsStoreVersion < 1.20 Then
		B4XPages.MainPage.store.Remove(Constants.NotificationSettingsStoreKey)
	End If
	If B4XPages.MainPage.store.ContainsKey(Constants.NotificationSettingsStoreKey) = False Then
		settings.Initialize
		settings.KeysValues = CreateMap("follow": True, "favourite": True, "mention": True, "reblog": True)
		B4XPages.MainPage.store.Put(Constants.NotificationSettingsStoreKey, settings)
		Return settings
	Else
		settings = B4XPages.MainPage.store.Get(Constants.NotificationSettingsStoreKey)
	End If
	If settings.Auth.Length = 0 Then
		Dim auth(16) As Byte
		For i = 0 To auth.Length - 1
			auth(i) = Rnd(-128, 127)
		Next
		settings.Auth = auth
		PersistSettings(settings)
	End If
	Return settings
End Sub

Public Sub PersistSettings (settings As PLMNotificationSettings)
	B4XPages.MainPage.store.Put(Constants.NotificationSettingsStoreKey, settings)
	PushSettingsStoreVersion = Constants.Version
End Sub

Private Sub CreateEndpoint (auth() As Byte) As String
	#if B4A
	Dim suffix As String = "b4a"
	#else
	Dim suffix As String = "b4i"
	#end if
	Return Constants.EndPointBase & UrlSafeAuth(auth) & "/" & suffix
End Sub

#if B4i
Private Sub B4iSubscribe (auth As String)
	Main.App.RegisterForRemoteNotifications
	Main.App.RegisterUserNotifications(True, True, True)
	Main.fm.SubscribeToTopic(auth)
	
End Sub
#End If

Public Sub Unsubscribe
	If B4XPages.MainPage.User.SignedIn = False Then Return
	Dim settings As PLMNotificationSettings = GetSettings
	settings.Auth = Array As Byte()
	PersistSettings(settings)
	Dim j As HttpJob = tu.CreateHttpJob(Me, B4XPages.MainPage.Root, True) 
	If j = Null Then Return
	j.Delete(B4XPages.MainPage.GetServer.URL & "/api/v1/push/subscription")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Log(j.GetString)
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub