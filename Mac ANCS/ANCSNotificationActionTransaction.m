//
//  ANCSNotificationActionTransaction.m
//  ANCS
//
//  Created by Not XX on 14/11/22.
//  Copyright (c) 2014年 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationActionTransaction.h"
#import "ANCSNotification.h"

#define HEADER_SIZE 5
static uint8_t const kANCSCommandIDPerformNotificationAction = ANCSCommandIDPerformNotificationAction;

@interface ANCSNotificationActionTransaction()

@property (nonatomic, readonly) ANCSNotification* notification;
@property (nonatomic, readonly) ANCSActionId action;

@end

@implementation ANCSNotificationActionTransaction

- (instancetype)initWithNotification:(ANCSNotification *)note action:(ANCSActionId)action {
    if (self = [super init]) {
        _notification = note;
        _action = action;
    }
    return self;
}

#pragma mark - overrides

- (NSInteger)headerLength
{
    return HEADER_SIZE;
}

- (NSData *)buildCommandData
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    [data appendBytes:&kANCSCommandIDPerformNotificationAction length:sizeof(kANCSCommandIDPerformNotificationAction)];
    
    uint32_t notificationId = (uint32_t)[self.notification notificationUid];
    notificationId = CFSwapInt32HostToLittle(notificationId);
    [data appendBytes:&notificationId length:sizeof(notificationId)];
    
    uint8_t actionId = (uint8_t)_action;
    [data appendBytes:&actionId length:sizeof(actionId)];
    
    return [data copy];
}

- (BOOL)needReply {
    return NO;
}

- (id)result {
    return @"OK";
}

@end
