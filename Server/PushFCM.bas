B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private API_KEY As String
End Sub

Public Sub Initialize
	API_KEY = Main.Config1.Settings.Get("fcm_key")
End Sub

Public Sub SendMessage(Message As NotificationMessage)
	Dim Job As HttpJob
	Job.Initialize("", Me)
	Dim m As Map = CreateMap("to": $"/topics/${Message.Topic}"$)
	Dim data As Map = CreateMap("title": Message.Title, "body": Message.Body)
	If Message.B4i Then
		Dim iosalert As Map =  CreateMap("title": Message.Title, "body": Message.Body, "sound": "default", "badge": 1)
		m.Put("notification", iosalert)
		m.Put("priority", 10)
		
	End If
	m.Put("data", data)
	Dim jg As JSONGenerator
	jg.Initialize(m)
	Log(jg.ToPrettyString(4))
	Job.PostString("https://fcm.googleapis.com/fcm/send", jg.ToString)
	Job.GetRequest.SetContentType("application/json;charset=UTF-8")
	Job.GetRequest.SetHeader("Authorization", "key=" & API_KEY)
	Wait For (Job) JobDone(Job As HttpJob)
	Log(Job)
	If Job.Success Then
		Log(Job.GetString)
	End If
	Job.Release
End Sub