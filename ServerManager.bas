B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private BaseServers As B4XOrderedMap
	Private TempServer As PLMServer
	Private lstTemplate As B4XSearchTemplate
	Private xui As XUI
End Sub

Public Sub Initialize
	lstTemplate.Initialize
	BaseServers.Initialize
	Dim TextColor As Int = Constants.ColorDefaultText
	lstTemplate.CustomListView1.DefaultTextBackgroundColor = xui.Color_White
	lstTemplate.CustomListView1.DefaultTextColor = TextColor
	lstTemplate.CustomListView1.AsView.Color = xui.Color_White
	lstTemplate.CustomListView1.sv.ScrollViewInnerPanel.Color = 0xFFC3C3C3
	lstTemplate.SearchField.TextField.TextColor = TextColor
	#if B4A
	Dim et As EditText = lstTemplate.SearchField.TextField
	et.InputType = 208 'TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS
	#Else If B4i
	Dim tf As TextField = lstTemplate.SearchField.TextField
	tf.KeyboardType = tf.TYPE_URL
	tf.Autocapitalize = tf.AUTOCAPITALIZE_NONE
	#End If
	lstTemplate.SearchField.HintFont = xui.CreateDefaultFont(14)
	lstTemplate.SearchField.HintText = "Server domain"
	lstTemplate.SearchField.Update
	lstTemplate.AllowUnlistedText = True
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
	For Each ser As PLMServer In Array(CreatePLMServer("https://mas.to", "mas.to"), CreatePLMServer("https://pleroma.com", "pleroma.com"))
		BaseServers.Put(ser.Name, ser)
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

Public Sub RequestServerName (Dialog As B4XDialog) As ResumableSub
	
	Dialog.Title = "Select or enter server domain"
	
	Dim keys As List
	keys.Initialize
	For Each server As PLMServer In BaseServers.Values
		keys.Add(server.Name)
	Next
	If TempServer.IsInitialized Then
		keys.Add(TempServer.Name)
	End If
	lstTemplate.SetItems(keys)
	lstTemplate.Resize(300dip, 150dip)
	
	Wait For (Dialog.ShowTemplate(lstTemplate, "", "", "Cancel")) Complete (Result As Int)
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




