//
//  ANCSNotificationDetailTuple.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationDetailTuple.h"

#define HEADER_SIZE 3

@interface ANCSNotificationDetailTuple ()

@property (nonatomic, strong) NSMutableData *data;

@end

@implementation ANCSNotificationDetailTuple

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		
	}
	return self;
}

- (BOOL)isComplete
{
	return _data != nil && _data.length == self.length;
}


- (NSData *)appendData:(NSData *)data
{
	if(!self.complete)
	{
		if(_data == nil)
		{
			_data = [[NSMutableData alloc] init];
		}
		[self.data appendData:data];
		uint16_t length = self.length;
		if([self.data length] > length)
		{
			NSData *extra = [self.data subdataWithRange:NSMakeRange(length, [self.data length] - length)];
			self.data = [[self.data subdataWithRange:NSMakeRange(0, length)] mutableCopy];
			return extra;
		}
	}
	return nil;
}

- (NSString *)value
{
	NSData *data = [self.data subdataWithRange:NSMakeRange(HEADER_SIZE, [self.data length] - HEADER_SIZE)];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (uint16_t)length
{
	if(self.data == nil)
	{
		return UINT16_MAX;
	}
	if(self.data.length < HEADER_SIZE)
	{
		return UINT16_MAX;
	}
	uint16_t ret;
	[self.data getBytes:&ret range:NSMakeRange(sizeof(uint8_t), sizeof(uint16_t))];
	return CFSwapInt16LittleToHost(ret) + HEADER_SIZE;
}
@end
