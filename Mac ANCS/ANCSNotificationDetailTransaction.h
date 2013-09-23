//
//  ANCSNotificationDetailTransaction.h
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCSController.h"
#import  "ANCSTransaction.h"

@interface ANCSNotificationDetailTransaction : ANCSTransaction

- (instancetype)initWithNotification:(ANCSNotification *)note detailsMask:(ANCSNotificationDetailsTypeMask)mask;

@end
