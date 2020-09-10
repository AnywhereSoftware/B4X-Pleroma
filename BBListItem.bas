B4J=true
Group=UI
ModulesStructureVersion=1
Type=Class
Version=8.31
@EndOfDesignText@
#Event: LinkClicked (URL As String, Text As String)
Sub Class_Globals
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Public mBase As B4XView 'ignore
	Private xui As XUI 'ignore
	Private mRuns As List
	Private xui As XUI
	Public Style As BCParagraphStyle
	Private mTextEngine As BCTextEngine
	Private mText As String
	Public Paragraph As BCParagraph
	Private TouchPanel As B4XView
	Public Padding As B4XRect
	Public ParseData As BBCodeParseData
	Public Tag As Object
	Private ImageViewsCache As List
	Private UsedImageViews As B4XOrderedMap
	Private StubScrollView As B4XView
	Private RenderIndex As Int
	Public TextIndex As Int
	Private WaitingForDrawing As Boolean
	Private URLToLines As Map
	Type BCURLExtraData (LineS As List)
	Public WordWrap As Boolean = True
	Public LineSpacingFactor As Float = 1
	Private UpdateOffsetY, UpdateHeight As Int
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	ParseData.Initialize
	ParseData.Views.Initialize
	ParseData.URLs.Initialize
	Padding.Initialize(0, 0, 0, 0)
	ParseData.ImageCache.Initialize
	URLToLines.Initialize
	mRuns.Initialize
	ParseData.UrlColor = B4XPages.MainPage.TextUtils1.UrlColor
End Sub

Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	#if B4J
	Dim sp As ScrollPane
	sp.Initialize("sv")
	sp.SetHScrollVisibility("NEVER")
	#else if B4A
	Dim sp As ScrollView
	sp.Initialize2(50dip, "sv")
	#Else If B4i
	Dim sp As ScrollView
	sp.Initialize("sv", mBase.Width, 50dip)
	sp.Bounces = False
	#End If
	StubScrollView = sp
	ImageViewsCache.Initialize
	UsedImageViews = B4XCollections.CreateOrderedMap
	mBase.Tag = Me
	Dim xlbl As B4XView = Lbl
	mText = xlbl.Text
	ParseData.DefaultColor = xlbl.TextColor
	ParseData.DefaultFont = xlbl.Font
	ParseData.ViewsPanel = mBase
	If xui.SubExists(mCallBack, mEventName & "_linkclicked", 2) Then
		TouchPanel = xui.CreatePanel("TouchPanel")
'		TouchPanel.Color = 0x77ff0000
	End If
	#if B4J
	Dim fx As JFX
	ParseData.DefaultBoldFont = fx.CreateFont(Lbl.Font.FamilyName, ParseData.DefaultFont.Size, True, False)
	#Else If B4A
	ParseData.DefaultBoldFont = xui.CreateFont(Typeface.CreateNew(Lbl.Typeface, Typeface.STYLE_BOLD), xlbl.TextSize)
	#else if B4i
	ParseData.DefaultBoldFont = xui.CreateDefaultBoldFont(xlbl.TextSize)
	#End If
End Sub

Public Sub ReleaseInlineImageViews
	For Each iv As B4XView In ParseData.Views.Values
		B4XPages.MainPage.ViewsCache1.ReleaseImageView(iv)
	Next
	ParseData.Views.Clear
End Sub

Public Sub ChangeVisibility(Visible As Boolean)
	For Each iv As B4XView In ParseData.Views.Values
		B4XPages.MainPage.ImagesCache1.SetConsumerVisibility(iv.Tag, Visible)
	Next
	
End Sub


Public Sub Base_Resize (Width As Double, Height As Double)
	
End Sub

Public Sub setTextEngine (b As BCTextEngine)
	mTextEngine = b
	Redraw
End Sub

Public Sub getTextEngine As BCTextEngine
	Return mTextEngine
End Sub


Public Sub PrepareBeforeRuns
	TextIndex = TextIndex + 1
	RenderIndex = RenderIndex + 1
	ParseData.NeedToReparseWhenResize = False
	ParseData.Text = mText
	ParseData.URLs.Clear
	ParseData.Width = (mBase.Width - Padding.Left - Padding.Right)
	ParseData.DefaultColor = Constants.ColorDefaultText
	ParseData.UrlColor = B4XPages.MainPage.TextUtils1.UrlColor
	URLToLines.Clear
	mBase.RemoveAllViews
	If TouchPanel.IsInitialized Then
		mBase.AddView(TouchPanel, 0, 0, 0, 0)
	End If
End Sub

Public Sub SetRuns(Runs As List)
	mRuns = Runs
	Redraw
End Sub

Public Sub getText As String
	Return mText
End Sub

Public Sub UpdateLastVisibleRegion
	UpdateVisibleRegion(UpdateOffsetY, UpdateHeight)
End Sub

Public Sub UpdateVisibleRegion (OffsetY As Int, Height As Int)
	UpdateOffsetY = OffsetY
	UpdateHeight = Height
	RenderIndex = RenderIndex + 1
	Dim MyRenderIndex As Int = RenderIndex
	Dim MyTextIndex As Int = TextIndex
	Do While WaitingForDrawing And MyRenderIndex = RenderIndex
		Sleep(10)
	Loop
	If MyRenderIndex <> RenderIndex Then Return
	Dim foundFirst As Boolean
	Dim Existing As List
	Existing.Initialize
	Existing.AddAll(UsedImageViews.Keys)
	CleanExistingImageViews(True, Existing, OffsetY, Height)
	For Each Line As BCTextLine In Paragraph.TextLines
		If LineIsVisible (Line, OffsetY, Height) Then
			foundFirst = True
			If UsedImageViews.ContainsKey(Line) Then
				Continue
			End If
			Dim xiv As B4XView = GetImageView
			Dim bc As BitmapCreator = mTextEngine.DrawSingleLineAsync(Line, xiv, Paragraph, Me)
			If bc <> Null Then
				WaitingForDrawing = True
				Wait For BC_BitmapReady (bmp As B4XBitmap)
				WaitingForDrawing = False
				B4XPages.MainPage.TextUtils1.TextEngine.ReleaseAsyncBC(bc)
				If MyTextIndex <> TextIndex Then
					xiv.RemoveViewFromParent
					xiv.SetBitmap(Null)
					ImageViewsCache.Add(xiv)
					Return
				End If
				If xui.IsB4J Then
					bmp = bc.Bitmap
				End If
				bmp = bmp.Crop(0, 0, bmp.Width, bmp.Height)
				bc.SetBitmapToImageView(bmp, xiv)
			End If
			UsedImageViews.Put(Line, xiv)
		Else
			If foundFirst Then Exit
		End If
	Next
End Sub

Private Sub GetImageView As B4XView
	Dim xiv As B4XView
	If ImageViewsCache.Size = 0 Then
		Dim iv As ImageView
		iv.Initialize("")
		xiv = iv
	Else
		xiv = ImageViewsCache.Get(ImageViewsCache.Size - 1)
		ImageViewsCache.RemoveAt(ImageViewsCache.Size - 1)
	End If
	mBase.AddView(xiv, 0, 0, 0, 0)
	xiv.SendToBack
	Return xiv
End Sub

Private Sub LineIsVisible(line As BCTextLine, offset As Int, height As Int) As Boolean
	Return line.BaselineY + line.MaxHeightBelowBaseLine >= offset And line.BaselineY - line.MaxHeightAboveBaseLine <= offset + height
End Sub

Private Sub CleanExistingImageViews (InvisibleOnly As Boolean, Existing As List, Offset As Int, Height As Int)
	For Each Line As BCTextLine In Existing
		If InvisibleOnly = False Or LineIsVisible(Line, Offset, Height) = False Then
			Dim xiv As B4XView = UsedImageViews.Get(Line)
			xiv.RemoveViewFromParent
			xiv.SetBitmap(Null)
			ImageViewsCache.Add(xiv)
			If InvisibleOnly = True Then UsedImageViews.Remove(Line)
		End If
	Next
End Sub


Private Sub Redraw
	Dim Style As BCParagraphStyle = mTextEngine.CreateStyle
	Style.Padding = Padding
	Style.MaxWidth = mBase.Width
	Style.ResizeHeightAutomatically = True
	Style.WordWrap = WordWrap
	Style.LineSpacingFactor = LineSpacingFactor
	CleanExistingImageViews(False, UsedImageViews.Keys, 0, 0)
	UsedImageViews.Clear
	Paragraph = mTextEngine.PrepareForLazyDrawing(mRuns, Style, StubScrollView)
	mBase.SetLayoutAnimated(0, mBase.Left, mBase.Top, mBase.Width, Paragraph.Height / mTextEngine.mScale + 5dip)
	For Each run As BCTextRun In ParseData.URLs.Keys
		run.Underline = False
	Next
	If TouchPanel.IsInitialized Then
		TouchPanel.SetLayoutAnimated(0, 0, 0, mBase.Width, mBase.Height)
	End If
End Sub

Private Sub TouchPanel_Touch (Action As Int, X As Float, Y As Float)
	If ParseData.URLs.Size > 0 And URLToLines.Size = 0 Then
		CollectURLs
	End If
	Dim run As BCTextRun = FindTouchedRun(X, Y)
	If run <> Null And ParseData.URLs.ContainsKey(run) Then 
		If Action = TouchPanel.TOUCH_ACTION_UP Then
			Dim url As String = ParseData.Urls.Get(run)
			CallSubDelayed3(mCallBack, mEventName & "_LinkClicked", url, run.Text)
			MarkURL(Null)
		Else If Action = 4 Then 'cancelled (B4i - see main module)
			MarkURL(Null)
		Else
			MarkURL(run)
		End If
		Return
	End If
	MarkURL(Null)
End Sub

Private Sub FindTouchedRun(x As Float, y As Float) As BCTextRun
	For Each offsetx As Int In Array(0, -5dip, 5dip)
		For Each offsety As Int In Array(0, -3dip, 3dip)
			Dim single As BCSingleStyleSection = mTextEngine.FindSingleStyleSection(Paragraph, X + offsetx, Y + offsety)
			If single <> Null Then
				Return single.Run
			End If
		Next
	Next
	Return Null
End Sub



Private Sub MarkURL (Run As BCTextRun)
	For Each r As BCTextRun In URLToLines.Keys
		If r.Underline <> (r = Run) Then
			r.Underline = r = Run
			Dim extra As BCURLExtraData = URLToLines.Get(r)
			For Each line As BCTextLine In extra.Lines
				If UsedImageViews.ContainsKey(line) Then
					mTextEngine.DrawSingleLine(line, UsedImageViews.Get(line), Paragraph)
				End If
			Next
		End If
	Next
End Sub

Private Sub CollectURLs
	For Each line As BCTextLine In Paragraph.TextLines
		For Each un As BCUnbreakableText In line.Unbreakables
			For Each st As BCSingleStyleSection In un.SingleStyleSections
				If ParseData.URLs.ContainsKey(st.Run) Then
					Dim extra As BCURLExtraData
					If URLToLines.ContainsKey(st.Run) = False Then
						extra = CreateBCURLExtraData
						URLToLines.Put(st.Run, extra)
					Else
						extra = URLToLines.Get(st.Run)
					End If
					If extra.Lines.IndexOf(line) = -1 Then
						extra.Lines.Add(line)
					End If
				End If
			Next
		Next
	Next
End Sub


Private Sub CreateBCURLExtraData  As BCURLExtraData
	Dim t1 As BCURLExtraData
	t1.Initialize
	t1.Lines.Initialize
	Return t1
End Sub

#if B4J
Private Sub TouchPanel_MouseExited (EventData As MouseEvent)
	MarkURL(Null)
End Sub
#End If