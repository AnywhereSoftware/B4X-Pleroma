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
	Public Const PlusChar As String = Chr(0xF067)
	Public Const NoMoreItemsBackground As Int = 0xFFAEAEAE
	Public Const EmptyList As List = Array()
	Public ReadMoreGradient As B4XBitmap
	Public Const MaxTextHeight As Int = 250dip
	Public Const MissingBitmapFileName As String = "Missing-image-232x150.png"
	Public Const CLVAnimationDuration As Int = 100
	Public Const DefaultTextBackground As Int = xui.Color_White
	Public Const OverlayColor As Int = 0x44000000
	Public Const StackItemRelevantPeriod As Int = 5 * DateTime.TicksPerMinute
	
	Public Const URL_TAG As String = "/api/v1/timelines/tag/"
	Public Const URL_USER As String = "/api/v1/accounts/:id"
	Public Const URL_THREAD As String = "/api/v1/statuses/:id/context"
	Public Const URL_SEARCH As String = "/api/v2/search/"
	Public Const LINKTYPE_TAG = 1, LINKTYPE_USER = 2, LINKTYPE_OTHER = 3, LINKTYPE_TIMELINE = 4, LINKTYPE_THREAD = 5, _
		LINKTYPE_SEARCH = 6 As Int
	Public AppName As String = "B4X Pleroma"
	
	Public Const StackMaximumNumberOfItems As Int = 6
	Public Const Version As Float = 1.16
	Public Const TempImageFileName as string = "tempimage"
End Sub

Public Sub Initialize
	Dim bc As BitmapCreator
	bc.Initialize(200, 50)
	bc.FillGradient(Array As Int(0x00FFFFFF, xui.Color_White), bc.TargetRect, "TOP_BOTTOM")
	ReadMoreGradient = bc.Bitmap
	
End Sub



