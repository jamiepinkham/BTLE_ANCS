//
//  ANCSTransaction.m
//  ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSTransaction.h"

@interface ANCSTransaction ()

@property (nonatomic, strong) NSMutableData *accumulatedData;

@end

@implementation ANCSTransaction

- (id)init
{
	self = [super init];
	if(self)
	{
		_accumulatedData = [[NSMutableData alloc] init];
		_identifier = [NSUUID UUID];
	}
	return self;
}

- (NSData *)buildCommandData
{
	NSAssert(NO, @"subclasses should override: %@", NSStringFromSelector(_cmd));
	return nil;
}

-(void)appendData:(NSData *)data
{
	[self.accumulatedData appendData:data];
}

- (NSData *)transactionData
{
	return [self.accumulatedData copy];
}

-(id)result
{
	NSAssert(NO, @"subclasses should override: %@", NSStringFromSelector(_cmd));
	return nil;
}


-(ANCSTransactionType)transactionType
{
	ANCSTransactionType type = ANCSTransactionTypeUnknown;
	if([self.accumulatedData length] >= 3)
	{
		[self.accumulatedData getBytes:&type range:NSMakeRange(0, sizeof(type))];
	}
	return type;
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
	ANCSTransaction *transaction = (ANCSTransaction *)object;
	return [transaction.identifier isEqualTo:self.identifier];
}

@end
