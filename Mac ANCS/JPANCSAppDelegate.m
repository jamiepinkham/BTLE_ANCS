//
//  JPANCSAppDelegate.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "JPANCSAppDelegate.h"
#import "ANCSController.h"
#import "ANCSNotificationCenter.h"
#import "ANCSNotification.h"
#import "ANCSNotificationDetails.h"

@interface JPANCSAppDelegate () <ANCSControllerDelegate, NSComboBoxDataSource, NSUserNotificationCenterDelegate>

@property (nonatomic, strong) ANCSController *controller;
@property (nonatomic, strong) ANCSNotificationCenter *center;

@end

@implementation JPANCSAppDelegate {
    NSUserNotificationCenter* _default;
    NSMutableDictionary* _notifications;
    NSMutableArray* _delivered;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.controller = [[ANCSController alloc] initWithDelegate:self queue:NULL];
	[self.controller scanForNotificationCenters];
    _uidBox.dataSource = self;
    _default = [NSUserNotificationCenter defaultUserNotificationCenter];
    [_default removeAllDeliveredNotifications];
    _default.delegate = self;
    _notifications = [NSMutableDictionary new];
    _delivered = [NSMutableArray new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       while (YES) {
                           NSMutableArray* values = [_delivered mutableCopy];
                           for (NSUserNotification* exists in _default.deliveredNotifications) {
                               for (NSUserNotification* n in _delivered) {
                                   if ([n.identifier isEqualToString:exists.identifier]) {
                                       [values removeObject:n];
                                   }
                               }
                               [NSThread sleepForTimeInterval:0.20f];
                           }
                           [_delivered removeObjectsInArray:values];
                           dispatch_async(dispatch_get_main_queue(), ^{
                               for (NSUserNotification* n in values) {
                                   [self userNotificationCenter:nil didDismissNotification:n];
                               }
                           });
                       }
                   });
}

- (void)removeButtonClick:(id)sender {
    int index = (int)_uidBox.indexOfSelectedItem;
    if (index < 0 || index >= _center.count) return;
    ANCSNotification* n = [_center notificationAtIndex:index];
    if (!n) return;
    [_controller performAction:ANCSActionIDNegative forNotification:n notificationCenter:_center];
}

- (void)controllerStartedScanningForNotificationCenters:(ANCSController *)controller
{
	NSLog(@"started scanning");
}
- (void)controller:(ANCSController *)controller failedToStartScan:(NSError *)error
{
	NSLog(@"failed to scan");
}
- (void)controller:(ANCSController *)controller foundNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
//	NSLog(@"found notification center = %@", notificationCenter.name);
    [controller connectToNotificationCenter:notificationCenter];
    _center = notificationCenter;
}
- (void)controller:(ANCSController *)controller connectedToNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
//	NSLog(@"connected to notification center = %@", notificationCenter.name);
}
- (void)controller:(ANCSController *)controller failedToConnectToNotificationCenter:(ANCSNotificationCenter *)notificationCenter error:(NSError *)error
{
//	NSLog(@"failed to connect = %@ name = %@", notificationCenter.name, error);
}
- (void)controller:(ANCSController *)controller disconnectedFromNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
//	NSLog(@"disconnected from notification center = %@", notificationCenter.name);
}
- (void)controller:(ANCSController *)controller receivedNotification:(ANCSNotification *)notification notificationCenter:(ANCSNotificationCenter *)notificationCenter
{
	if([notification notificationType] == ANCSEventNotificationTypeRemoved)
	{
//		NSLog(@"removed notification = %@", notification);
        id key = @(notification.notificationUid);
        NSUserNotification* n = _notifications[key];
        if (n) {
            [_delivered removeObject:n];
            [_notifications removeObjectForKey:key];
            [_default removeDeliveredNotification:n];
        }
	}
	else
	{
//		NSLog(@"added notification = %@", notification);
		[controller getAttributesForNotification:notification detailsMask:ANCSNotificationDetailsTypeMaskAll notificationCenter:notificationCenter];
	}
}

- (void)controller:(ANCSController *)controller didUpdateNotificationDetails:(ANCSNotificationDetails *)detail notificationCenter:(ANCSNotificationCenter *)notificationCenter
{
//	NSLog(@"updated details = %@", detail);
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = detail.title;
    if (detail.subtitle)
        notification.subtitle = detail.subtitle;
    notification.informativeText = detail.message;

    notification.identifier = [NSString stringWithFormat:@"%lu", detail.notificationUid];
    if (detail.positionActionLabel && ![@"" isEqualToString:detail.positionActionLabel]) {
        notification.hasActionButton = YES;
        notification.actionButtonTitle = detail.positionActionLabel;
    } else {
        notification.hasActionButton = NO;
    }
    notification.otherButtonTitle = detail.negativeActionLabel;
    [notification setValue:@YES forKey:@"_showsButtons"];
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.userInfo = @{ @"notificationUid": @(detail.notificationUid) };
    _notifications[@(detail.notificationUid)] = notification;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_default deliverNotification:notification];
    });
//    [controller getApplicationNameForIdentifier:detail.appIdentifier onNotificationCenter:notificationCenter];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
    [_delivered addObject:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSDictionary * dic = notification.userInfo;
    if (!dic) return;
    id key = [dic objectForKey:@"notificationUid"];
    if (!key) return;
    ANCSNotification* n = [_center notificationForKey:key];
    if (!n) return;
    switch (notification.activationType) {
        case NSUserNotificationActivationTypeActionButtonClicked:
            [_controller performAction:ANCSActionIDPositive forNotification:n notificationCenter:_center];
            break;
        case NSUserNotificationActivationTypeContentsClicked:
            [_controller performAction:ANCSActionIDNegative forNotification:n notificationCenter:_center];
            break;
        default:
            break;
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissNotification:(NSUserNotification *)notification {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    NSDictionary * dic = notification.userInfo;
    if (!dic) return;
    id key = [dic objectForKey:@"notificationUid"];
    if (!key) return;
    ANCSNotification* n = [_center notificationForKey:key];
    if (!n) return;
    [_controller performAction:ANCSActionIDNegative forNotification:n notificationCenter:_center];
}

- (void)controller:(ANCSController *)controller didRetrieveAppDisplayName:(NSString *)displayName forIdentifier:(NSString *)identifier
{
	
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return _center.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    ANCSNotification* n = [_center notificationAtIndex:index];
    ANCSNotificationDetails* d = [_center.detailMap objectForKey:@(n.notificationUid)];
    if (d)
        return [NSString stringWithFormat:@"%lu %@", n.notificationUid, d.message];
    else
        return [NSString stringWithFormat:@"%lu", n.notificationUid];
}

@end
