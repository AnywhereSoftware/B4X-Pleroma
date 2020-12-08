B4J=true
Group=ListItems
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public mBase As B4XView
	Private xui As XUI
	Private tu As TextUtils
	Private mStatusView As StatusView
	Private mStatus As PLMStatus
	Private BBListItem1 As BBListItem
End Sub

Public Sub Initialize (width As Int)
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, width, 60dip)
	mBase.LoadLayout("ReactionsView")

	tu = B4XPages.MainPage.TextUtils1
	BBListItem1.TextEngine = tu.TextEngine
End Sub

Public Sub SetContent(Content As Object, ListItem As PLMCLVItem)
	mStatusView = Content
	mStatus = mStatusView.mStatus
	mBase.SetColorAndBorder(B4XPages.MainPage.Theme.Background, 0, 0, 1dip)
	Dim reactions As List = B4XPages.MainPage.Settings.GetReactions
	Dim runs As List
	runs.Initialize
	BBListItem1.PrepareBeforeRuns
	runs.Add(tu.TextEngine.CreateRun("  "))
	For Each Emoji As String In reactions
		runs.Add(tu.CreateUrlRun(Emoji, " " & Emoji & " " , BBListItem1.ParseData))
	Next
	Dim fnt As B4XFont = xui.CreateFontAwesome(18)
	For Each r As BCTextRun In runs
		r.TextFont = fnt
	Next
	BBListItem1.SetRuns(runs)
	BBListItem1.UpdateVisibleRegion(0, 1000dip)
End Sub

Public Sub SetVisibility (visible As Boolean)
	
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub

Public Sub BackKeyPressed (OnlyTesting As Boolean) As Boolean
	Return False
End Sub

Private Sub BBListItem1_LinkClicked (URL As String, Text As String)
	If mStatusView.mStatus <> mStatus Then Return
	Dim Emoji As String = URL
	If EmojiAlreadyAdded(Emoji) Then
		
		mStatusView.EmojiClick("~emoji_delete:" & Emoji)
	Else
		mStatusView.EmojiClick("~emoji_put:" & Emoji)
	End If
End Sub

Private Sub EmojiAlreadyAdded (emoji As String) As Boolean
	For Each m As Map In mStatus.EmojiReactions
		If emoji = m.Get("name") Then
			Return True
		End If
	Next
	Return False
End Sub

Public Sub RemoveFromParent
	mBase.RemoveViewFromParent
End Sub