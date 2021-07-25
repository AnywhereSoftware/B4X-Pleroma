B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=11
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: True
	#IncludeTitle: False
#End Region

Sub Process_Globals

End Sub

Sub Globals
	Private SimpleExoPlayerView1 As SimpleExoPlayerView
	Private lblExitFullScreen As B4XView
	Private viewcache As ViewsCache
End Sub

Sub Activity_Create(FirstTime As Boolean)
	If B4XPages.IsInitialized = False Then
		StartActivity(Main)
		Activity.Finish
		Return
	End If
	Activity.LoadLayout("FullScreen")
	viewcache = B4XPages.MainPage.ViewsCache1
	SwitchTargetPlayerView(True)
	viewcache.PutLabelInVideoTopRightCorner(SimpleExoPlayerView1, lblExitFullScreen, False)
	SimpleExoPlayerView1.Tag.As(SimpleExoPlayer).Play
End Sub

Private Sub SwitchTargetPlayerView(FullScreenIsDestination As Boolean)
	Dim jo As JavaObject
	Dim player As Object = viewcache.FullScreenPlayer.Tag.As(JavaObject).GetField("player")
	SimpleExoPlayerView1.Tag = viewcache.FullScreenPlayer.Tag
	jo.InitializeStatic("com.google.android.exoplayer2.ui.PlayerView")
	jo.RunMethod("switchTargetView", Array(player, IIf(FullScreenIsDestination, viewcache.FullScreenPlayer, SimpleExoPlayerView1), _
		IIf(FullScreenIsDestination, SimpleExoPlayerView1,	viewcache.FullScreenPlayer)))
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)
	SwitchTargetPlayerView(False)
End Sub


Private Sub lblExitFullScreen_Click
	Activity.Finish
End Sub