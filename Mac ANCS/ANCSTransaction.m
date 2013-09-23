//
//  ANCSTransaction.m
//  ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSTransaction.h"
#import "ANCSDetailTuple.h"

@interface ANCSTransaction ()

@property (nonatomic, strong) NSMutableData *accumulatedData;
@property (nonatomic, assign) ANCSDetailTuple *currentTuple;

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
	if(self.accumulatedData.length < self.headerLength)
	{
		return;
	}
	if(self.currentTuple == nil)
	{
		uint8_t type;
		[self.accumulatedData getBytes:&type range:NSMakeRange(self.headerLength, 1)];
		self.currentTuple = self.tuples[@(type)];
		data = [data subdataWithRange:NSMakeRange(5, [self.transactionData length] - self.headerLength)];
	}
	NSData *leftOver = [[self currentTuple] appendData:data];
	while(leftOver != nil)
	{
		uint8_t nextType;
		[leftOver getBytes:&nextType length:sizeof(uint8_t)];
		self.currentTuple = self.tuples[@(nextType)];
		leftOver = [[self currentTuple] appendData:leftOver];
	}

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

- (NSError *)error
{
	if(!self.isComplete)
	{
		return [NSError errorWithDomain:@"com.jamiepinkham.ancs" code:-1001 userInfo:@{NSLocalizedDescriptionKey:@"transaction timed out"}];
	}
	if(self.result == nil)
	{
		return [NSError errorWithDomain:@"com.jamiepinkham.ancs" code:-1002 userInfo:@{NSLocalizedDescriptionKey:@"invalid result"}];
	}
	return nil;
}

- (BOOL)isComplete
{
	if([self.transactionData length] < self.headerLength)
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

-(NSUInteger)hash
{
	return [self.identifier hash];
}


@end
