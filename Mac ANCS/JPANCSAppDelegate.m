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

@interface JPANCSAppDelegate () <ANCSControllerDelegate, NSComboBoxDataSource>

@property (nonatomic, strong) ANCSController *controller;
@property (nonatomic, strong) NSMutableArray* notifications;
@property (nonatomic, strong) NSMutableDictionary* details;
@property (nonatomic, strong) ANCSNotificationCenter *center;

@end

@implementation JPANCSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.controller = [[ANCSController alloc] initWithDelegate:self queue:NULL];
	[self.controller scanForNotificationCenters];
    _notifications = [NSMutableArray new];
    _details = [NSMutableDictionary new];
    _uidBox.dataSource = self;
}

- (void)removeButtonClick:(id)sender {
    int index = (int)_uidBox.indexOfSelectedItem;
    if (index < 0 || index >= _notifications.count) return;
    ANCSNotification* n = _notifications[index];
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
		NSLog(@"removed notification = %@", notification);
        [_notifications removeObject:notification];
	}
	else
	{
		NSLog(@"added notification = %@", notification);
        [_notifications addObject:notification];
		[controller getAttributesForNotification:notification detailsMask:ANCSNotificationDetailsTypeMaskAll notificationCenter:notificationCenter];
	}
}

- (void)controller:(ANCSController *)controller didUpdateNotificationDetails:(ANCSNotificationDetails *)notificationDetails notificationCenter:(ANCSNotificationCenter *)notificationCenter
{
	NSLog(@"updated details = %@", notificationDetails);
    [_details setObject:notificationDetails forKey:@(notificationDetails.notificationUid)];
	[controller getApplicationNameForIdentifier:notificationDetails.appIdentifier onNotificationCenter:notificationCenter];
}

- (void)controller:(ANCSController *)controller didRetrieveAppDisplayName:(NSString *)displayName forIdentifier:(NSString *)identifier
{
	
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return _notifications.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    ANCSNotification* n = _notifications[index];
    ANCSNotificationDetails* d = [_details objectForKey:@(n.notificationUid)];
    if (d)
        return [NSString stringWithFormat:@"%lu %@", n.notificationUid, d.message];
    else
        return [NSString stringWithFormat:@"%lu", n.notificationUid];
}

@end
