B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.5
@EndOfDesignText@
'Version 1.00
Sub Class_Globals
	Private NotificationCenter As NativeObject
End Sub

Public Sub Initialize
	NotificationCenter = NotificationCenter.Initialize("UNUserNotificationCenter").RunMethod("currentNotificationCenter", Null)
	NotificationCenter.SetField("delegate", Me)
End Sub




#if OBJC
#import <UserNotifications/UserNotifications.h>
@end
@interface b4i_usernotificationcenter (notification) <UNUserNotificationCenterDelegate>
@end
@implementation b4i_usernotificationcenter (notification)
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
		  B4I* bi = [b4i_main new].bi;
		  NSLog(@"sdsdfsdfsdf");
		NSNumber* n =[bi raiseEvent:nil event:@"usernotification_willpresent:" params:@[notification]];
        completionHandler(n.intValue);
   }
#End If