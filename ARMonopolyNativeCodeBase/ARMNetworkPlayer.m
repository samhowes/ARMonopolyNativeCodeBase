//
//  ARMNetworkPlayer.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/12/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMNetworkPlayer.h"

@implementation ARMNetworkPlayer

@synthesize playerName;
@synthesize gameTileImageTargetID;
@synthesize imageLocalURL;
@synthesize imageNetworkURL;

-(id) initWithName:(NSString *)name gameTileImageTargetID:(NSNumber *)gameTileImageTargetID imageNetworkURL:(NSURL *)imageNetworkURL
{
    self = [super init];
    if (self) {
        self.playerName = name;
        self.gameTileImageTargetID = gameTileImageTargetID;
        self.imageNetworkURL = imageNetworkURL;
    }
    return self;
}

@end
