//
//  ARMNetworkPlayer.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/12/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMNetworkPlayer.h"

const NSString *kLocalFilenameFormatString = @"%@.png";

@implementation ARMNetworkPlayer

@synthesize playerName;
@synthesize gameTileImageTargetID;
@synthesize imageLocalFileName;
@synthesize imageNetworkRelativeURLString;

-(id) initWithName:(NSString *)name gameTileImageTargetID:(NSString *)imageTargetID imageNetworkRelativeURLString:(NSString *)networkRelativeURLString
{
    self = [super init];
    if (self) {
        self.playerName = name;
        self.gameTileImageTargetID = imageTargetID;
        self.imageNetworkRelativeURLString = networkRelativeURLString;
        self.imageLocalFileName = [NSString stringWithFormat:[kLocalFilenameFormatString copy], gameTileImageTargetID];
    }
    return self;
}

@end
