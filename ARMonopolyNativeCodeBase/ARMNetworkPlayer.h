//
//  ARMNetworkPlayer.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/12/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARMNetworkPlayer : NSObject

-(id) initWithName:(NSString *)name gameTileImageTargetID:(NSNumber *)gameTileImageTargetID imageNetworkURL:(NSURL *)imageNetworkURL;

@property NSString *playerName;
@property NSNumber *gameTileImageTargetID;

@property NSURL *imageNetworkURL;
@property NSURL *imageLocalURL;

@end
