//
//  JPANCSNotificationSource.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotification.h"

@implementation ANCSNotification

- (instancetype)initWithData:(NSData *)data
{
	self = [super init];
	if (self)
	{
		[data getBytes:&_notificationType range:NSMakeRange(0, 1)];
		[data getBytes:&_eventFlags range:NSMakeRange(1, 1)];
		[data getBytes:&_category range:NSMakeRange(2, 1)];
		[data getBytes:&_categoryCount range:NSMakeRange(3, 1)];
		uint32_t eventId;
		[data getBytes:&eventId range:NSMakeRange(4, 4)];
		_eventId = CFSwapInt32LittleToHost(eventId);
	}
	return self;
}

- (BOOL)isEqual:(id)object
{
	return [self isEqualTo:object];
}

- (BOOL)isEqualTo:(id)object
{
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	ANCSNotification *other = (ANCSNotification *)object;
	return [other eventId] == [self eventId];
}

- (NSUInteger)hash
{
	return self.eventId;
}

@end
