//
//  ANCSNotificationDetailTransaction.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSNotificationDetailTransaction.h"
#import "ANCSNotificationDetailTuple.h"
#import "ANCSNotification.h"
#import "ANCSNotificationDetails.h"

static uint8_t const kANCSCommandIDGetNotificationAttributes = 0x0;
static uint16_t const kANCSAttributeMaxLength = 0xffff;
@interface ANCSNotificationDetailTransaction ()

@property (nonatomic, strong) NSMutableDictionary *tuples;
@property (nonatomic, assign) ANCSNotificationDetailTuple *currentTuple;
@property (nonatomic, assign) ANCSNotificationDetailsTypeMask mask;
@property (nonatomic, strong) NSMutableData *accumulatedData;

@end

@implementation ANCSNotificationDetailTransaction

- (instancetype)initWithNotification:(ANCSNotification *)note detailsMask:(ANCSNotificationDetailsTypeMask)mask;
{
	self = [super init];
	if (self)
	{
		_notification = note;
		_tuples = [[NSMutableDictionary alloc] init];
		_mask = mask;
		_accumulatedData = [[NSMutableData alloc] init];
		
	}
	return self;
}


- (NSMutableDictionary *)tuples
{
	if(_tuples == nil)
	{
		_tuples = [[NSMutableDictionary alloc] init];
	}
	return _tuples;
}

- (void)buildTuples:(ANCSNotificationDetailsTypeMask)mask
{
	ANCSNotificationAttributeType type = ANCSNotificationAttributeTypeReserved;
	while(type > 0)
	{
		if(mask & (1 << type))
		{
			ANCSNotificationDetailTuple *tuple = [[ANCSNotificationDetailTuple alloc] init];
			tuple.attributeType = type;
			self.tuples[@(tuple.attributeType)] = tuple;
		}
		type--;
	}
	//special case for 0 value
	if(mask & ANCSNotificationDetailsTypeMaskAppIdentifier)
	{
		ANCSNotificationDetailTuple *tuple = [[ANCSNotificationDetailTuple alloc] init];
		tuple.attributeType = ANCSNotificationAttributeTypeAppIdentifier;
		self.tuples[@(tuple.attributeType)] = tuple;
	}
}

- (NSData *)buildCommandData
{
	[self buildTuples:self.mask];
	NSMutableData *data = [[NSMutableData alloc] init];
	
	[data appendBytes:&kANCSCommandIDGetNotificationAttributes length:sizeof(kANCSCommandIDGetNotificationAttributes)];

	uint32_t notificationId = (uint32_t)[self.notification eventId];
	notificationId = CFSwapInt32HostToLittle(notificationId);
	[data appendBytes:&notificationId length:sizeof(notificationId)];
	
	NSArray *orderedTuples = [self orderedTuples];
	for(ANCSNotificationDetailTuple *tuple in orderedTuples)
	{
		ANCSNotificationAttributeType type = tuple.attributeType;
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
	if(!self.complete)
	{
		[self.accumulatedData appendData:data];
		if([self.accumulatedData length] < 6)
		{
			return;
		}
		if(self.currentTuple == nil)
		{
			ANCSNotificationAttributeType type;
			[self.accumulatedData getBytes:&type range:NSMakeRange(5, 1)];
			self.currentTuple = self.tuples[@(type)];
			data = [data subdataWithRange:NSMakeRange(5, [self.accumulatedData length] - 5)];
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
	if([self.accumulatedData length] < 6)
	{
		return NO;
	}
	__block BOOL complete = YES;
	[[self.tuples allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ANCSNotificationDetailTuple *tuple = (ANCSNotificationDetailTuple *)obj;
		complete = [tuple isComplete];
		if(!complete)
		{
			*stop = YES;
		}
	}];
	return complete;
}

- (ANCSNotificationDetails *)buildDetails
{
	ANCSNotificationDetails *detail = [[ANCSNotificationDetails alloc] init];
	
	NSArray *allTuples = [self orderedTuples];
	for (ANCSNotificationDetailTuple *tuple in allTuples)
	{
		switch (tuple.attributeType) {
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

- (NSArray *)orderedTuples
{
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"attributeType" ascending:YES];
	
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

@end
