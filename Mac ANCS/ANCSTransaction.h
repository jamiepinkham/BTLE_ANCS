//
//  ANCSTransaction.h
//  ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ANCSTransaction;

typedef void(^ANCSTransactionCompletionBlock)(id result, NSError *error);

typedef NS_ENUM(uint8_t, ANCSTransactionType)
{
	ANCSTransactionTypeNotificationDetails,
	ANCSTransactionTypeAppDetails,
	ANCSTransactionTypeUnknown,
};

@interface ANCSTransaction : NSObject

@property (nonatomic, readonly, getter = isComplete) BOOL complete;
@property (nonatomic, readonly) ANCSTransactionType transactionType;
@property (nonatomic, readonly) NSData *transactionData;
@property (nonatomic, readonly) NSUUID *identifier;
@property (nonatomic, readonly) NSInteger headerLength;
@property (nonatomic, readonly) NSDictionary *tuples;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, copy) ANCSTransactionCompletionBlock completionBlock;

- (NSData *)buildCommandData;

- (void)appendData:(NSData *)data;

- (id)result;

@end