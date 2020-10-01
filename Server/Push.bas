B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Log(req.ContentLength)
	Log(req.ContentType)
	For Each k As String In req.ParameterMap.Keys
		Log(k)
		Dim st() As String = req.ParameterMap.Get(k)
		For Each s As String In st
			Log(s)
		Next
	Next
End Sub