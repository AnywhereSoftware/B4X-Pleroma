B4J=true
Group=Network
ModulesStructureVersion=1
Type=Class
Version=8.3
@EndOfDesignText@
Sub Class_Globals
	Private Cache As B4XOrderedMap
	Private xui As XUI
	Private CurrentlyDownloadingURLs As Map
	Private CurrentlyDownloadingIds As Map
	Private CACHE_MAX_SIZE As Int = 20
	Public const NSFW_URL = "nsfw", MISSING_URL = "missing", PLAY = "play" As String
	Private PermCache As B4XOrderedMap
	Type CachedBitmap (Bmp As B4XBitmap, Url As String, ReferenceCount As Int, IsPermanent As Boolean, IsGif As Boolean, GifFile As String)
	Type ImageConsumer (CBitmaps As List, WaitingId As Int, Target As B4XView, GifTarget As B4XGifView, IsVisible As Boolean, PanelColor As Int, NoAnimation As Boolean)
	Public NoImage As CachedBitmap
	Private WaitingId As Int
	Private const MAX_IMAGE_SIZE As Int = 1000
	Private ImagesLoader As BitmapsAsync
	Private GifViews As List
	Private B4XGifView1 As B4XGifView
	Private GifCounter As Int = 1
	Private WebPLoader As WebP
	Private const REMOVED_ID As Int = -1
	Private RequestsManager1 As RequestsManager
	Public RESIZE_FILLWIDTH = 1, RESIZE_FIT = 2, RESIZE_NONE = 0 , RESIZE_FILL_NO_DISTORTIONS = 3 As Int
End Sub

Public Sub Initialize
	Cache.Initialize
	CurrentlyDownloadingIds.Initialize
	CurrentlyDownloadingURLs.Initialize
	ImagesLoader.Initialize
	ImagesLoader.MaxFileSize = 5 * 1024 * 1024
	NoImage.Initialize
	PermCache.Initialize
	PermCache.Put(NSFW_URL, CreateImageCacheBmp(xui.LoadBitmap(File.DirAssets, "nsfw.74818f9.png"), NSFW_URL))
	PermCache.Put(MISSING_URL, CreateImageCacheBmp(xui.LoadBitmap(File.DirAssets, "Missing-image-232x150.png"), MISSING_URL))
	PermCache.Put(PLAY, CreateImageCacheBmp(xui.LoadBitmap(File.DirAssets, "play.png"), MISSING_URL))
	GifViews.Initialize
	WebPLoader.Initialize
	For Each cb As CachedBitmap In PermCache.Values
		cb.IsPermanent = True
	Next
	RequestsManager1.Initialize
End Sub

'should be called after a call to SetImage
Public Sub HoldAnotherImage(URL As String, Consumer As ImageConsumer)
	Dim id As Int = Consumer.WaitingId
	Wait For (GetImage(URL, Consumer)) Complete (Result As CachedBitmap)
	Result.ReferenceCount = Result.ReferenceCount - 1
	If Consumer.WaitingId = id Then
		Consumer.CBitmaps.Add(Result)
		Result.ReferenceCount = Result.ReferenceCount + 1
	End If
End Sub

Public Sub SetImage (Url As String, Consumer As ImageConsumer, ResizeMode As Int)
	For Each cb As CachedBitmap In Consumer.CBitmaps
		If cb.IsPermanent = False Then
			Log("Previous image not released: " & Url & ", " & cb.Url)
		End If
	Next
	WaitingId = WaitingId + 1
	Dim id As Int =  WaitingId
	Consumer.WaitingId = id
	Wait For (GetImage(Url, Consumer)) Complete (Result As CachedBitmap)
	Result.ReferenceCount = Result.ReferenceCount - 1
	If Consumer.WaitingId = id Then
		If ResizeMode = RESIZE_FILLWIDTH Then
			FillImageViewWidth(Result, Consumer)
		Else If ResizeMode = RESIZE_FIT Then
			FitImageView(Result, Consumer)
		Else If ResizeMode = RESIZE_FILL_NO_DISTORTIONS Then
			FillNoDistortions(Result, Consumer)
		Else
			SetImageAndFillImageView(Result, Consumer)
		End If
	Else
		'Log("index changed")
	End If
End Sub

Public Sub RemovePanelChildImageViews(pnl As B4XView)
	For Each x As B4XView In pnl.GetAllViewsRecursive
		If x.Tag Is ImageConsumer Then
			B4XPages.MainPage.ImagesCache1.ReleaseImage(x.Tag)
		End If
	Next
End Sub

Private Sub FillNoDistortions(cb As CachedBitmap, Consumer As ImageConsumer)
	Dim iv As B4XView = Consumer.Target
	If iv.Parent.IsInitialized = False Or iv.Parent.Parent.IsInitialized = False Then Return
	Dim wr As Float = iv.Parent.Width / cb.Bmp.Width
	Dim hr As Float = iv.Parent.Height / cb.Bmp.Height
	Dim r As Float = Max(wr, hr)
	Dim width As Int = cb.Bmp.Width * r
	Dim height As Int = cb.Bmp.Height * r
	iv.SetLayoutAnimated(0, iv.Parent.Width / 2 - width / 2, iv.Parent.Height / 2 - height / 2, width, height)
	SetImageAndFillImageView(cb, Consumer)
End Sub

Private Sub FillImageViewWidth(cb As CachedBitmap, Consumer As ImageConsumer)
	Dim iv As B4XView = Consumer.Target
	If iv.Parent.IsInitialized = False Or iv.Parent.Parent.IsInitialized = False Then Return
	Dim bmpRatio As Float = cb.bmp.Height / cb.bmp.Width
	Dim height As Int = iv.Parent.Width * bmpRatio
	iv.SetLayoutAnimated(0, 0, iv.Parent.Height / 2 - height / 2, iv.Parent.Width, height)
	SetImageAndFillImageView(cb, Consumer)
End Sub

Private Sub FitImageView(cb As CachedBitmap, Consumer As ImageConsumer)
	Dim iv As B4XView = Consumer.Target
	If iv.Parent.IsInitialized = False Then Return
	Dim bmpRatio As Float = cb.bmp.Width / cb.bmp.Height
	Dim viewRatio As Float = iv.Parent.Width / iv.Parent.Height
	Dim Height, Width As Int
	If viewRatio > bmpRatio Then
		Height = iv.Parent.Height
		Width = iv.Parent.Height * bmpRatio
	Else
		Width = iv.Parent.Width
		Height = iv.Parent.Width / bmpRatio
	End If
	iv.SetLayoutAnimated(0, iv.Parent.Width / 2 - Width / 2, iv.Parent.Height / 2 - Height / 2, Width, Height)
	SetImageAndFillImageView(cb, Consumer)
End Sub

Private Sub SetImageAndFillImageView(cb As CachedBitmap, Consumer As ImageConsumer)
	Consumer.CBitmaps.Add(cb)
	cb.ReferenceCount = cb.ReferenceCount + 1
	If Consumer.IsVisible Then CallSetBitmap(Consumer)
End Sub

Public Sub SetConsumerVisibility(Consumer As ImageConsumer, NewState As Boolean)
	If Consumer.IsVisible = NewState Then Return
	Consumer.IsVisible = NewState
	If Consumer.IsVisible And Consumer.CBitmaps.Size > 0 Then
		CallSetBitmap(Consumer)
	End If
End Sub

Private Sub CallSetBitmap(Consumer As ImageConsumer)
	Dim Target As B4XView = Consumer.Target
	Dim cb As CachedBitmap = Consumer.CBitmaps.Get(0)
	If cb.IsGif Then
		If Target.Parent.IsInitialized = False Then Return
		Consumer.GifTarget = GetGifView
		Consumer.GifTarget.mBase.RemoveViewFromParent
		Target.Parent.AddView(Consumer.GifTarget.mBase, Target.Left, Target.Top, Target.Width, Target.Height)
		Consumer.GifTarget.Base_Resize(Target.Width, Target.Height)
		Try
			Consumer.GifTarget.SetGif(xui.DefaultFolder, cb.GifFile)
		Catch
			Log(LastException)
		End Try
	Else
		ImageViewSetBitmap(Target, cb.Bmp)
	End If
	If Target.Parent.IsInitialized And Consumer.PanelColor <> 0 Then
		Target.Parent.Color = Consumer.PanelColor
	End If
	If Consumer.NoAnimation = False And Target.Parent.IsInitialized Then
		Target.Parent.Visible = False
		Target.Parent.SetVisibleAnimated(100, True)
	End If
End Sub

Private Sub GetImage (Url As String, Consumer As ImageConsumer) As ResumableSub
	If PermCache.ContainsKey(Url) Then
		Return PermCache.Get(Url)
	End If
	Dim MyWaitingId As Int = Consumer.WaitingId
	Sleep(Rnd(100, 300))
	Do While Consumer.IsVisible = False Or Consumer.WaitingId <> MyWaitingId
'		Log("waiting: " & Url)
		Sleep(Rnd(100, 300))
		If Consumer.WaitingId <> MyWaitingId Then
'			Log("removed before download: " & MyWaitingId)
			Return PermCache.Get(MISSING_URL)
		End If
		If CurrentlyDownloadingURLs.Size <= 2 Then Exit
	Loop
	Do While CurrentlyDownloadingURLs.ContainsKey(Url)
		Sleep(200)
	Loop
	If Cache.ContainsKey(Url) Then
		Dim res As CachedBitmap = Cache.Get(Url)
		res.ReferenceCount = res.ReferenceCount + 1
		Return res
	End If
	Dim res As CachedBitmap
	Try
		Dim j As HttpJob
		j.Initialize("", Me)
		j.Download(Url)
		CurrentlyDownloadingURLs.Put(Url, j)
		CurrentlyDownloadingIds.Put(MyWaitingId, Url)
		Wait For (j) JobDone(j As HttpJob)
		If Consumer.WaitingId = MyWaitingId And j.Success Then
			
			Dim ContentType As String = j.Response.ContentType
			Dim IsGif As Boolean = ContentType = "image/gif"
			Dim ShouldLoadRegularImage As Boolean = True
			If IsGif Then
				'In B4i the downloaded data cannot be accessed asynchronously. The input stream must be opened before the sub is paused.
				#if B4i
				Dim GifFile As String = LoadGif(j)
				#else
				Wait For (LoadGif(j)) Complete (GifFile As String)
				#End If
				If GifFile <> "" Then
					Log("Gif: " & Url)
					res.GifFile = GifFile
				End If
			Else If ContentType = "image/webp" Then
				Log("loading webp: " & Url)
				Dim bmp As B4XBitmap = WebPLoader.LoadWebP(Bit.InputStreamToBytes(j.GetInputStream))
				ShouldLoadRegularImage = False
			End If
			If ShouldLoadRegularImage Then
				Wait For (ImagesLoader.LoadFromHttpJob(j, MAX_IMAGE_SIZE, MAX_IMAGE_SIZE)) Complete (bmp As B4XBitmap)
			End If
			If bmp.IsInitialized Then
				#if B4A
				If ContentType = "image/jpeg" Then
					bmp = RotateJpegIfNeeded(bmp, j)
				End If
				#end if
				res = CreateImageCacheBmp(bmp, Url)
				res.ReferenceCount = res.ReferenceCount + 1
				res.IsGif  = IsGif
				res.GifFile = GifFile
			Else
				Log("error loading bitmap")
			End If
		Else
			Log("ERROR: " & MyWaitingId & ": " & j.ErrorMessage)
		End If
	Catch
		Log("Caught error: " & LastException)
	End Try
	j.Release
	If res.IsInitialized Then
		If Cache.Size > CACHE_MAX_SIZE Then
			ClearCache
		End If
		Cache.Put(Url, res)
	Else
		res = PermCache.Get(MISSING_URL)
	End If
	CurrentlyDownloadingURLs.Remove(Url)
	CurrentlyDownloadingIds.Remove(MyWaitingId)
	Return res
End Sub

#if B4i
Private Sub LoadGif (job As HttpJob) As String
#Else
Private Sub LoadGif (job As HttpJob) As ResumableSub
#End If
	GifCounter = GifCounter + 1
	Dim FileName As String = GifCounter & ".gif"
	File.Delete(xui.DefaultFolder, FileName)
	Dim out As OutputStream = File.OpenOutput(xui.DefaultFolder, FileName, False)
	#if B4i
	'in B4i the downloaded data is not available when JobDone ends. This means that it must be done synchronously.
	File.Copy2(job.GetInputStream, out)
	out.Close
	Return FileName
	#else
	Wait For (File.Copy2Async(job.GetInputStream, out)) Complete (Success As Boolean)
	out.Close
	If Success Then
		Return FileName
	Else
		Return ""	
	End If
	#End If
End Sub

#if B4A
Private Sub RotateJpegIfNeeded (bmp As B4XBitmap, job As HttpJob) As B4XBitmap
	Dim p As Phone
	If p.SdkVersion >= 24 Then
		Dim ExifInterface As JavaObject
		Dim in As InputStream = job.GetInputStream
		ExifInterface.InitializeNewInstance("android.media.ExifInterface", Array(in))
		Dim orientation As Int = ExifInterface.RunMethod("getAttribute", Array("Orientation"))
		in.Close
	End If
	Return bmp
End Sub
#End If

Private Sub ClearCache
	For Each ic As CachedBitmap In Cache.Values
		If ic.ReferenceCount < 0 Then
			Log("error: " & ic.ReferenceCount)
		End If
		If ic.ReferenceCount <= 0 Then
			Cache.Remove(ic.Url)
'			Log("removing: " & ic.Url & ", " & ic.ReferenceCount)
			#if B4A
			If ic.Bmp.IsInitialized Then
				Dim jo As JavaObject = ic.Bmp
				jo.RunMethod("recycle", Null)
			End If
			#End If
			ic.Bmp = Null
			'Log("release: " & ic.Url)
		End If
	Next
'	Log("Cache size: " & Cache.Size)
End Sub

Private Sub CreateImageCacheBmp (Bmp As B4XBitmap, Url As String) As CachedBitmap
	Dim t1 As CachedBitmap
	t1.Initialize
	t1.Bmp = Bmp
	t1.Url = Url
	t1.ReferenceCount = 0
	Return t1
End Sub


Public Sub ReleaseImage(Consumer As ImageConsumer)
	For Each cb As CachedBitmap In Consumer.CBitmaps
		If cb.IsPermanent = False Then
			cb.ReferenceCount = cb.ReferenceCount - 1
			If cb.IsGif Then
				If Consumer.GifTarget.IsInitialized Then
					Consumer.GifTarget.mBase.GetView(0).SetBitmap(Null)
					#if B4A
					If Consumer.GifTarget.GifDrawable.IsInitialized Then
						Consumer.GifTarget.GifDrawable.RunMethod("recycle", Null)
					End If
					#End If
					Consumer.GifTarget.mBase.RemoveViewFromParent
					GifViews.Add(Consumer.GifTarget)
				End If
			End If
		End If
	Next
	Consumer.CBitmaps.Clear
	ImageViewSetBitmap(Consumer.Target, Null)
	If CurrentlyDownloadingIds.ContainsKey(Consumer.WaitingId) Then
		Dim url As String = CurrentlyDownloadingIds.Get(Consumer.WaitingId)
		RequestsManager1.CancelRequest(url, CurrentlyDownloadingURLs.Get(url))
	End If
	Consumer.WaitingId = REMOVED_ID
	
End Sub

Private Sub ImageViewSetBitmap(Target As B4XView, bmp As B4XBitmap)
	If Target Is ImageView Then
		If bmp.IsInitialized = False Then
			Target.SetBitmap(Null)
		Else
			Target.SetBitmap(bmp)
			#if B4A
			Dim iiv As ImageView = Target
			iiv.Gravity = Gravity.FILL
			#End If
		End If
	Else
		CallSub2(Target.Tag, "SetBitmap", bmp)
	End If
End Sub

Private Sub GetGifView As B4XGifView
	If GifViews.Size > 0 Then
		Dim gif As B4XGifView = GifViews.Get(0)
		GifViews.RemoveAt(0)
		Return gif
	End If
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, 102dip, 102dip)
	pnl.LoadLayout("GifView")
	B4XGifView1.mBase.RemoveViewFromParent
	'don't capture the touch events
	#if B4J
	Private jo = B4XGifView1.mBase As JavaObject
	jo.RunMethod("setMouseTransparent", Array(True))
	#else if B4i
	Dim v As View = B4XGifView1.mBase
	v.UserInteractionEnabled = False
	#end if
	Return B4XGifView1
End Sub