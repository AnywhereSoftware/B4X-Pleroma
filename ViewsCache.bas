﻿B4A=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=9.9
@EndOfDesignText@
Sub Class_Globals
	Private xui As XUI 'ignore
	Private VideoPlayers As Map
	#if B4A
	Private btn As B4XView 'ignore
	Private SimpleExoPlayerView1 As SimpleExoPlayerView
	#else if B4i
	Private VideoPlayer1 As VideoPlayer
	#end if
	Private ImageViews As Map
	Private CardViews As Map
	Private VideosToStatusViews As Map
End Sub

Public Sub Initialize
	VideoPlayers.Initialize	
	ImageViews.Initialize
	CardViews.Initialize
	VideosToStatusViews.Initialize
End Sub

Public Sub GetVideoPlayer (sv As StatusView, attachment As PLMMedia) As Object
	Dim vp As B4XView = GetFromMap(VideoPlayers)
	If vp.IsInitialized = False Then
		vp = CreateVideoPlayer
	End If
	VideosToStatusViews.Put(GetVideoPlayerKey(vp), Array(sv, attachment))
	Return vp
End Sub

'This should match the Sender value in VideoPlayer1_Ready event.
Private Sub GetVideoPlayerKey (vp As B4XView) As Object
	#if B4i
	Dim no As NativeObject = vp.Tag
	return no.GetField("controller") 'Internal controller field
	#else if B4A
	Return vp.Tag 'SimpleExoPlayerWrapper
	#End If
End Sub

Public Sub GetImageView As B4XView
	Dim iv As B4XView = GetFromMap(ImageViews)
	If iv.IsInitialized = False Then
		Return B4XPages.MainPage.CreateImageView
	End If
	Return iv
End Sub

Public Sub GetCardView As CardView
	Dim c As CardView = GetFromMap(CardViews)
	If c = Null Then
		Dim c As CardView
		c.Initialize
	End If
	Return c
End Sub

Public Sub ReleaseCardView (cv As CardView)
	CardViews.Put(cv, False)
End Sub

Public Sub ReleaseImageView(iv As B4XView)
	ImageViews.Put(iv, False)
	B4XPages.MainPage.ImagesCache1.ReleaseImage(iv.Tag)
	iv.RemoveViewFromParent
End Sub

Public Sub ReturnVideoPlayer(vp As B4XView)
	VideoPlayers.Put(vp, False)
	VideoPlayers.Remove(GetVideoPlayerKey(vp))	
End Sub

Private Sub CreateVideoPlayer As Object
	Log("create video player")
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, 102dip, 102dip)
	pnl.LoadLayout("VideoPlayer") 'ignore
#if B4A
	Dim player As SimpleExoPlayer
	player.Initialize("VideoPlayer1")
	SimpleExoPlayerView1.Player = player
	SimpleExoPlayerView1.Tag = player
	SimpleExoPlayerView1.RemoveView
	SimpleExoPlayerView1.UseController = False
	VideoPlayers.Put(SimpleExoPlayerView1, True)
	Return SimpleExoPlayerView1
#else if B4i
	VideoPlayer1.BaseView.RemoveViewFromParent
	VideoPlayer1.BaseView.Tag = VideoPlayer1
	VideoPlayer1.ShowControls = False
	Dim no As NativeObject = VideoPlayer1
	no.GetField("controller").GetField("view").SetField("backgroundColor", no.ColorToUIColor(xui.Color_White))
	Return VideoPlayer1.BaseView
#else if B4J
	Return Null
#end if
End Sub


Public Sub GetFromMap (m As Map) As Object
	For Each vp As Object In m.Keys
		Dim Used As Boolean = m.Get(vp)
		If Used = False Then
			m.Put(vp, True)
			Return vp
		End If
	Next
	Return Null
End Sub

Public Sub SetCircleClip (pnl As B4XView)
#if B4J
	Dim circle As JavaObject
	Dim radius As Double = Max(pnl.Width / 2, pnl.Height / 2)
	Dim cx As Double = pnl.Width / 2
	Dim cy As Double = pnl.Height / 2
	circle.InitializeNewInstance("javafx.scene.shape.Circle", Array(cx, cy, radius))
	Dim jo As JavaObject = pnl
	jo.RunMethod("setClip", Array(circle))
#else 
	SetClipToOutline(pnl)
#End If
End Sub

Public Sub SetClipToOutline (pnl As B4XView)
#If B4A
	Dim jo As JavaObject = pnl
	jo.RunMethod("setClipToOutline", Array(True))
#end if
End Sub

'Level between 0 to 1
Public Sub SetAlpha (View As B4XView, Level As Float)
	#if B4A
	Dim jo As JavaObject = View
	Dim alpha As Float = Level
	jo.RunMethod("setAlpha", Array(alpha))
	#Else If B4J
	Dim n As Node = View
	n.Alpha = Level
	#else if B4i
	Dim v As View = View
	v.Alpha = Level
	#End If
End Sub

Public Sub CreatePreferencesDialog (json As String) As PreferencesDialog
	Dim PrefDialog As PreferencesDialog
	PrefDialog.Initialize(B4XPages.MainPage.Root, "", Constants.DialogWidth, Constants.DialogHeight)
	PrefDialog.LoadFromJson(File.ReadString(File.DirAssets, json))
	Dim views As ViewsCache = B4XPages.MainPage.ViewsCache1
	B4XPages.MainPage.DialogSetLightTheme(PrefDialog.Dialog)
	For Each pi As B4XPrefItem In PrefDialog.PrefItems
		If pi.ItemType <> PrefDialog.TYPE_SEPARATOR Then
			pi.Title = views.CreateRichTextWithSize(pi.Title, 14)
		End If
	Next
	For Each v As B4XView In Array(PrefDialog.CustomListView1.AsView, PrefDialog.mBase)
		v.SetColorAndBorder(xui.Color_Transparent, 0, 0, Constants.DialogCornerRadius)
		views.SetClipToOutline(v)
	Next
	Return PrefDialog
End Sub

Public Sub CreateRichTextWithSize(s As String, size As Int) As Object
	#if B4J
	Return s
	#else 
	Dim cs As CSBuilder
	cs.Initialize
	#if B4A
	cs.Size(14)
	#Else
	cs.Font(Font.CreateNew(14))
	#End If
	Return cs.Append(s).PopAll
	#End If
End Sub


#if B4A
Private Sub VideoPlayer1_Ready
	Dim Success As Boolean = True
#Else if B4i
Private Sub VideoPlayer1_Ready (Success As Boolean)
#End If
'	Log("VideoPlayer_ready: " & Success)
	Dim key As Object
	#if B4A
	key = Sender
	#else if B4I
	Dim player As NativeObject = Sender 'AVPlayerViewController
	Success = Success And (player.GetField("player").GetField("currentItem").GetField("status").AsNumber = 1) 'ignore
	key = player
	#End If
	If VideosToStatusViews.ContainsKey(key) Then
		Dim SVandAttachment() As Object = VideosToStatusViews.Get(key)
		Dim sv As StatusView = SVandAttachment(0)
		sv.VideoReady(Success, SVandAttachment(1))
	Else
		Log("Video player already removed")
	End If
End Sub
