//
//  ANCSTransaction.h
//  ANCS
//
//  Created by Jamie Pinkham on 9/22/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>

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

- (NSData *)buildCommandData;

- (void)appendData:(NSData *)data;

- (id)result;

@end
