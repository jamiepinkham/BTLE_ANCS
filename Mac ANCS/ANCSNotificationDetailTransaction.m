//
//  ANCSNotificationDetailTransaction.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationDetailTransaction.h"
#import "ANCSDetailTuple.h"
#import "ANCSNotification.h"
#import "ANCSNotificationDetails.h"

static uint8_t const kANCSCommandIDGetNotificationAttributes = 0x0;
static uint16_t const kANCSAttributeMaxLength = 0xffff;
@interface ANCSNotificationDetailTransaction ()

@property (nonatomic, strong) NSDictionary *tuples;
@property (nonatomic, assign) ANCSDetailTuple *currentTuple;
@property (nonatomic, assign) ANCSNotificationDetailsTypeMask mask;
@property (nonatomic, readonly) ANCSNotification *notification;

@end

@implementation ANCSNotificationDetailTransaction

- (instancetype)initWithNotification:(ANCSNotification *)note detailsMask:(ANCSNotificationDetailsTypeMask)mask;
{
	self = [super init];
	if (self)
	{
		_notification = note;
		_mask = mask;
		
	}
	return self;
}

- (NSDictionary *)tuples
{
	if(_tuples == nil)
	{
		_tuples = [self buildTuples:self.mask];
	}
	return _tuples;
}

#pragma mark - overrides

- (NSData *)buildCommandData
{
	NSMutableData *data = [[NSMutableData alloc] init];
	
	[data appendBytes:&kANCSCommandIDGetNotificationAttributes length:sizeof(kANCSCommandIDGetNotificationAttributes)];

	uint32_t notificationId = (uint32_t)[self.notification eventId];
	notificationId = CFSwapInt32HostToLittle(notificationId);
	[data appendBytes:&notificationId length:sizeof(notificationId)];
	
	NSArray *orderedTuples = [self orderedTuples];
	for(ANCSDetailTuple *tuple in orderedTuples)
	{
		ANCSNotificationAttributeType type = tuple.attributeIdentifier;
		[data appendBytes:&type length:sizeof(ANCSNotificationAttributeType)];
		
		if(type == ANCSNotificationAttributeTypeTitle || type == ANCSNotificationAttributeTypeSubtitle || type == ANCSNotificationAttributeTypeMessage)
		{
			[data appendBytes:&kANCSAttributeMaxLength length:sizeof(kANCSAttributeMaxLength)];
		}
	}
	
	return [data copy];
}

- (void)appendData:(NSData *)data
{
	[super appendData:data];
	if(!self.complete)
	{
		if([self.transactionData length] < 6)
		{
			return;
		}
		if(self.currentTuple == nil)
		{
			ANCSNotificationAttributeType type;
			[self.transactionData getBytes:&type range:NSMakeRange(5, 1)];
			self.currentTuple = self.tuples[@(type)];
			data = [data subdataWithRange:NSMakeRange(5, [self.transactionData length] - 5)];
		}
		NSData *leftOver = [[self currentTuple] appendData:data];
		while(leftOver != nil)
		{
			ANCSNotificationAttributeType nextType;
			[leftOver getBytes:&nextType length:sizeof(ANCSNotificationAttributeType)];
			self.currentTuple = self.tuples[@(nextType)];
			leftOver = [[self currentTuple] appendData:leftOver];
		}
	}
}

-(BOOL)isComplete
{
	if([self.transactionData length] < 6)
	{
		return NO;
	}
	__block BOOL complete = YES;
	[[self.tuples allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ANCSDetailTuple *tuple = (ANCSDetailTuple *)obj;
		complete = [tuple isComplete];
		if(!complete)
		{
			*stop = YES;
		}
	}];
	return complete;
}

- (id)result
{
	ANCSNotificationDetails *detail = [[ANCSNotificationDetails alloc] init];
	uint32_t notificationId;
	[self.transactionData getBytes:&notificationId range:NSMakeRange(1, sizeof(uint32_t))];
	detail.notificationId = CFSwapInt32LittleToHost(notificationId);
	NSArray *allTuples = [self orderedTuples];
	for (ANCSDetailTuple *tuple in allTuples)
	{
		switch (tuple.attributeIdentifier) {
			case ANCSNotificationAttributeTypeMessage:
				detail.message = [tuple value];
				break;
			case ANCSNotificationAttributeTypeAppIdentifier:
				detail.appIdentifier = [tuple value];
				break;
			case ANCSNotificationAttributeTypeDate:
			{
				NSString *dateString = [tuple value];
				NSDate *date = [self.dateFormatter dateFromString:dateString];
				detail.date = date;
			}
				break;
			case ANCSNotificationAttributeTypeMessageSize:
				detail.messageSize = [tuple value];
				break;
			case ANCSNotificationAttributeTypeSubtitle:
				detail.subtitle = [tuple value];
				break;
			case ANCSNotificationAttributeTypeTitle:
				detail.title = [tuple value];
				break;
			default:
				break;
		}
	}
	
	return detail;
}

#pragma mark - helpers

- (NSArray *)orderedTuples
{
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"attributeIdentifier" ascending:YES];
	
	NSArray *orderedTuples = [[self.tuples allValues] sortedArrayUsingDescriptors:@[sort]];
	
	return orderedTuples;
}

static NSDateFormatter *formatter = nil;
- (NSDateFormatter *)dateFormatter
{
	if(formatter == nil)
	{
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyyMMdd'T'HHmmSS"];
	}
	return formatter;
}

- (NSDictionary *)buildTuples:(ANCSNotificationDetailsTypeMask)mask
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	NSInteger type = ANCSNotificationAttributeTypeReserved;
	while(type >= 0)
	{
		if(mask & (1 << type))
		{
			ANCSDetailTuple *tuple = [[ANCSDetailTuple alloc] init];
			tuple.attributeIdentifier = type;
			dict[@(tuple.attributeIdentifier)] = tuple;
		}
		type--;
	}
	return [dict copy];
}

@end
