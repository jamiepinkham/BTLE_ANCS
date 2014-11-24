//
//  ANCSNotificationCenter.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationCenter.h"

@implementation ANCSNotificationCenter {
    NSMutableArray* _notifications;
    NSMutableDictionary* _notificationMap;
}

- (instancetype)init {
    if (self = [super init]) {
        _notifications = [NSMutableArray new];
        _notificationMap = [NSMutableDictionary new];
        _detailMap = [NSMutableDictionary new];
    }
    return self;
}

- (void)setNotification:(ANCSNotification *)notification forKey:(id<NSCopying>)key {
    ANCSNotification* old = _notificationMap[key];
    if (old ) {
        NSUInteger index = [_notifications indexOfObject:old];
        [_notifications replaceObjectAtIndex:index withObject:notification];
    } else {
        [_notifications addObject:notification];
    }
    [_notificationMap setObject:notification forKey:key];
}

- (ANCSNotification *)notificationForKey:(id)key {
    return [_notificationMap objectForKey:key];
}

- (ANCSNotification *)notificationAtIndex:(NSUInteger)index {
    return [_notifications objectAtIndex:index];
}

- (void)removeNotificationForKey:(id)key {
    ANCSNotification* old = [_notificationMap objectForKey:key];
    if (old) {
        [_notifications removeObject:old];
        [_notificationMap removeObjectForKey:key];
    }
}

- (NSUInteger)count {
    return _notifications.count;
}

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
