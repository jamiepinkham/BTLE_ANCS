//
//  ANCSNotificationDetails.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/21/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationDetails.h"


@implementation ANCSNotificationDetails

- (NSString *)description
{
	NSMutableString *ret = [[NSMutableString alloc] init];
	[ret appendFormat:@"{\n\t appIdentifier : %@",self.appIdentifier];
	[ret appendFormat:@"\n\t notificationId : %hu", self.notificationId];
	[ret appendFormat:@"\n\t title : %@", self.title];
	[ret appendFormat:@"\n\t subtitle : %@", self.subtitle];
	[ret appendFormat:@"\n\t message : %@", self.message];
	[ret appendFormat:@"\n\t messageSize : %@", self.messageSize];
	[ret appendFormat:@"\n\t date : %@", self.date];
    [ret appendFormat:@"\n\t positionAction : %@", self.positionActionLabel];
    [ret appendFormat:@"\n\t negativeAction : %@", self.negativeActionLabel];
	[ret appendFormat:@"\n}"];
	return ret;
}

@end
