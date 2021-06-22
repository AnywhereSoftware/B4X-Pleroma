B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private BaseServers As B4XOrderedMap '<string, PLMServer>
	Private TempServer As PLMServer
	Private lstTemplate As B4XSearchTemplate
	Private xui As XUI
	Type PLMInstanceFeatures (URI As String, Title As String, Version As String, IsPleroma As Boolean, Features As B4XSet, StatusMaxLength As Int)
	Private InstanceFeatures As Map '<string, PLMInstanceFeatures>
	Private tu As TextUtils
	Private mTheme As ThemeManager
End Sub

Public Sub Initialize
	tu = B4XPages.MainPage.TextUtils1
	
	lstTemplate.Initialize
	BaseServers.Initialize
	InstanceFeatures.Initialize
	
	#if B4A
	Dim et As EditText = lstTemplate.SearchField.TextField
	et.InputType = 208 'TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS
	#Else If B4i
	Dim tf As TextField = lstTemplate.SearchField.TextField
	tf.KeyboardType = tf.TYPE_URL
	tf.Autocapitalize = tf.AUTOCAPITALIZE_NONE
	#End If
	lstTemplate.SearchField.HintText = ""
	lstTemplate.SearchField.Update
	lstTemplate.AllowUnlistedText = True
End Sub

Public Sub AfterThemeCreated
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	Theme_Changed
End Sub

Private Sub Theme_Changed
	Dim TextColor As Int = mTheme.DefaultText
	lstTemplate.CustomListView1.DefaultTextBackgroundColor = mTheme.Background
	lstTemplate.CustomListView1.DefaultTextColor = TextColor
	lstTemplate.CustomListView1.AsView.Color = mTheme.Background
	lstTemplate.CustomListView1.sv.ScrollViewInnerPanel.Color = mTheme.AttachmentPanelBackground
	mTheme.SetFloatTextFieldColor(lstTemplate.SearchField)
End Sub

Public Sub LoadFromStore (store As KeyValueStore)
	If store.ContainsKey("servers") Then
		Dim s As List = store.Get("servers")
		For Each Server As PLMServer In s
			BaseServers.Put(Server.Name, Server)
		Next
	Else
		CreateServersList
		B4XPages.MainPage.PersistUserAndServers
	End If
End Sub

Public Sub SaveToStore (store As KeyValueStore)
	store.Put("servers", BaseServers.Values)
End Sub

Private Sub CreateServersList
	For Each Ser As PLMServer In Array(CreatePLMServer("https://mas.to", "mas.to"))
		BaseServers.Put(Ser.Name, Ser)
	Next
End Sub

Private Sub CreatePLMServer (URL As String, Name As String) As PLMServer
	Dim t1 As PLMServer
	t1.Initialize
	t1.URL = URL
	t1.Name = Name
	Return t1
End Sub

Public Sub GetServer (user As PLMUser) As PLMServer
	Return BaseServers.GetDefault(user.ServerName, TempServer)
End Sub

Public Sub GetServerFeatures (server As PLMServer) As PLMInstanceFeatures
	Return InstanceFeatures.Get(server.Name)
End Sub

Public Sub RequestServerName (Dialog As B4XDialog) As ResumableSub
	
	Dialog.Title = "Select or enter server domain"
	
	Dim keys As List
	keys.Initialize
	For Each Server As PLMServer In BaseServers.Values
		keys.Add(Server.Name)
	Next
	If TempServer.IsInitialized Then
		keys.Add(TempServer.Name)
	End If
	lstTemplate.SetItems(keys)
	lstTemplate.Resize(Constants.DialogWidth, Constants.DialogHeight)
	Dim rs As Object = Dialog.ShowTemplate(lstTemplate, "", "", "Cancel")
	B4XPages.MainPage.ViewsCache1.AfterShowDialog(Dialog)
	Wait For (rs) Complete (Result As Int)
	B4XPages.MainPage.UpdateHamburgerIcon
	If Result = xui.DialogResponse_Positive Then
		Dim name As String = lstTemplate.SelectedItem.Trim
		If name <> "" Then
			If BaseServers.ContainsKey(name) = False Then
				Dim url As String = name
				If url.EndsWith("/") Then url = url.SubString2(0, url.Length - 1)
				If url.StartsWith("http") = False Then url = "https://" & url
				TempServer = CreatePLMServer(url, name)
				Return TempServer
			Else
				Return BaseServers.Get(name)
			End If
		End If
	End If
	Dim Res As PLMServer
	Return Res
End Sub

Public Sub AfterSignIn (SignedInServerName As String)
	If TempServer.IsInitialized And TempServer.Name = SignedInServerName Then
		BaseServers.Put(TempServer.Name, TempServer)
	End If
	ResetTempServer
End Sub

Private Sub ResetTempServer
	Dim TempServer As PLMServer 'will be uninitialized
End Sub

Public Sub VerifyInstanceFeatures (server As PLMServer) As ResumableSub
	If InstanceFeatures.ContainsKey(server.Name) Then Return True
	Dim j As HttpJob = tu.CreateHttpJob(Me, Null, False)
	j.Download(server.URL & "/api/v1/instance")
	Wait For (j) JobDone (j As HttpJob)
	Dim res As Boolean
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			res = True
			Dim features As PLMInstanceFeatures
			features.Initialize
			features.Title = m.GetDefault("title", "")
			features.URI = m.GetDefault("uri", "")
			features.Version = m.GetDefault("version", "")
			features.StatusMaxLength = m.GetDefault("max_toot_chars", 500)
			features.Features.Initialize
			If m.ContainsKey("pleroma") Then
				features.IsPleroma = True
				Dim plm As Map = m.Get("pleroma")
				Dim metadata As Map = plm.Get("metadata")
				If metadata.ContainsKey("features") Then
					Dim feat As List = metadata.Get("features")
					For Each f As String In feat
						features.Features.Add(f)
					Next
				End If
			End If
			InstanceFeatures.Put(server.Name, features)
		End If
	End If
	j.Release
	B4XPages.MainPage.HideProgress
	If res = False Then
		B4XPages.MainPage.ShowMessage("Failed to connect: " & j.ErrorMessage)
	End If
	Return res	
End Sub



