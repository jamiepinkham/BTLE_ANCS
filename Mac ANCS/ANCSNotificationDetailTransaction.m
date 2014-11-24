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

static uint8_t const kANCSCommandIDGetNotificationAttributes = ANCSCommandIDGetNotificationAttributes;
static uint16_t const kANCSAttributeMaxLength = 0xffff;
#define HEADER_SIZE 5

@interface ANCSNotificationDetailTransaction ()
{
	NSDictionary *_tuples;
}

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
		_tuples =  [self buildTuples:self.mask];
	}
	return _tuples;
}

#pragma mark - overrides

- (NSInteger)headerLength
{
	return HEADER_SIZE;
}

- (NSData *)buildCommandData
{
	NSMutableData *data = [[NSMutableData alloc] init];
	
	[data appendBytes:&kANCSCommandIDGetNotificationAttributes length:sizeof(kANCSCommandIDGetNotificationAttributes)];

	uint32_t notificationId = (uint32_t)[self.notification notificationUid];
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


- (id)result
{
	if(self.complete)
	{
		ANCSNotificationDetails *detail = [[ANCSNotificationDetails alloc] init];
		uint32_t notificationId;
		[self.transactionData getBytes:&notificationId range:NSMakeRange(1, sizeof(uint32_t))];
		detail.notificationUid = CFSwapInt32LittleToHost(notificationId);
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
                case ANCSNotificationAttributeTypePositiveActionLabel:
                    detail.positionActionLabel = [tuple value];
                    break;
                case ANCSNotificationAttributeTypeNegativeActionLabel:
                    detail.negativeActionLabel = [tuple value];
                    break;
				default:
					break;
			}
		}
		
		return detail;
	}
	return nil;
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
