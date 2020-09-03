B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
#Event: LinkClicked (Link As PLMLink)
Sub Class_Globals
	Private mCallback As Object
	Private mEventName As String	
	Public ImageView1 As B4XView
	Private BBListItem1 As BBListItem
	Public base As B4XView
	Private xui As XUI
	Private pnlImageView As B4XView
	Private url As String
	Private pnlTouch As B4XView
End Sub

Public Sub Initialize
	base = xui.CreatePanel("")
	base.SetLayoutAnimated(0, 0, 0, 100dip, 80dip)
	base.LoadLayout("CardView")
	B4XPages.MainPage.SetImageViewTag(ImageView1)
	BBListItem1.TextEngine = B4XPages.MainPage.TextUtils1.TextEngine
	BBListItem1.LineSpacingFactor = 0.2
	base.Tag = Me
	base.SetColorAndBorder(0, 1dip, 0xFFCDCDCD, 5dip)
	#if B4A
	Dim jo As JavaObject = base
	jo.RunMethod("setClipToOutline", Array(True))
	#end if
End Sub

Public Sub SetCard (card As Map, Callback As Object, EventName As String, Attachments As List)
	mCallback = Callback
	mEventName = EventName
	pnlImageView.Color = 0
	base.Parent.Color = xui.Color_White
	url = card.Get("url")
	base.Width = base.Parent.Width
	Dim imageurl As String
	If card.GetDefault("image", Null) <> Null Then
		imageurl = card.Get("image")
		For Each attach As PLMMedia In Attachments
			If attach.Url = imageurl Then
				Log("same image in card")
				imageurl = ""
			End If
		Next
	End If
	pnlImageView.Visible = imageurl <> ""
	If pnlImageView.Visible Then
		Dim ic As ImagesCache = B4XPages.MainPage.ImagesCache1
		ic.SetImage(imageurl, ImageView1.Tag, ic.RESIZE_FILL_NO_DISTORTIONS)
		BBListItem1.mBase.Left = pnlImageView.Left + pnlImageView.Width + 5dip
	Else
		BBListItem1.mBase.Left = 5dip
	End If
	BBListItem1.mBase.Width = base.Width - BBListItem1.mBase.Left - 5dip
	BBListItem1.PrepareBeforeRuns
	pnlTouch.SetLayoutAnimated(0, 0, 0, base.Width, base.Height)
	Dim runs As List
	runs.Initialize
	Dim tu As TextUtils = B4XPages.MainPage.TextUtils1
	Dim r As BCTextRun = tu.CreateRun(card.Get("provider_name") & CRLF, xui.CreateDefaultFont(9))
	r.TextColor = Constants.ColorDefaultText
	runs.Add(r)
	runs.Add(tu.CreateRun(card.Get("title") & CRLF, xui.CreateDefaultBoldFont(12)))
	runs.Add(tu.CreateRun(card.Get("description"), xui.CreateDefaultFont(11)))
	BBListItem1.SetRuns(runs)
	If pnlImageView.Visible = False Then
		base.Height = BBListItem1.mBase.Height + 4dip
	Else
		base.Height = Max(80dip, BBListItem1.mBase.Height + 4dip)
	End If
	base.Height = Min(base.Height, 120dip)
	pnlTouch.Height = base.Height
	pnlImageView.Height = base.Height
	If xui.IsB4J Then pnlImageView.Height = base.Height - 6dip
End Sub

Public Sub Release
	base.RemoveViewFromParent
	B4XPages.MainPage.ImagesCache1.ReleaseImage(ImageView1.Tag)
	BBListItem1.ReleaseInlineImageViews
	B4XPages.MainPage.ViewsCache1.ReleaseCardView(Me)
End Sub

Public Sub SetVisibility (Visible As Boolean)
	If Visible Then
		BBListItem1.UpdateVisibleRegion(0, 10000)
	End If
End Sub

#if B4J
Sub pnlTouch_MouseClicked (EventData As MouseEvent)
#else
Private Sub pnlTouch_Click
#end if
	CallSub2(mCallback, mEventName & "_LinkClicked", B4XPages.MainPage.TextUtils1.CreatePLMLink(url, B4XPages.MainPage.LINKTYPE_OTHER, url))
End Sub