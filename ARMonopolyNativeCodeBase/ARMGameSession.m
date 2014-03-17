//
//  ARMGameSession.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/14/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMGameSession.h"

@implementation ARMGameSession

@synthesize name;
@synthesize ID;
@synthesize players;

- (id)initWithName:(NSString *)sessionName withID:(NSString *)sessionID
{
    self = [super init];
    if (self)
    {
        [self setName:sessionName];
        [self setID:sessionID];
    }
    return self;
}

@end
