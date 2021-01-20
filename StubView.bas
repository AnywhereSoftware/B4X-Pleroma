B4J=true
Group=ListItems
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public mBase As B4XView
	Private xui As XUI
	Private mTheme As ThemeManager
	Private xlbl As B4XView
End Sub

Public Sub Initialize (width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, width, 300dip)
	mTheme = B4XPages.MainPage.Theme
	Dim lbl As Label
	lbl.Initialize("")
	xlbl = lbl
	mBase.AddView(xlbl, 0, 0, mBase.Width, 40dip)
	xlbl.SetTextAlignment("CENTER", "CENTER")
	xlbl.TextColor = mTheme.NoMoreItemsBackground
	xlbl.Font = xui.CreateDefaultFont(12)
End Sub

Public Sub SetContent(Content As PLMStub, ListItem As PLMCLVItem)
	xlbl.Text = Content.Text
	mBase.Height = Content.Height
	xlbl.Visible = Content.Text <> ""
	mBase.Visible = mBase.Height > 0
	xlbl.Height = Min(xlbl.Height, mBase.Height)
End Sub

Public Sub SetVisibility (visible As Boolean)
	
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub