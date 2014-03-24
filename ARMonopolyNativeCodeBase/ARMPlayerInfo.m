//
//  ARMPlayerInfo.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/2/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMPlayerInfo.h"

const NSString *kDefaultImageFileName = @"LOGO.png";
const NSString *kImageFolderName = @"images";

@implementation ARMPlayerInfo

@synthesize playerDisplayName;
@synthesize playerDisplayImage;
@synthesize gameTileImageTargetID;
@synthesize gameTileName;

@synthesize sessionName;
@synthesize playersInSessionArray;

/****************************************************************************/
/*								Class Methods                               */
/****************************************************************************/
+ (id)sharedInstance
{
    static ARMPlayerInfo *this = nil;
    if (!this)
    {
        this = [self loadInstanceFromArchive];
        if (!this)
        {
            this = [[ARMPlayerInfo alloc] init];
        }
    }
    return this;
}

+ (id)loadInstanceFromArchive
{
    ARMPlayerInfo *this = [NSKeyedUnarchiver unarchiveObjectWithFile:[[ARMPlayerInfo savedDataURL] path]];
    return this;
}

+ (NSURL *)savedDataURL
{
	NSURL *dataPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	dataPath = [dataPath URLByAppendingPathComponent:@"SavedData"];
	return dataPath;
}

/****************************************************************************/
/*							Instance Methods                                */
/****************************************************************************/

- (id)init
{
	self = [super init];
	if (self) {
		playersInSessionArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self) {
		for (NSString *key in self.keysForEncoding)
		{
			[self setValue:[decoder decodeObjectForKey:key] forKey:key];
		}
	}
	return self;
}

- (BOOL)isReadyToConnectToGameTile
{
    if (playerDisplayName)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)isReadyForLogin
{
    if ([self isReadyToConnectToGameTile] &&
        playerDisplayName && playerDisplayImage && gameTileImageTargetID)
    {
        return YES;
    }
    
    return NO;
}

- (void)applicationDidLeaveGameSession
{
    playersInSessionArray = nil;
}

- (void)bluetoothDidConnectToGameTileWithName:(NSString *)name imageTargetID:(NSString *)imageTargetID
{
    gameTileName = name;
    gameTileImageTargetID = imageTargetID;
    
    // now that we are connected to a game tile, we can save our image in the right location
    // Save the file to the documents directory so vuforia can access it
    NSString *destinationPath = [self pathToSaveUsersImage];
    
    NSData *imageData = UIImagePNGRepresentation(playerDisplayImage);
    [imageData writeToFile:destinationPath atomically:NO];

    
}

/*
 *  If we were connected to a game tile, make sure we remove the old image
 */
/*- (void)bluetoothWillConnectToNewGameTile
{
    if (gameTileImageTargetID)
    {
        NSString *pathToRemove = [self pathToSaveUsersImage];
        [[NSFileManager defaultManager] removeItemAtPath:pathToRemove error:NULL];
    }
    gameTileName = nil;
    gameTileImageTargetID = nil;
} */

- (NSString *)pathToSaveUsersImage
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:
            [[kImageFolderName stringByAppendingPathComponent:gameTileImageTargetID]
                               stringByAppendingPathExtension:[kDefaultImageFileName pathExtension]]];
}

/************************ Coding Methods ***********************************/
- (NSArray *)keysForEncoding;
{
	return [NSArray arrayWithObjects:@"playerDisplayName",
			@"playerDisplayImage", @"gameTileImageTargetID", nil];
}

- (BOOL)saveInstanceToArchive
{
	return [NSKeyedArchiver archiveRootObject:[ARMPlayerInfo sharedInstance] toFile:[[ARMPlayerInfo savedDataURL] path]];
}

/*
 * We are asked to be archived, encode our data
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
	for (NSString *key in self.keysForEncoding)
	{
		[encoder encodeObject:[self valueForKey:key] forKey:key];
	}
}

@end
