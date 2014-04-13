//
//  ARMPlayerInfo.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/2/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *kDefaultImageFileName;
extern const NSString *kImageFolderName;
extern const NSString *kAvatarImageFilenameFormatString;

@interface ARMPlayerInfo : NSObject

+ (id)sharedInstance;

/* Save the user data to a persistent archive on disk */
- (BOOL)saveInstanceToArchive;

- (BOOL)isReadyToConnectToGameTile;
/* If we have adequate data for use with the game server */
- (BOOL)isReadyForLogin;

- (void)bluetoothDidConnectToGameTileWithName:(NSString *)name imageTargetID:(NSString *)imageTargetID;

- (void)bluetoothWillConnectToNewGameTile;

- (void)networkingDidLogInWithCookie:(NSHTTPCookie *)newCookie;

// Local Player info
@property (strong, nonatomic) NSString *playerDisplayName;

@property (strong, nonatomic) UIImage *playerDisplayImage;

@property (strong, nonatomic) NSString *gameTileImageTargetID;
@property (strong, nonatomic) NSString *gameTileName;

// Networking info to store
@property (strong, nonatomic) NSHTTPCookie *gameServerCookie;

@end
