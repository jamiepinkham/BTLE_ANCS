//
//  ANCSAppNameTransaction.m
//  ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSAppNameTransaction.h"


static uint8_t const kANCSCommandIDGetAppName = 0x1;
static uint8_t const kANCSAppAttributeIDDisplayName = 0x0;
static uint16_t const kANCSAttributeMaxLength = 0xffff;

@interface ANCSAppNameTransaction ()
{
	NSInteger headerSize;
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
		headerSize = [appIdentifier lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 2;
	}
	return self;
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

- (BOOL)isComplete
{
	return [self.transactionData length] == [self expectedLength];
}

- (NSInteger)expectedLength
{
	if(self.transactionData == nil)
	{
		return UINT16_MAX;
	}
	if(self.transactionData.length < headerSize)
	{
		return UINT16_MAX;
	}
	uint16_t ret;
	[self.transactionData getBytes:&ret range:NSMakeRange(sizeof(uint8_t), sizeof(uint16_t))];
	return CFSwapInt16LittleToHost(ret) + headerSize;
}

- (id)result
{
	NSData *data = [self.transactionData subdataWithRange:NSMakeRange(headerSize, [self.transactionData length] - headerSize)];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
