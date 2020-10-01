B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
#Event: Close
#Event: NewPost (Status As PLMStatus)
Sub Class_Globals
	Private xui As XUI
	Public mBase As B4XView
	Public B4XFloatTextField1 As B4XFloatTextField
	Public mReplyToId As String
	Private IdempotencyKey As String
	Private tu As TextUtils
	Private mCallback As Object
	Private mEventName As String
	Private btnCancel As B4XView
	Private btnCamera As B4XView	
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
		FileName As String, Removed As Boolean, DeleteTempFile As Boolean)
	Private Medias As List
	Private pnlMedia As B4XView
	Private B4XImageView1 As B4XImageView
	Private InDialog As Boolean
	Private Posting As Boolean
	Private MediaSize As Int = 50dip
	Private TempFileIndex As Int
	Private PrefDialog As PreferencesDialog
	Private PostOptions As Map
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	mBase.LoadLayout("PostView")
	tu = B4XPages.MainPage.TextUtils1
	mCallback = Callback
	mEventName = EventName
	Medias.Initialize
	#if B4A
	VideoRecorder.Initialize("VideoRecorder")
	#Else If B4i
	Camera.Initialize("Camera", B4XPages.GetNativeParent(B4XPages.MainPage))
	
	#End If
	
End Sub

Public Sub SetContent(Content As PLMPost, ListItem As PLMCLVItem)
	PostOptions = CreateMap("nsfw": False, "visibility": "Public")
	mReplyToId = Content.ReplyId
	For Each pm As PostMedia In Medias
		pm.Pnl.RemoveViewFromParent
	Next
	Medias.Clear
	InDialog = Content.ReplyId = ""
	btnCancel.Visible = Not(InDialog)
	IdempotencyKey = Rnd(0, 0x7FFFFFFF)
	B4XFloatTextField1.Text = ""
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	B4XFloatTextField1.lblV.Font = xui.CreateMaterialIcons(28)
	B4XFloatTextField1.lblV.Text = Chr(0xE163)
	
	If xui.IsB4i Then
		B4XFloatTextField1.mBase.SetColorAndBorder(xui.Color_Transparent, 1dip, xui.Color_LightGray, 2dip)
	End If
	ArrangeMedias
End Sub

Public Sub SetVisibility (visible As Boolean)
	
End Sub

Private Sub btnSubmit_Click
	Post(B4XFloatTextField1.Text)
End Sub

Private Sub Post (status As String)
	If status.Trim = "" Then Return
	If Posting Then Return
	Dim AttachmentIds As List
	AttachmentIds.Initialize
	For Each pm As PostMedia In Medias
		If pm.Uploading Then
			B4XPages.MainPage.ShowMessage("Attachments are still being uploaded. Please try again shortly.")
			Return
		End If
		If pm.Removed = False And pm.UploadedSuccessfully Then
			AttachmentIds.Add(pm.Media.Id)
		End If
	Next
	Posting = True
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase)
	If j = Null Then Return
	Dim params As Map = CreateMap("status": status)
	If mReplyToId <> "" Then params.Put("in_reply_to_id", mReplyToId)
	Dim vis As String = PostOptions.Get("visibility")
	params.Put("visibility", vis.ToLowerCase)
	params.Put("sensitive", PostOptions.Get("nsfw"))
	If AttachmentIds.Size > 0 Then params.Put("media_ids", AttachmentIds)
	Dim jg As JSONGenerator
	jg.Initialize(params)
	j.PostString(B4XPages.MainPage.GetServer.URL & $"/api/v1/statuses"$, jg.ToString)
	j.GetRequest.SetHeader("Idempotency-Key", IdempotencyKey)
	j.GetRequest.SetContentType("application/json")
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	B4XPages.MainPage.HideProgress
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			Dim st As PLMStatus = tu.ParseStatus(m)
			For Each pm As PostMedia In Medias
				If pm.Removed = False Then pm.UploadedSuccessfully = True
			Next
			If AttachmentIds.Size > 0 Then
				Sleep(1000) 'give the server some time to process the attachments.
			End If
			CallSub2(mCallback, mEventName & "_NewPost", st)
		End If
		
	End If
	Posting = False
	j.Release
End Sub

Public Sub RemoveFromParent
	mBase.RemoveViewFromParent
	For Each pm As PostMedia In Medias
		If pm.UploadedSuccessfully = False And pm.Uploading = False Then
			RemoveFromServer(pm)		
		End If
		If pm.DeleteTempFile Then
			File.Delete(pm.FileName, "")
		End If
	Next
	Medias.Clear
End Sub

Private Sub RemoveFromServer (pm As PostMedia) 'ignore
	'should be implemented when there is an API to remove already uploaded posts
	
End Sub

Private Sub btnCancel_Click
	CallSub(mCallback, mEventName & "_Close")
End Sub

Private Sub B4XFloatTextField1_EnterPressed
	btnSubmit_Click
End Sub

#if B4A
Private Sub AddVideoFromCamera
	Dim folder As String = B4XPages.MainPage.Provider.SharedFolder
	Dim FileName As String = GetTempFile
	VideoRecorder.Record3(folder, FileName, -1, B4XPages.MainPage.Provider.GetFileUri(FileName))
	Wait For VideoRecorder_RecordComplete (Success As Boolean)
	If Success Then
		AttachMediaFile(CreatePostMedia(File.Combine(folder, FileName), True), False)
	End If
End Sub

Private Sub AddImageFromCamera
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
				AttachMediaFile(CreatePostMedia(File.Combine(provider.SharedFolder, tempImageFile), True), True)
			Catch
				Log(LastException)
			End Try
		End If
	Catch
		Log(LastException)
	End Try
End Sub

Sub StartActivityForResult(i As Intent)
	Dim jo As JavaObject = Me
	jo = jo.RunMethod("getBA", Null)
	ion = jo.CreateEvent("anywheresoftware.b4a.IOnActivityResult", "ion", Null)
	jo.RunMethod("startActivityForResult", Array(ion, i))
End Sub
#Else If B4J
Private Sub AddImageFromCamera
	B4XPages.MainPage.ShowMessage("not implemented")
End Sub
Private Sub AddVideoFromCamera
	B4XPages.MainPage.ShowMessage("not implemented")
End Sub
#else if B4i
Private Sub AddImageFromCamera
	If CheckPermission = False Then Return
	If Camera.IsSupported = False Then
		B4XPages.MainPage.ShowMessage("Not supported")
	Else
		Camera.TakePicture
	End If
End Sub

Private Sub CheckPermission As Boolean
	If llCamera.AuthorizationDenied Then
		B4XPages.MainPage.ShowMessage("Not permission to access camnera. Enable it in device Settings.")
		Return False
	End If
	Return True
End Sub

Private Sub AddVideoFromCamera
	If CheckPermission = False Then Return
	If Camera.IsVideoSupported = False Then
		B4XPages.MainPage.ShowMessage("Not supported")
	Else
		Camera.TakeVideo
	End If
End Sub

Private Sub Camera_Complete (Success As Boolean, Image As Bitmap, VideoPath As String)
	If Success Then
		If VideoPath <> "" Then
			AttachMediaFile(CreatePostMedia(VideoPath, True), False)
		Else
			Dim temp As String = GetTempFile
			Dim out As OutputStream = File.OpenOutput(xui.DefaultFolder, temp, False)
			Image.WriteToStream(out, 100, "JPEG")
			out.Close
			AttachMediaFile(CreatePostMedia(File.Combine(xui.DefaultFolder, temp), True), True)
		End If
	End If
End Sub
#End If

Sub btnGallery_Click
	AddImageFromGallery
End Sub


Private Sub AddImageFromGallery
	#if B4J
	If fc.IsInitialized = False Then
		fc.Initialize
	End If
	Dim f As String = fc.ShowOpen(B4XPages.GetNativeParent(B4XPages.MainPage))
	If f <> "" Then
		AttachMediaFile(CreatePostMedia(f, False), True)
	End If
	#Else If B4A
	Wait For (MediaFromContentChooser(False)) Complete (unused As Boolean)
	#Else If B4i
	Camera.SelectFromPhotoLibrary(btnCamera, Camera.TYPE_IMAGE)
	#End If
	B4XFloatTextField1.RequestFocusAndShowKeyboard
End Sub

Private Sub AddVideoFromGallery
	#if B4A
	Wait For (MediaFromContentChooser(True)) Complete (unused As Boolean)
	#Else If B4i
	Camera.SelectFromPhotoLibrary(btnCamera, Camera.TYPE_MOVIE)
	#End If
	B4XFloatTextField1.RequestFocusAndShowKeyboard
End Sub

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
			AttachMediaFile(CreatePostMedia(MediaFile, True), Video = False)
		End If
	End If
	Return True
End Sub
#End If

Private Sub GetTempFile As String 'ignore
	TempFileIndex = TempFileIndex + 1
	Return "temp-" & TempFileIndex
End Sub

Private Sub AttachMediaFile (pm As PostMedia, IsImage As Boolean)
	Dim FileSize As Long = File.Size(pm.FileName, "")
	If IsImage And FileSize > 8 * 1024 * 1024 Then
		B4XPages.MainPage.ShowMessage($"Maximum image size: 8 MB. Current image size: $1.0{FileSize / 1024 / 1024} MB."$)
		Return
	Else If FileSize > 40 * 1024 * 1024 Then
		B4XPages.MainPage.ShowMessage($"Maximum video size: 40 MB. Current video size: $1.0{FileSize / 1024 / 1024} MB."$)
		Return
	End If
	If Posting Then Return
	Medias.Add(pm)
	pm.Pnl = xui.CreatePanel("")
	pm.Pnl.SetLayoutAnimated(0, 0, 0, MediaSize + 10dip , MediaSize + 10dip)
	pm.Pnl.LoadLayout("PostViewMedia")
	pm.Pnl.Tag = pm
	If IsImage Then
		Try
			B4XImageView1.Bitmap = xui.LoadBitmapResize(pm.FileName, "", MediaSize, MediaSize, True)
		Catch
			B4XImageView1.Bitmap = xui.LoadBitmapResize(File.DirAssets, Constants.MissingBitmapFileName, MediaSize, MediaSize, True)
		End Try
	Else
		pm.Pnl.GetView(1).Text = "Video"
	End If
	pm.Pnl.GetView(pm.Pnl.NumberOfViews -1).Visible = False
	B4XPages.MainPage.ViewsCache1.SetAlpha(pm.Pnl, 0.3)
	ArrangeMedias
	UploadMedia (pm)
End Sub

Private Sub ArrangeMedias
	pnlMedia.RemoveAllViews
	Dim count As Int
	Dim Offset As Int
	If InDialog Then Offset = 20dip Else Offset = 5dip
	For Each pm As PostMedia In Medias
		If pm.Removed Then Continue
		pnlMedia.AddView(pm.Pnl, Offset + (MediaSize + 15dip) * count, 0, pm.Pnl.Width, pm.Pnl.Width)
		count = count + 1
	Next
End Sub

Private Sub UploadMedia (pm As PostMedia)
	pm.Uploading = True
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase)
	If j = Null Then Return
	Dim part As MultipartFileData
	part.Initialize
	part.FileName = pm.FileName
	part.KeyName = "file"
	Log($"Uploading ${pm.FileName}, size: $1.0{File.Size(pm.FileName, "") / 1024 / 1024} MB"$)
	j.PostMultipart(B4XPages.MainPage.GetServer.URL & $"/api/v2/media"$, Null, Array(part))
	B4XPages.MainPage.auth.AddAuthorization(j)
	Wait For (j) JobDone(j As HttpJob)
	If j.Success Then
		Dim m As Map = tu.JsonParseMap(j.GetString)
		If m.IsInitialized Then
			pm.Media = tu.CreateAttachment(m)
			pm.Uploading = False
			If pm.Removed = False Then
				B4XPages.MainPage.ViewsCache1.SetAlpha(pm.Pnl, 1)
				pm.Pnl.GetView(pm.Pnl.NumberOfViews -1).Visible = True
				pm.UploadedSuccessfully = True
			Else
				RemoveFromServer(pm)	
			End If
		End If
	Else
		Log("Failed to upload")
		pm.Removed = True
		ArrangeMedias
		B4XPages.MainPage.ShowMessage("Error uploading attachment.")
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

#if B4J
Private Sub lblDelete_MouseClicked (EventData As MouseEvent)
	EventData.Consume
#Else
Private Sub lblDelete_Click
#end if
	Dim lbl As B4XView = Sender
	Dim pm As PostMedia = lbl.Parent.Tag
	pm.Removed = True
	ArrangeMedias
End Sub


Private Sub btnMore_Click
	Dim options As List = Array("Capture image", "Image from gallery", "Capture video", "Video from gallery")
	Wait For (B4XPages.MainPage.ShowListDialog(options, True)) Complete (Result As String)
	Select options.IndexOf(Result)
		Case 0
			AddImageFromCamera
		Case 1
			AddImageFromGallery
		Case 2
			AddVideoFromCamera
		Case 3
			AddVideoFromGallery
	End Select
End Sub

Private Sub btnCamera_Click
	AddImageFromCamera
End Sub

Private Sub CreatePostMedia (MediaFile As String, TempFileShouldBeDeleted As Boolean) As PostMedia
	Dim pm As PostMedia
	pm.Initialize
	pm.FileName = MediaFile
	pm.DeleteTempFile = TempFileShouldBeDeleted
	Return pm
End Sub

Private Sub btnOptions_Click
	If PrefDialog.IsInitialized = False Then
		PrefDialog.Initialize(B4XPages.MainPage.Root, "", 250dip, 200dip)
		B4XPages.MainPage.DialogSetLightTheme(PrefDialog.Dialog)
		PrefDialog.LoadFromJson(File.ReadString(File.DirAssets, "PostView.json"))
		PrefDialog.Dialog.BackgroundColor = Constants.DefaultTextBackground
		PrefDialog.Dialog.BorderColor = xui.Color_Transparent
		PrefDialog.Dialog.BorderCornersRadius = 10dip
		
	End If
	Dim rs As Object = PrefDialog.ShowDialog(PostOptions, "Ok", "Cancel")
	B4XPages.MainPage.ViewsCache1.SetClipToOutline(PrefDialog.Dialog.Base) 'apply the round corners to the content
	Wait For (rs) Complete (Success As Int)
	
End Sub

'returns True if the dialog was closed
Public Sub BackKeyPressed As Boolean
	If PrefDialog.IsInitialized And PrefDialog.Dialog.Visible Then
		PrefDialog.Dialog.Close(xui.DialogResponse_Cancel)
		Return True
	End If
	Return False
End Sub