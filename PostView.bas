B4J=true
Group=ListItems
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
	
	Private Medias As List
	Private pnlMedia As B4XView
	Private B4XImageView1 As B4XImageView
	Private InDialog As Boolean
	Private Posting As Boolean
	Private MediaSize As Int = 50dip
	
	Private PrefDialog As PreferencesDialog
	Private PostOptions As Map
	Private MediaChooser1 As MediaChooser
	Private Pane1 As B4XView
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	mBase.LoadLayout("PostView")
	tu = B4XPages.MainPage.TextUtils1
	mCallback = Callback
	mEventName = EventName
	Medias.Initialize
	MediaChooser1 = B4XPages.MainPage.MediaChooser1
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
	Pane1.Visible = Not(InDialog)
	IdempotencyKey = Rnd(0, 0x7FFFFFFF)
	B4XFloatTextField1.Text = ""
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	
	If xui.IsB4i Then
		B4XFloatTextField1.mBase.SetColorAndBorder(xui.Color_Transparent, 1dip, xui.Color_LightGray, 2dip)
	End If
	ArrangeMedias
End Sub

Public Sub SetVisibility (visible As Boolean)
	
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

Private Sub AttachMediaFile (pm As PostMedia)
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	If pm.IsInitialized = False Then Return
	If tu.CheckPostMediaSize (pm) = False Then Return
	If Posting Then Return
	Medias.Add(pm)
	pm.Pnl = xui.CreatePanel("")
	pm.Pnl.SetLayoutAnimated(0, 0, 0, MediaSize + 10dip , MediaSize + 10dip)
	pm.Pnl.LoadLayout("PostViewMedia")
	pm.Pnl.Tag = pm
	If pm.IsImage Then
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
	Dim rs As Object
	Select options.IndexOf(Result)
		Case 0
			rs = MediaChooser1.AddImageFromCamera
		Case 1
			rs = MediaChooser1.AddImageFromGallery (btnCamera)
		Case 2
			rs = MediaChooser1.AddVideoFromCamera 
		Case 3
			#if b4i
			MediaChooser1.AddVideoFromGallery(Me, "AttachMediaFile", btnCamera)
			Return
			#else
			rs = MediaChooser1.AddVideoFromGallery
			#End If
	End Select
	Wait For (rs) Complete (pm As PostMedia)
	AttachMediaFile(pm)
End Sub

Private Sub btnCamera_Click
	Wait For (MediaChooser1.AddImageFromCamera) Complete (pm As PostMedia)
	AttachMediaFile(pm)
	
End Sub

Sub btnGallery_Click
	Wait For (MediaChooser1.AddImageFromGallery (btnCamera)) Complete (pm As PostMedia)
	AttachMediaFile(pm)
End Sub


Private Sub btnOptions_Click
	If PrefDialog.IsInitialized = False Then
		PrefDialog = B4XPages.MainPage.ViewsCache1.CreatePreferencesDialog("PostView.json")
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

Private Sub btnSend_Click
	Post(B4XFloatTextField1.Text)
End Sub