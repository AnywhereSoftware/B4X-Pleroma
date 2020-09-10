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
	Private B4XFloatTextField1 As B4XFloatTextField
	Public mReplyToId As String
	Private IdempotencyKey As String
	Private tu As TextUtils
	Private mCallback As Object
	Private mEventName As String
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, Width, 200dip)
	mBase.LoadLayout("PostView")
	tu = B4XPages.MainPage.TextUtils1
	mCallback = Callback
	mEventName = EventName
End Sub

Public Sub SetContent(Content As PLMPost, ListItem As PLMCLVItem)
	mReplyToId = Content.ReplyId
	IdempotencyKey = Rnd(0, 0x7FFFFFFF)
	B4XFloatTextField1.Text = ""
	B4XFloatTextField1.RequestFocusAndShowKeyboard
	B4XFloatTextField1.lblV.Font = xui.CreateMaterialIcons(24)
	B4XFloatTextField1.lblV.Text = Chr(0xE163)
	If xui.IsB4i Then
		B4XFloatTextField1.mBase.SetColorAndBorder(xui.Color_Transparent, 1dip, xui.Color_LightGray, 2dip)
	End If
End Sub

Public Sub SetVisibility (visible As Boolean)
	
End Sub

Private Sub btnSubmit_Click
	Post(B4XFloatTextField1.Text)
End Sub

Private Sub Post (status As String)
	If status.Trim = "" Then Return
	Dim j As HttpJob = tu.CreateHttpJob(Me, mBase)
	If j = Null Then Return
	Dim params As Map = CreateMap("status": status)
	If mReplyToId <> "" Then params.Put("in_reply_to_id", mReplyToId)
	params.Put("visibility", "public")
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
			CallSub2(mCallback, mEventName & "_NewPost", st)
		End If
	End If
	j.Release
End Sub

Public Sub RemoveFromParent
	mBase.RemoveViewFromParent
End Sub

Private Sub btnCancel_Click
	CallSub(mCallback, mEventName & "_Close")
End Sub

Private Sub B4XFloatTextField1_EnterPressed
	btnSubmit_Click
End Sub