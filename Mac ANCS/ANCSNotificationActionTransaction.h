//
//  ANCSNotificationActionTransaction.h
//  ANCS
//
//  Created by Not XX on 14/11/22.
//  Copyright (c) 2014年 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCSController.h"
#import "ANCSTransaction.h"

@interface ANCSNotificationActionTransaction : ANCSTransaction

- (instancetype)initWithNotification:(ANCSNotification *)note action:(ANCSActionId)action;

@end
