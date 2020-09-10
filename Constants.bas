B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private xui As XUI
	Public Const ColorAlreadyTookAction As Int = xui.Color_Blue
	Public Const ColorDefaultText As Int = 0xFF585858
	Public Const ImageParentColor As Int = 0xFFF5F5F5
	Public Const SearchIconChar As String = Chr(0xF002)
	Public Const NoMoreItemsBackground As Int = 0xFFAEAEAE
	Public Const EmptyList As List = Array()
	Public ReadMoreGradient As B4XBitmap
	Public Const MaxTextHeight As Int = 250dip
	Public Const CLVAnimationDuration as int = 100
End Sub

Public Sub Initialize
	Dim bc As BitmapCreator
	bc.Initialize(200, 50)
	bc.FillGradient(Array As Int(0x00FFFFFF, xui.Color_White), bc.TargetRect, "TOP_BOTTOM")
	ReadMoreGradient = bc.Bitmap
End Sub

