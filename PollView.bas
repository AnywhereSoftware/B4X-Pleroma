B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.87
@EndOfDesignText@
Sub Class_Globals
	Private xui As XUI
	Private Label1 As B4XView
	Private CustomListView1 As CustomListView
	Private btnVote As B4XView
	Public mBase As B4XView
	Private selections As CLVSelections
	Private mPoll As PLMPoll
	Private mTheme As ThemeManager
	Private UserCanVote As Boolean
	Private mStatus As PLMStatus
	Private tu As TextUtils
End Sub

Public Sub Initialize
	mBase = xui.CreatePanel("")
	mBase.SetLayoutAnimated(0, 0, 0, 100dip, 100dip)
	mBase.LoadLayout("PollView")
	selections.Initialize(CustomListView1)
	mTheme = B4XPages.MainPage.Theme
	mTheme.RegisterForEvents(Me)
	tu = B4XPages.MainPage.TextUtils1
	mBase.Tag = Me
	CustomListView1.AsView.Color = xui.Color_Transparent
	CustomListView1.sv.ScrollViewInnerPanel.Color = xui.Color_Transparent
	Theme_Changed
End Sub

Private Sub Theme_Changed
	Label1.TextColor = mTheme.DefaultText
	
End Sub

Public Sub SetContent (Status As PLMStatus, Width As Int)
	mBase.Width = Width
	CustomListView1.AsView.Width = Width
	CustomListView1.sv.Width = Width
	CustomListView1.Base_Resize(Width, mBase.Height)
	CustomListView1.Clear
	selections.SelectedItems.Clear
	mStatus = Status
	mPoll = Status.Poll
	If mPoll.Multiple Then selections.Mode = selections.MODE_MULTIPLE_ITEMS Else selections.Mode = selections.MODE_SINGLE_ITEM_PERMANENT
	UserCanVote = B4XPages.MainPage.User.SignedIn And mPoll.UserVoted = False And mPoll.Expired = False
	For Each m As Map In mPoll.Options
		Dim title As String = m.GetDefault("title", "N/A")
		Dim count As Int = m.GetDefault("votes_count", 0)
		Dim item As B4XView = xui.CreatePanel("")
		item.SetLayoutAnimated(0, 0, 0, Width, 40dip)
		Dim index As Int = CustomListView1.Size
		CustomListView1.Add(item, "")
		Dim text As B4XView = CreateLabel(title)
		text.Font = xui.CreateDefaultBoldFont(14)
		Dim left As Int = 4dip
		Dim top As Int = 2dip
		Dim height As Int = item.Height - 4dip
		If UserCanVote Then
			item.AddView(text, left, top, item.Width - 4dip, height)
		Else
			Dim ratio As Float
			If mPoll.VotesCount > 0 Then ratio = count / mPoll.VotesCount
			If count > 0 Then
				Dim p As B4XView = xui.CreatePanel("")
				p.SetColorAndBorder(mTheme.SystemGray3, 0, 0, 20dip)
				item.AddView(p, 2dip, top, (Width - 4dip) * ratio, height)
			End If
			If mPoll.OwnVotes.IndexOf(index) > -1 Then
				Dim v As B4XView = CreateLabel(Chr(0xF00C))
				v.Font = xui.CreateFontAwesome(14)
				item.AddView(v, left, top, 20dip, height)
				left = left + 22dip
			End If
			Dim per As B4XView = CreateLabel($"$1.0{ratio * 100}%"$)
			item.AddView(per, left, top, 40dip, height)
			left = left + 42dip
			item.AddView(text, left, 2dip, item.Width - left, height)
		End If
	Next
	CustomListView1.AsView.Height = CustomListView1.sv.ScrollViewContentHeight
	CustomListView1.Base_Resize(Width, CustomListView1.AsView.Height)
	mBase.Height = CustomListView1.AsView.Height + 45dip
	
	btnVote.Visible = UserCanVote
	Dim EndsText As String
	If mPoll.Expired Then
		EndsText = "poll expired"
	Else
		Dim t As String = B4XPages.MainPage.TextUtils1.TicksToTimeString(DateTime.Now - (mPoll.ExpiresAt - DateTime.Now), True)
		If t = "now" Then t = "a few seconds"
		EndsText = $"poll ends in ${t}"$
	End If
	Dim msg As String
	If UserCanVote Then
		msg = EndsText
		If mPoll.Multiple Then
			msg = msg & " (multiple choices)"
		Else
			msg = msg & " (single choice)"
		End If
	Else
		msg = $"${mPoll.VotesCount} vote(s) - "$ & EndsText
	End If
	Label1.SetLayoutAnimated(0, 2dip, mBase.Height - Label1.Height, mBase.Width - 64dip, Label1.Height)
	btnVote.Top = mBase.Height - btnVote.Height
	btnVote.Left = mBase.Width - 2dip - btnVote.Width
	Label1.Text = msg
	btnVote.Enabled = False
End Sub

Private Sub CreateLabel(Text As String) As B4XView
	Dim per As B4XView = XUIViewsUtils.CreateLabel
	per.SetTextAlignment("CENTER", "LEFT")
	per.TextColor = mTheme.DefaultText
	per.Font = xui.CreateDefaultFont(14)
	per.Text = Text
	Return per
End Sub

Private Sub CustomListView1_ItemClick (Index As Int, Value As Object)
	If UserCanVote Then
		selections.ItemClicked(Index)
		btnVote.Enabled = selections.SelectedItems.Size > 0
	End If
End Sub

Private Sub btnVote_Click
	If UserCanVote = False Then Return
	Dim j As HttpJob = tu.CreateHttpJob(Me, btnVote, True)
	If j = Null Then Return
	Dim link As String = B4XPages.MainPage.GetServer.URL & $"/api/v1/polls/${mPoll.Id}/votes"$
	Dim jg As JSONGenerator
	jg.Initialize(CreateMap("choices": selections.SelectedItems.AsList))
	j.PostString(link, jg.ToString)
	B4XPages.MainPage.auth.AddAuthorization(j)
	j.GetRequest.SetContentType("application/json")
	Wait For (j) JobDone (j As HttpJob)
	If j.Success Then
		Dim poll As PLMPoll = tu.CreatePoll(tu.JsonParseMap(j.GetString))
		If poll.IsInitialized Then
			mStatus.Poll = poll
			SetContent(mStatus, mBase.Width)		
		End If
	Else
		B4XPages.MainPage.ShowMessage("Failed to submit vote: " & j.ErrorMessage)
	End If
	j.Release
	B4XPages.MainPage.HideProgress
End Sub

Public Sub Release
	mBase.RemoveViewFromParent
	B4XPages.MainPage.ViewsCache1.ReleasePollView(Me)
End Sub