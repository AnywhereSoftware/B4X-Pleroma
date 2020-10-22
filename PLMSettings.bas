﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private settings As Map
	Private PrefDialog As PreferencesDialog
	Private xui As XUI
	Public NSFW_Overlay As Boolean
End Sub

Public Sub Initialize
	settings.Initialize
End Sub

Public Sub LoadFromStore (store As KeyValueStore, StoreVersion As Float)
	If store.ContainsKey("settings") Then
		settings = store.Get("settings")
	Else
		settings.Put("nsfw_overlay", True)
	End If
	AfterSettingsChanged
End Sub

Public Sub SaveToStore
	B4XPages.MainPage.store.Put("settings", settings)
End Sub

Private Sub AfterSettingsChanged
	NSFW_Overlay = settings.Get("nsfw_overlay")
End Sub

Public Sub ShowSettings
	If PrefDialog.IsInitialized = False Then
		PrefDialog = B4XPages.MainPage.ViewsCache1.CreatePreferencesDialog("Settings.json")
	End If
	Dim views As ViewsCache = B4XPages.MainPage.ViewsCache1
	PrefDialog.CustomListView1.Clear 'as we update the titles, we need to clear the existing items.
	Dim pi As B4XPrefItem = PrefDialog.PrefItems.Get(0)
	pi.Title = "B4X Pleroma v" & NumberFormat2(Constants.Version, 1, 2, 2, False)
	Dim server As PLMServer = B4XPages.MainPage.GetServer
	PrefDialog.GetPrefItem("server").Title =  views.CreateRichTextWithSize($"Server (${server.Name})"$, 14)
	
	PrefDialog.SetExplanation("server", CreateServerExplanation)
	Dim m As Map = CreateMap()
	For Each key As String In settings.Keys
		m.Put(key, settings.Get(key))
	Next
	Dim PushSettings As PLMNotificationSettings = B4XPages.MainPage.push1.GetSettings
	Dim PushKeys As List = Array("follow", "mention", "reblog", "favourite")
	For Each k As String In PushKeys
		m.Put("push_" & k, PushSettings.KeysValues.Get(k))
	Next
	Dim rs As Object = PrefDialog.ShowDialog(m, "Ok", "Cancel")
	views.SetClipToOutline(PrefDialog.Dialog.Base) 'apply the round corners to the content
	Wait For (rs) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		Dim NeedToUpdatePush As Boolean
		For Each k As String In PushKeys
			Dim key As String = "push_" & k
			Dim NewValue As Boolean = m.Get(key)
			m.Remove(k)
			If NewValue <> PushSettings.KeysValues.Get(k) Then
				PushSettings.KeysValues.Put(k, NewValue)
				NeedToUpdatePush = True
			End If
		Next
		If NeedToUpdatePush Then
			B4XPages.MainPage.push1.PersistSettings (PushSettings)
			B4XPages.MainPage.push1.Subscribe
		End If
		m.Remove("server")
		settings = m
		SaveToStore
		AfterSettingsChanged
	End If
End Sub

Private Sub CreateServerExplanation As String
	Dim server As PLMServer = B4XPages.MainPage.GetServer
	Dim features As PLMInstanceFeatures = B4XPages.MainPage.ServerManager1.GetServerFeatures(server)
	Dim s As String = $"Title: ${features.Title}
URI: ${features.URI}
Version: ${features.Version}
Is Pleroma: ${features.IsPleroma}
"$
	For Each f As String In features.Features.AsList
		s = s & f & CRLF
	Next
	Return s
End Sub


'returns True if the dialog was closed
Public Sub BackKeyPressed As Boolean
	If PrefDialog.IsInitialized And PrefDialog.Dialog.Visible Then
		PrefDialog.Dialog.Close(xui.DialogResponse_Cancel)
		Return True
	End If
	Return False
End Sub