//
//  ARMNetworkPlayer.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/12/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *kLocalFilenameFormatString;

@interface ARMNetworkPlayer : NSObject

-(id) initWithName:(NSString *)name gameTileImageTargetID:(NSString *)gameTileImageTargetID imageNetworkRelativeURLString:(NSString *)networkRelativeURLString;
@property NSString *playerName;
@property NSString *gameTileImageTargetID;

@property NSString *imageNetworkRelativeURLString;
@property NSString *imageLocalFileName;

@end
