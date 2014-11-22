//
//  ANCSNotificationDetails.h
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/21/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ANCSNotificationDetails : NSObject

@property (nonatomic, assign) NSUInteger notificationUid;
@property (nonatomic, copy) NSString *appIdentifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *messageSize;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *positionActionLabel;
@property (nonatomic, copy) NSString *negativeActionLabel;

@end
