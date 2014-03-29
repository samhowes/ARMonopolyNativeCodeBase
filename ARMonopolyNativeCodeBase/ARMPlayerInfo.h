//
//  ARMPlayerInfo.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/2/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "ARMNetworkViewController.h"

extern const NSString *kDefaultImageFileName;
extern const NSString *kImageFolderName;


@interface ARMPlayerInfo : NSObject

+ (id)sharedInstance;

/* Save the user data to a persistent archive on disk */
- (BOOL)saveInstanceToArchive;

- (BOOL)isReadyToConnectToGameTile;
/* If we have adequate data for use with the game server */
- (BOOL)isReadyForLogin;

- (void)applicationDidLeaveGameSession;

- (void)bluetoothDidConnectToGameTileWithName:(NSString *)name imageTargetID:(NSString *)imageTargetID;

- (void)bluetoothWillConnectToNewGameTile;

// Local Player info
@property NSString *playerDisplayName;

@property UIImage *playerDisplayImage;

@property NSString *gameTileImageTargetID;
@property NSString *gameTileName;

// Networking Properties
@property NSString *sessionName;
@property NSMutableArray *playersInSessionArray;

@end
