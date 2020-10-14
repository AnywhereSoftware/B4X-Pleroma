B4J=true
Group=Misc
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
	Public Const URL_PUBLIC As String = "/api/v1/timelines/public"
	Public Const URL_HOME As String = "/api/v1/timelines/home"
	Public Const URL_NOTIFICATIONS As String = "/api/v1/notifications"
	Public Const LINKTYPE_TAG = 1, LINKTYPE_USER = 2, LINKTYPE_OTHER = 3, LINKTYPE_TIMELINE = 4, LINKTYPE_THREAD = 5, _
		LINKTYPE_SEARCH = 6, LINKTYPE_NOTIFICATIONS = 7 As Int
	Public AppName As String = "B4X Pleroma"
	
	Public Const StackMaximumNumberOfItems As Int = 6
	Public Const Version As Float = 1.19
	Public Const TempImageFileName As String = "tempimage"
	Public Const PushPublicKey As String = "BHDfTUyMS9YZ2HHSivY98uXUNcSfsTaDMFUlNBSFYxoZQSIcihVNOsOKIyaPPsbWNeTlCuelJnPvAZDIPPLTJoo="
	Public Const EndPointBase As String = "https://b4x.com:51051/push/"
	Public Const NotificationSettingsStoreKey As String = "Notification Settings"
	Public Const DefaultServer As String = "mas.to"
	
	Public Const ExtraContentKeyNotification As String = "notification"
	Public Const ExtraContentKeyCard As String = "card"
	Public Const ExtraContentKeyReblog As String = "reblog"
	
	Public Const LinkExtraCurrentStatus As String = "current"
	Public Const TextRunThreadLink As String = "~time"
End Sub

Public Sub Initialize
	Dim bc As BitmapCreator
	bc.Initialize(200, 50)
	bc.FillGradient(Array As Int(0x00FFFFFF, xui.Color_White), bc.TargetRect, "TOP_BOTTOM")
	ReadMoreGradient = bc.Bitmap
End Sub



