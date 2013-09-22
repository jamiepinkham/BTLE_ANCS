//
//  ANCSNotificationDetailTransaction.h
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCSController.h"

@interface ANCSNotificationDetailTransaction : NSObject

- (instancetype)initWithNotification:(ANCSNotification *)note detailsMask:(ANCSNotificationDetailsTypeMask)mask;

@property (nonatomic, readonly) ANCSNotification *notification;
@property (nonatomic, readonly, getter = isComplete) BOOL complete;

- (NSData *)buildCommandData;

- (void)appendData:(NSData *)data;

- (ANCSNotificationDetails *)buildDetails;

@end
