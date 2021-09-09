B4J=true
Group=Text
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mTextEngine As BCTextEngine
	Private mHtmlParser As MiniHtmlParser
	Private mData As BBCodeParseData
	Private Runs As List
	Private Depth As Int
	Private mEmojis As List
	Private ToTextSB As StringBuilder
End Sub

Public Sub Initialize (TextEngine As BCTextEngine, HtmlParser As MiniHtmlParser)
	mTextEngine = TextEngine
	mHtmlParser = HtmlParser
End Sub

Public Sub ConvertHtmlToRuns (Content As PLMContent, Data As BBCodeParseData, Emojis As List) As List
	Runs.Initialize
	mData = Data
	Depth = 0
	mEmojis = Emojis
	ImplConvertHtmlToRuns(Content.RootHtmlNode, False)
	If Content.TextDirection = mTextEngine.TextDirectionRTL Then
		For Each run As BCTextRun In Runs
			run.HorizontalAlignment = "right"
		Next
	End If
	Return Runs
End Sub

Public Sub ConvertHtmlToText (Parent As HtmlNode, Emojis As List) As String
	ToTextSB.Initialize
	ImplConvertHtmlToRuns(Parent, True)
	Return ToTextSB.ToString
End Sub

Private Sub ImplConvertHtmlToRuns (Parent As HtmlNode, ToText As Boolean)
	If (Parent.Name = "p" And Runs.Size > 0) Or Parent.Name = "br" Then
		If ToText Then
			ToTextSB.Append(CRLF)
		Else
			Runs.Add(mTextEngine.CreateRun(CRLF))
		End If
		If Parent.Name = "br" Then Return
	End If
	If Parent.Children.Size = 0 Or Parent.Name = "a" Then
		HandleLeaf(Parent, ToText)
	Else
		Depth = Depth + 1
		For Each c As HtmlNode In Parent.Children
			ImplConvertHtmlToRuns(c, ToText)
		Next
		Depth = Depth - 1
	End If
End Sub

Private Sub HandleLeaf (Leaf As HtmlNode, ToText As Boolean)
	Dim Text As String
	Dim sb As StringBuilder
	sb.Initialize
	GetAllTextElements(Leaf, sb)
	Text = sb.ToString
	If Leaf.Name = "text" And mEmojis.IsInitialized Then
		If ToText Then
			ToTextSB.Append(Text)
		Else
			B4XPages.MainPage.TextUtils1.TextWithEmojisToRuns(Text, Runs, mEmojis, mData, mData.DefaultFont)
		End If
		Return
	End If

	Try
		If ToText Then
			ToTextSB.Append(Text)
		Else
			Dim Run As BCTextRun = mTextEngine.CreateRun(Text)
			Run.TextColor = mData.DefaultColor
			Run.TextFont = mData.DefaultFont
			Runs.Add(Run)
			If Leaf.Name = "a" Then
				mData.URLs.Put(Run, mHtmlParser.GetAttributeValue(Leaf, "href", ""))
				Run.Underline = True
				Run.TextColor = mData.UrlColor
			End If
		End If
		
	Catch
		Log("*****    Handle Leaf Error ****: " & Text)
		Log(LastException)
	End Try
End Sub



Private Sub GetText (TextElement As HtmlNode) As String
	Return mHtmlParser.UnescapeEntities(mHtmlParser.GetAttributeValue(TextElement, "value", ""))
End Sub

Private Sub GetAllTextElements (Parent As HtmlNode, sb As StringBuilder)
	If Parent.Name = "text" Then
		sb.Append(GetText(Parent))
	Else
		For Each child As HtmlNode In Parent.Children
			GetAllTextElements(child, sb)
		Next
	End If
End Sub

