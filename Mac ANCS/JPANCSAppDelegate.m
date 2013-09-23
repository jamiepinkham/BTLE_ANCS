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

@interface JPANCSAppDelegate () <ANCSControllerDelegate>

@property (nonatomic, strong) ANCSController *controller;

@end

@implementation JPANCSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.controller = [[ANCSController alloc] initWithDelegate:self queue:NULL];
	[self.controller scanForNotificationCenters];
}

- (void)controllerStartedScanningForNotificationCenters:(ANCSController *)controller
{
//	NSLog(@"started scanning");
}
- (void)controller:(ANCSController *)controller failedToStartScan:(NSError *)error
{
//	NSLog(@"failed to scan");
}
- (void)controller:(ANCSController *)controller foundNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
//	NSLog(@"found notification center = %@", notificationCenter.name);
	[controller connectToNotificationCenter:notificationCenter];
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
	}
	else
	{
		NSLog(@"added notification = %@", notification);
		[controller getAttributesForNotification:notification detailsMask:ANCSNotificationDetailsTypeMaskAll notificationCenter:notificationCenter];
	}
}

- (void)controller:(ANCSController *)controller didUpdateNotificationDetails:(ANCSNotificationDetails *)notificationDetails notificationCenter:(ANCSNotificationCenter *)notificationCenter
{
	NSLog(@"updated details = %@", notificationDetails);
	[controller getApplicationNameForIdentifier:notificationDetails.appIdentifier onNotificationCenter:notificationCenter];
}

- (void)controller:(ANCSController *)controller didRetrieveAppDisplayName:(NSString *)displayName forIdentifier:(NSString *)identifier
{
	
}


@end
