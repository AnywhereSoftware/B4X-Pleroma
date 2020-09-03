B4J=true
Group=ListItems
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public mBase As B4XView
	Private xui As XUI
End Sub

Public Sub Initialize (width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, width, 30dip)
	mBase.SetColorAndBorder(Constants.NoMoreItemsBackground, 0, 0, 1dip)
	Dim lbl As Label
	lbl.Initialize("")
	Dim xlbl As B4XView = lbl
	mBase.AddView(xlbl, 0, 0, mBase.Width, mBase.Height)
	xlbl.SetTextAlignment("CENTER", "CENTER")
	xlbl.Text = "No more items"
	xlbl.TextColor = xui.Color_White
	xlbl.Font = xui.CreateDefaultFont(16)
End Sub

Public Sub SetContent(Content As Object)
	
End Sub

Public Sub SetVisibility (visible As Boolean)
	
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub