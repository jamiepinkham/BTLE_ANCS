//
//  ANCSNotificationCenter.h
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANCSNotificationCenter : NSObject <NSCopying>

@property (nonatomic, assign) CFUUIDRef UUID;
@property (nonatomic, copy) NSString *name;

@end
