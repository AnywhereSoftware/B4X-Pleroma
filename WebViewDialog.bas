B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private xui As XUI
	Public mParent As B4XView
	Public mDialog As B4XDialog
	Private WebView1 As WebView
	Private mURL As String	
End Sub

Public Sub Initialize (Parent As B4XView)
	mParent = Parent
	mParent.LoadLayout("WebViewDialog")
	#if B4A
	Dim r As Reflector
	r.Target = WebView1
	r.Target = r.RunMethod("getSettings")
	r.RunMethod2("setBuiltInZoomControls", True, "java.lang.boolean")
	r.RunMethod2("setDisplayZoomControls", False, "java.lang.boolean")
	#End If
End Sub

#if B4J
Sub lblExit_MouseClicked (EventData As MouseEvent)
	lblExit_Click
End Sub

Sub lblExternal_MouseClicked (EventData As MouseEvent)
	lblExternal_Click
End Sub
#End If

Public Sub Show(Dialog As B4XDialog, Link As PLMLink)
	mDialog = Dialog
	mDialog.Title = Link.Title
	mURL = Link.URL
	WebView1.LoadUrl(Link.URL)
End Sub

Sub lblExit_Click
	mDialog.Close(xui.DialogResponse_Cancel)
End Sub

Sub lblExternal_Click
	B4XPages.MainPage.ShowExternalLink(mURL)
	lblExit_Click
End Sub

Public Sub Close
	WebView1.LoadHtml("")
End Sub

Private Sub WebView1_LocationChanged (Location As String)
	Log(Location)
End Sub