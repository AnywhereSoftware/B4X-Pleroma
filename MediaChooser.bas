B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	#if B4J
	Private fc As FileChooser
	#Else If B4A
	Private ion As Object
	Private VideoRecorder As VideoRecordApp
	#Else If B4i
	Private llCamera As LLCamera 'ignore, just used for the authorization status
	Private Camera As Camera
	#End If
	Type PostMedia (Media As PLMMedia, Pnl As B4XView, Uploading As Boolean, UploadedSuccessfully As Boolean, _
		FileName As String, Removed As Boolean, DeleteTempFile As Boolean, IsImage As Boolean)
	Private TempFileIndex As Int
	Private NoResult As PostMedia
	Private xui As XUI
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	#if B4A
	VideoRecorder.Initialize("VideoRecorder")
	#Else If B4i
	Camera.Initialize("Camera", B4XPages.GetNativeParent(B4XPages.MainPage))
	Camera.AllowsEditing = True
	#End If
End Sub

#if B4A
Public Sub AddVideoFromCamera As ResumableSub
	Dim folder As String = B4XPages.MainPage.Provider.SharedFolder
	Dim FileName As String = GetTempFile
	VideoRecorder.Record3(folder, FileName, -1, B4XPages.MainPage.Provider.GetFileUri(FileName))
	Wait For VideoRecorder_RecordComplete (Success As Boolean)
	If Success Then
		Return CreatePostMedia(File.Combine(folder, FileName), True, False)
	End If
	Return NoResult
End Sub

Public Sub AddImageFromCamera As ResumableSub
	Dim i As Intent
	i.Initialize("android.media.action.IMAGE_CAPTURE", "")
	Dim tempImageFile As String = GetTempFile
	Dim provider As FileProvider = B4XPages.MainPage.Provider
	File.Delete(B4XPages.MainPage.Provider.SharedFolder, tempImageFile)
	Dim u As Object = provider.GetFileUri(tempImageFile)
	i.PutExtra("output", u) 'the image will be saved to this path
	Try
		StartActivityForResult(i)
		Wait For ion_Event (MethodName As String, Args() As Object)
		If -1 = Args(0) Then
			Try
				Dim in As Intent = Args(1)
				If File.Exists(provider.SharedFolder, tempImageFile) Then
					
				Else If in.HasExtra("data") Then 'try to get thumbnail instead
					Dim jo As JavaObject = in
					Dim bmp As B4XBitmap = jo.RunMethodJO("getExtras", Null).RunMethod("get", Array("data"))
					Dim out As OutputStream = File.OpenOutput (provider.SharedFolder, tempImageFile, False)
					bmp.WriteToStream(out, 100, "PNG")
					out.Close
				End If
				Return CreatePostMedia(File.Combine(provider.SharedFolder, tempImageFile), True, True)
			Catch
				Log(LastException)
			End Try
		End If
	Catch
		Log(LastException)
	End Try
	Return NoResult
End Sub

Sub StartActivityForResult(i As Intent)
	Dim jo As JavaObject = Me
	jo = jo.RunMethod("getBA", Null)
	ion = jo.CreateEvent("anywheresoftware.b4a.IOnActivityResult", "ion", Null)
	jo.RunMethod("startActivityForResult", Array(ion, i))
End Sub
#Else If B4J
Public Sub AddImageFromCamera As ResumableSub
	B4XPages.MainPage.ShowMessage("not implemented")
	Return NoResult
End Sub

Public Sub AddVideoFromCamera As ResumableSub
	B4XPages.MainPage.ShowMessage("not implemented")
	Return NoResult
End Sub

Public Sub AddVideoFromGallery As ResumableSub
	B4XPages.MainPage.ShowMessage("not implemented")
	Return NoResult
End Sub
#else if B4i
Public Sub AddImageFromCamera As ResumableSub
	If CheckPermission = False Then 
		Return NoResult
	End If
	If Camera.IsSupported = False Then
		B4XPages.MainPage.ShowMessage("Not supported")
	Else
		Camera.TakePicture
		Wait For Camera_Complete (Success As Boolean, Image As Bitmap, VideoPath As String)
		If Success Then
			Return CreatePostMedia(File.Combine(xui.DefaultFolder, CopyImageFromCamera(Image)), True, True)
		End If
	End If
	Return NoResult
End Sub

Private Sub CopyImageFromCamera (Image As Bitmap) As String
	Dim temp As String = GetTempFile
	Dim out As OutputStream = File.OpenOutput(xui.DefaultFolder, temp, False)
	Image.WriteToStream(out, 100, "JPEG")
	out.Close
	Return temp
End Sub

Private Sub CheckPermission As Boolean
	If llCamera.AuthorizationDenied Then
		B4XPages.MainPage.ShowMessage("No permission to access camnera. Enable it in device settings.")
		Return False
	End If
	Return True
End Sub

Public Sub AddVideoFromCamera As ResumableSub
	If CheckPermission = False Then Return NoResult
	If Camera.IsVideoSupported = False Then
		B4XPages.MainPage.ShowMessage("Not supported")
	Else
		Camera.TakeVideo
		Dim TopPage As String = B4XPages.GetManager.GetTopPage.Id
		Wait For Camera_Complete (Success As Boolean, Image As Bitmap, VideoPath As String)
		B4XPages.GetManager.mStackOfPageIds.Add(TopPage)
		If VideoPath <> "" Then
			Return CreatePostMedia(VideoPath, True, False)
		End If
	End If
	Return NoResult
End Sub


#End If

Public Sub AddImageFromGallery (btn As B4XView) As ResumableSub
	#if B4J
	If fc.IsInitialized = False Then
		fc.Initialize
	End If
	Dim f As String = fc.ShowOpen(B4XPages.GetNativeParent(B4XPages.MainPage))
	If f <> "" Then
		Return CreatePostMedia(f, False, True)
	Else
		Return NoResult
	End If
	#Else If B4A
	Wait For (MediaFromContentChooser(False)) Complete (pm As PostMedia)
	Return pm
	#Else If B4i
	Camera.SelectFromPhotoLibrary(btn, Camera.TYPE_IMAGE)
	Dim TopPage As String = B4XPages.GetManager.GetTopPage.Id
	Wait For Camera_Complete (Success As Boolean, Image As Bitmap, VideoPath As String)
	B4XPages.GetManager.mStackOfPageIds.Add(TopPage)
	If Success Then
		Return CreatePostMedia(File.Combine(xui.DefaultFolder, CopyImageFromCamera(Image)), True, True)
	End If
	Return NoResult
	#End If
End Sub

#if B4A
Public Sub AddVideoFromGallery As ResumableSub
	Wait For (MediaFromContentChooser(True)) Complete (pm As PostMedia)
	Return pm
End Sub
#else if B4i
Public Sub AddVideoFromGallery (Callback As Object, Event As String, btn As B4XView)
	Camera.SelectFromPhotoLibrary(btn, Camera.TYPE_MOVIE)
	Wait For Camera_Complete (Success As Boolean, Image As Bitmap, VideoPath As String)
	If VideoPath <> "" Then
		CallSub2(Callback, Event, CreatePostMedia(VideoPath, True, False))
	End If
End Sub
#End If



#if b4a
Private Sub MediaFromContentChooser (Video As Boolean) As ResumableSub
	Dim cc As ContentChooser
	cc.Initialize("cc")
	If Video Then
		cc.Show("video/*", "Choose video")
	Else
		cc.Show("image/*", "Choose image")
	End If
	Wait For CC_Result (Success As Boolean, Dir As String, FileName As String)
	If Success Then
		Dim MediaFile As String = GetTempFile		
		B4XPages.MainPage.ShowProgress
		Wait For (File.CopyAsync(Dir, FileName, xui.DefaultFolder, MediaFile)) Complete (Success As Boolean)
		B4XPages.MainPage.HideProgress
		If Success Then
			MediaFile = File.Combine(xui.DefaultFolder, MediaFile)
			Return CreatePostMedia(MediaFile, True, Video = False)
		End If
	End If
	Return NoResult
End Sub
#End If

Private Sub GetTempFile As String 'ignore
	TempFileIndex = TempFileIndex + 1
	Return "temp-" & TempFileIndex
End Sub

Private Sub CreatePostMedia (MediaFile As String, TempFileShouldBeDeleted As Boolean, IsImage As Boolean) As PostMedia
	Dim pm As PostMedia
	pm.Initialize
	pm.FileName = MediaFile
	pm.DeleteTempFile = TempFileShouldBeDeleted
	pm.IsImage = IsImage
	Return pm
End Sub