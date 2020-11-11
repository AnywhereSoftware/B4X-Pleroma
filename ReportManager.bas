B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private PrefDialog As PreferencesDialog
	Private xui As XUI
	Private tu As TextUtils
End Sub

Public Sub Initialize
	tu = B4XPages.MainPage.TextUtils1
End Sub

Public Sub Show(Account As PLMAccount, StatusId As String)
	If B4XPages.MainPage.MakeSureThatUserSignedIn = False Then
		Return
	End If
	If PrefDialog.IsInitialized = False Then
		PrefDialog = B4XPages.MainPage.ViewsCache1.CreatePreferencesDialog("Report.json")
	End If
	Dim m As Map = CreateMap("account": Account.DisplayName, "status": StatusId)
	Dim rs As Object = PrefDialog.ShowDialog(m, "Send", "Cancel")
	For Each i As Int In Array(0, 1, 2)
		Dim fl As B4XFloatTextField = PrefDialog.CustomListView1.GetPanel(i).GetView(0).Tag
		fl.TextField.Enabled = i = 2
		fl.SmallLabelTextSize = 12
		fl.LargeLabelTextSize = 16
		fl.Update
	Next
	PrefDialog.CustomListView1.ScrollToItem(0)
	B4XPages.MainPage.ViewsCache1.SetClipToOutline(PrefDialog.Dialog.Base) 'apply the round corners to the content
	Wait For (rs) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		Dim j As HttpJob = tu.CreateHttpJob(Me, B4XPages.MainPage.Root, True)
		If j = Null Then Return
		Dim jg As JSONGenerator
		Dim report As Map = CreateMap("account_id": Account.Id, "comment": m.Get("comment"))
		If StatusId <> "" Then report.Put("status_ids", Array(StatusId))
		jg.Initialize(report)
		j.PostString(B4XPages.MainPage.GetServer.URL & $"/api/v1/reports"$, jg.ToString)
		j.GetRequest.SetContentType("application/json")
		B4XPages.MainPage.auth.AddAuthorization(j)
		Wait For (j) JobDone(j As HttpJob)
		If j.Success Then
			B4XPages.MainPage.ShowMessage("Report sent.")
		Else
			B4XPages.MainPage.ShowMessage("Error sending report: " & j.ErrorMessage)
		End If
		j.Release
		B4XPages.MainPage.HideProgress
	End If
End Sub