﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private ByteConverter As ByteConverter
	Private ColorsTables As List
	Public Link As Int
	Public DefaultText As Int
	Public Background As Int
	Public SecondBackground As Int
	Public AlreadyTookAction As Int
	Public AttachmentPanelBackground As Int
	Public Divider As Int
	Public NoMoreItemsBackground As Int
	Public OverlayColor As Int
	Public OverlayColorMadeWithLove As Int
	Public PrefSeparatorColor As Int
	Public SecondTextColor As Int
	Public ChatMeBackground As Int
	Public ActionBar As Int
	Public SystemGray3 As Int
	Private CurrentPallete As Map
	Public ReadMoreGradient As B4XBitmap
	Private xui As XUI
	Private bc As BitmapCreator
	Private ThemeChangedTargets As B4XSet
	Private PalleteIndex As Int
	Private FirstTime As Boolean = True
	
End Sub

Public Sub Initialize (json As String)
	Dim bc As BitmapCreator
	bc.Initialize(200, 50)
	ThemeChangedTargets.Initialize
	Dim p As JSONParser
	p.Initialize(json)
	Dim m As Map = p.NextObject
	Dim lightMap As Map = CreateMap()
	Dim darkMap As Map = CreateMap()
	Dim Items As List = m.Get("Items")
	For Each row As Object In Items
		Dim rowAsList As List = row
		Dim key As String = rowAsList.Get(0)
		Dim LightColor As Int = HexToColor(rowAsList.Get(1))
		Dim DarkColor As Int = HexToColor(rowAsList.Get(2))
		lightMap.Put(key, LightColor)
		darkMap.Put(key, DarkColor)
	Next
	ColorsTables = Array(lightMap, darkMap)
	RegisterForEvents(B4XPages.MainPage.Settings)
	SetDark (B4XPages.MainPage.Settings.Dark)
End Sub

Public Sub RegisterForEvents (target As Object)
	ThemeChangedTargets.Add(target)
End Sub

Public Sub getIsDark As Boolean
	Return PalleteIndex = 1
End Sub

Public Sub SetDark (dark As Boolean)
	If dark Then PalleteIndex = 1 Else PalleteIndex = 0
	SetDefaults	
End Sub

Private Sub ThemeChanged
	For Each target As Object In ThemeChangedTargets.AsList
		CallSub(target, "Theme_Changed")
	Next
End Sub

Private Sub SetDefaults
	CurrentPallete = ColorsTables.Get(PalleteIndex)
	Dim clr1, clr2 As Int
	If getIsDark Then
		clr1 = 0
		clr2 = xui.Color_Black
	Else
		clr1 = 0x00FFFFFF
		clr2 = xui.Color_White
	End If
	bc.FillGradient(Array As Int(clr1, clr2), bc.TargetRect, "TOP_BOTTOM")
	ReadMoreGradient = bc.Bitmap
	DefaultText = CurrentPallete.Get("DefaultText")
	Link = CurrentPallete.Get("Link")
	Background = CurrentPallete.Get("Background")
	AlreadyTookAction = CurrentPallete.Get("AlreadyTookAction")
	AttachmentPanelBackground = CurrentPallete.Get("AttachmentPanelBackground")
	AttachmentPanelBackground = CurrentPallete.Get("AttachmentPanelBackground")
	Divider = CurrentPallete.Get("Divider")
	NoMoreItemsBackground = CurrentPallete.Get("NoMoreItemsBackground")
	SecondBackground = CurrentPallete.Get("SecondBackground")
	ActionBar = CurrentPallete.Get("ActionBar")
	OverlayColor = CurrentPallete.Get("OverlayColor")
	OverlayColorMadeWithLove = CurrentPallete.Get("OverlayColorMadeWithLove")
	PrefSeparatorColor = CurrentPallete.Get("PrefSeparatorColor")
	ChatMeBackground = CurrentPallete.Get("ChatMeBackground")
	SecondTextColor = CurrentPallete.Get("SecondTextColor")
	SystemGray3 = CurrentPallete.Get("systemGray3")
	If FirstTime Then
		FirstTime = False
	Else
		ThemeChanged
	End If
End Sub

Private Sub HexToColor(Hex As String) As Int
	If Hex.StartsWith("#") Then
		Hex = Hex.SubString(1)
	Else If Hex.StartsWith("0x") Then
		Hex = Hex.SubString(2)
	Else If Hex.Length = 6 Then
		Hex = "FF" & Hex
	End If
	Dim ints() As Int = ByteConverter.IntsFromBytes(ByteConverter.HexToBytes(Hex))
	Return ints(0)
End Sub

Public Sub ColorToHex(clr As Int) As String
	Dim hex As String = ByteConverter.HexFromBytes(ByteConverter.IntsToBytes(Array As Int(clr)))
	Return "#" & hex.SubString(2) 'remove the alpha channel
End Sub

Public Sub SetFloatTextFieldColor (ft As B4XFloatTextField)
	ft.TextField.TextColor = DefaultText
	If ft.lblClear.IsInitialized Then ft.lblClear.TextColor = DefaultText
	If ft.lblV.IsInitialized Then ft.lblV.TextColor = DefaultText
	#if B4A
	ChangeEditTextLineColor(ft.TextField, 0xFF006FA6, 0xFF006FA6)
	#End If
End Sub

#if B4A
Private Sub ChangeEditTextLineColor (View As View, Active As Int, Enabled As Int)
	Dim States(2,1) As Int
	States(0,0) = 16842908     'Active
	States(1,0) = 16842910    'Enabled
	Dim Color(2) As Int = Array As Int(Active,Enabled)
	Dim CSL As JavaObject
	CSL.InitializeNewInstance("android.content.res.ColorStateList",Array As Object(States,Color))
	Dim jo As JavaObject
	jo.InitializeStatic("android.support.v4.view.ViewCompat")
	jo.RunMethod("setBackgroundTintList", Array(View, CSL))
End Sub
#End If

