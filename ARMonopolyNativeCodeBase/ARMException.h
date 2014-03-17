//
//  ARMError.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/16/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *ARMExceptionName;

@interface ARMException : NSException

@property (strong, nonatomic) NSError *errorObject;

+ (id) exceptionWithError:(NSError *)error;

@end
