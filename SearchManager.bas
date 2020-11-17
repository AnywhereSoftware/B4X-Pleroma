B4J=true
Group=Misc
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public mBase As B4XView
	Private xui As XUI
	Private B4XFloatTextField1 As B4XFloatTextField
	Private mTheme As ThemeManager
End Sub

Public Sub Initialize (width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, width, 50dip)
	mBase.LoadLayout("Search")
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	B4XFloatTextField1.HintFont = xui.CreateFontAwesome(14)
	B4XFloatTextField1.HintText = Constants.SearchIconChar
	B4XFloatTextField1.Update
	#if B4A
	Dim JO As JavaObject = B4XFloatTextField1.TextField
	JO.RunMethod("setImeOptions",Array(3)) 'search button
	#Else If b4i
	Dim tf As TextField = B4XFloatTextField1.TextField
	tf.ReturnKey = tf.RETURN_SEARCH
	#End If 
	Theme_Changed
End Sub

Private Sub Theme_Changed
	mBase.Color = mTheme.Background
	mTheme.SetFloatTextFieldColor(B4XFloatTextField1)
End Sub

Private Sub B4XFloatTextField1_EnterPressed
	Dim t As String = B4XFloatTextField1.Text.Trim
	If t.Length > 0 Then
		Search(t)
	End If
	B4XPages.MainPage.HideSearch
End Sub

Public Sub Focus
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	#if B4A
	Dim et As EditText = B4XFloatTextField1.TextField
	et.SelectAll
	#Else If B4i
	Dim tf As TextField = B4XFloatTextField1.TextField
	tf.SelectAll
	#end if
End Sub

Private Sub Search (s As String)
	Dim mp As B4XMainPage = B4XPages.MainPage
	Dim link As PLMLink = mp.TextUtils1.CreatePLMLink(Constants.URL_SEARCH, Constants.LINKTYPE_SEARCH, s)
	link.Extra = CreateMap("query": s)
	mp.Statuses.Refresh2(mp.User, link, True, False)
	
End Sub