//
//  ARMPlayerInfo.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/2/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARMPlayerInfo : NSObject

+ (id)sharedInstance;
- (BOOL)saveInstanceToArchive;

// Local Player info
@property NSString *playerDisplayName;

@property UIImage *playerDisplayImage;

@property NSString *gameTileBluetoothID;

// Networking Properties
@property NSString *sessionID;

@property NSMutableArray *playersInSession;

@end
