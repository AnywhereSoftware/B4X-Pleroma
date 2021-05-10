B4J=true
Group=Misc
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private xui As XUI
	Public Const SearchIconChar As String = Chr(0xF002)
	Public Const PlusChar As String = Chr(0xF067)

	Public Const EmptyList As List = Array()
	Public Const MaxTextHeight As Int = 250dip
	Public Const MissingBitmapFileName As String = "Missing-image-232x150.png"
	Public Const CLVAnimationDuration As Int = 100
	Public Const StackItemRelevantPeriod As Int = 5 * DateTime.TicksPerMinute
	
	Public Const URL_TAG As String = "/api/v1/timelines/tag/"
	Public Const URL_USER As String = "/api/v1/accounts/:id"
	Public Const URL_THREAD As String = "/api/v1/statuses/:id/context"
	Public Const URL_SEARCH As String = "/api/v2/search/"
	Public Const URL_PUBLIC As String = "/api/v1/timelines/public"
	Public Const URL_HOME As String = "/api/v1/timelines/home"
	Public Const URL_NOTIFICATIONS As String = "/api/v1/notifications"
	Public Const URL_CHATS_LIST As String = "/api/v1/pleroma/chats"
	Public Const URL_DIRECTMESSAGES_LIST As String = "/api/v1/conversations"
	
	Public Const LINKTYPE_TAG = 1, LINKTYPE_USER = 2, LINKTYPE_OTHER = 3, LINKTYPE_TIMELINE = 4, LINKTYPE_THREAD = 5, _
		LINKTYPE_SEARCH = 6, LINKTYPE_NOTIFICATIONS = 7, LINKTYPE_CHAT = 8, LINKTYPE_CHATS_LIST = 9, _
		LINKTYPE_DIRECTMESSAGES_LIST = 10 As Int
	Public AppName As String = "B4X for P & M"
	
	Public Const StackMaximumNumberOfItems As Int = 6
	Public Const Version As Float = 1.46
	Public Const TempImageFileName As String = "tempimage"
	Public Const PushPublicKey As String = "BHDfTUyMS9YZ2HHSivY98uXUNcSfsTaDMFUlNBSFYxoZQSIcihVNOsOKIyaPPsbWNeTlCuelJnPvAZDIPPLTJoo="
	Public Const EndPointBase As String = "https://b4x.com:51051/push/"
	Public Const CrashReportsServer As String = "https://b4x.com:51051/report"
	Public Const NotificationSettingsStoreKey As String = "Notification Settings"
	Public Const DefaultServer As String = "mas.to"
	
	Public Const ExtraContentKeyNotification As String = "notification"
	Public Const ExtraContentKeyDirectMessageAccounts As String = "direct message accounts"
	Public Const ExtraContentKeyCard As String = "card"
	Public Const ExtraContentKeyReblog As String = "reblog"
	
	Public Const LinkExtraCurrentStatus As String = "current"
	Public Const TextRunThreadLink As String = "~time"
	
	Public Const DialogHeight As Int = 210dip
	Public Const DialogWidth As Int = 280dip
	Public Const DialogCornerRadius As Int = 5dip
	
	Public Const DefaultReactions As List = Array("👍", "😍", "❤", "🙏", "🤣", "😊", "🤔", "😞", "😡")
	
	Public ToastDurationMs As Int = 5000
	Public UserContentAgreement As String = $"There is no tolerance for objectionable content or abusive behavior.
Before you can post, you need to agree not to post objectional content."$
	Public VisibilityKeyToUserValue As Map = CreateMap("public": "Public", "unlisted": "Unlisted", "private": "Private", "direct": "Direct")
	Public Const SOUND_MESSAGE = "message" As String
	
	Public Const NewChatMessageTitle As String = "New Chat Message"
	Public Const DateFormat As String = DateTime.DeviceDefaultDateFormat
End Sub

Public Sub Initialize
	
End Sub



