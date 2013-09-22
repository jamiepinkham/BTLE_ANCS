//
//  ANCSNotificationCenter.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationCenter.h"

@implementation ANCSNotificationCenter

- (id)copyWithZone:(NSZone *)zone
{
	ANCSNotificationCenter *copy = [[ANCSNotificationCenter alloc] init];
	copy->_name = self.name;
	copy->_UUID = self.UUID;
	return copy;
}

- (BOOL)isEqual:(id)object
{
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	ANCSNotificationCenter *other = (ANCSNotificationCenter *)object;
	return CFEqual(self.UUID, other.UUID);
}

- (BOOL)isEqualTo:(id)object
{
	return [self isEqual:object];
}

- (NSUInteger)hash
{
	NSString *value = CFBridgingRelease(CFUUIDCreateString(NULL, self.UUID));
	return [value hash];
}

@end
