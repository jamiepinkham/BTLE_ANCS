//
//  ANCSAppNameTransaction.m
//  ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSAppNameTransaction.h"
#import "ANCSDetailTuple.h"
#import "ANCSNotification.h"

static uint8_t const kANCSCommandIDGetAppName = ANCSCommandIDGetAppAttributes;
static uint8_t const kANCSAppAttributeIDDisplayName = 0x0;
static uint16_t const kANCSAttributeMaxLength = 0xffff;

@interface ANCSAppNameTransaction ()
{
	NSDictionary *_tuples;
}

@property (nonatomic, copy) NSString *appIdentifier;

@end

@implementation ANCSAppNameTransaction

-(instancetype)initWithAppIdentifier:(NSString *)appIdentifier
{
	self = [super init];
	if(self)
	{
		_appIdentifier = appIdentifier;
	}
	return self;
}

- (NSInteger)headerLength
{
	return [self.appIdentifier lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 2;
}

-(NSDictionary *)tuples
{
	if(_tuples == nil)
	{
		_tuples =  [self buildTuples];
	}
	return _tuples;
}

- (NSData *)buildCommandData
{
	NSMutableData *ret = [NSMutableData data];
	
	[ret appendBytes:&kANCSCommandIDGetAppName length:sizeof(kANCSCommandIDGetAppName)];
	const char *appIdentifierCString = [self.appIdentifier UTF8String];
	[ret appendBytes:appIdentifierCString length:self.appIdentifier.length + 1];
	[ret appendBytes:&kANCSAppAttributeIDDisplayName length:sizeof(kANCSAppAttributeIDDisplayName)];
	
	return ret;
}

- (NSInteger)expectedLength
{
	if(self.transactionData == nil)
	{
		return UINT16_MAX;
	}
	if(self.transactionData.length < self.headerLength)
	{
		return UINT16_MAX;
	}
	uint16_t ret;
	[self.transactionData getBytes:&ret range:NSMakeRange(sizeof(uint8_t), sizeof(uint16_t))];
	return CFSwapInt16LittleToHost(ret) + self.headerLength;
}

- (id)result
{
	if(self.complete)
	{
        ANCSDetailTuple* currentTuple = self.tuples[@(kANCSAppAttributeIDDisplayName)];
        return currentTuple.value;
	}
	return nil;
}

- (NSDictionary *)buildTuples
{
	ANCSDetailTuple *tuple = [[ANCSDetailTuple alloc] init];
	tuple.attributeIdentifier = kANCSAppAttributeIDDisplayName;
	return @{@(kANCSAppAttributeIDDisplayName) : tuple };
}

@end
