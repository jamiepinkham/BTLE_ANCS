//
//  JPANCSController.h
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>


typedef NS_OPTIONS(NSInteger, ANCSNotificationDetailsTypeMask)
{
	ANCSNotificationDetailsTypeMaskAppIdentifier	=	(1 << 0),
	ANCSNotificationDetailsTypeMaskTitle			=	(1 << 1),
	ANCSNotificationDetailsTypeMaskSubtitle			=	(1 << 2),
	ANCSNotificationDetailsTypeMaskMessage			=	(1 << 3),
	ANCSNotificationDetailsTypeMaskMessageSize		=	(1 << 4),
	ANCSNotificationDetailsTypeMaskDate				=	(1 << 5),
	ANCSNotificationDetailsTypeMaskAll				=	ANCSNotificationDetailsTypeMaskAppIdentifier |
														ANCSNotificationDetailsTypeMaskTitle |
														ANCSNotificationDetailsTypeMaskSubtitle |
														ANCSNotificationDetailsTypeMaskMessage |
														ANCSNotificationDetailsTypeMaskMessageSize |
														ANCSNotificationDetailsTypeMaskDate,
};

typedef NS_ENUM(uint8_t, ANCSNotificationAttributeType)
{
	ANCSNotificationAttributeTypeAppIdentifier = 0,
	ANCSNotificationAttributeTypeTitle = 1,
	ANCSNotificationAttributeTypeSubtitle = 2,
	ANCSNotificationAttributeTypeMessage = 3,
	ANCSNotificationAttributeTypeMessageSize = 4,
	ANCSNotificationAttributeTypeDate = 5,
	ANCSNotificationAttributeTypeReserved = 6,
};

typedef NS_ENUM(uint8_t, ANCSAppAttributeType)
{
	ANCSAppAttributeTypeDisplayName = 0,
};


@protocol ANCSControllerDelegate;
@class ANCSNotification, ANCSNotificationCenter, ANCSNotificationDetails;

@interface ANCSController : NSObject

- (instancetype)initWithDelegate:(id<ANCSControllerDelegate>)delegate queue:(dispatch_queue_t)queue;

- (void)scanForNotificationCenters;
- (void)stopScanning;
- (void)connectToNotificationCenter:(ANCSNotificationCenter *)notificationCenter;
- (void)getAttributesForNotification:(ANCSNotification *)notification detailsMask:(ANCSNotificationDetailsTypeMask)mask notificationCenter:(ANCSNotificationCenter *)notificationCenter;
- (void)getApplicationNameForIdentifier:(NSString *)identifier;

@property (nonatomic, readonly, getter = isScanning) BOOL scanning;

@property (nonatomic, weak) id<ANCSControllerDelegate> delegate;

@end

@protocol ANCSControllerDelegate <NSObject>

- (void)controllerStartedScanningForNotificationCenters:(ANCSController *)controller;
- (void)controller:(ANCSController *)controller failedToStartScan:(NSError *)error;
- (void)controller:(ANCSController *)controller foundNotificationCenter:(ANCSNotificationCenter *)notificationCenter;
- (void)controller:(ANCSController *)controller connectedToNotificationCenter:(ANCSNotificationCenter *)notificationCenter;
- (void)controller:(ANCSController *)controller failedToConnectToNotificationCenter:(ANCSNotificationCenter *)notificationCenter error:(NSError *)error;
- (void)controller:(ANCSController *)controller disconnectedFromNotificationCenter:(ANCSNotificationCenter *)notificationCenter;
- (void)controller:(ANCSController *)controller receivedNotification:(ANCSNotification *)notification notificationCenter:(ANCSNotificationCenter *)notificationCenter;
- (void)controller:(ANCSController *)controller didUpdateNotificationDetails:(ANCSNotificationDetails *)notificationDetails notification:(ANCSNotification *)notification notificationCenter:(ANCSNotificationCenter *)notificationCenter;

@end
