//
//  ARMError.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/16/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMException.h"

const NSString *ARMExceptionName = @"ARMException";

@implementation ARMException

@synthesize errorObject;

+ (id)exceptionWithError:(NSError *)error
{
    ARMException *e = (ARMException *)[super exceptionWithName:[ARMExceptionName copy] reason:[error localizedFailureReason] userInfo:[error userInfo]];
    [e setErrorObject:error];
    return e;
}

@end

