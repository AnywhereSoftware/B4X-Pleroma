B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Public Settings As Map
End Sub

Public Sub Initialize
	Settings = File.ReadMap(File.DirApp, "settings.txt")	
End Sub