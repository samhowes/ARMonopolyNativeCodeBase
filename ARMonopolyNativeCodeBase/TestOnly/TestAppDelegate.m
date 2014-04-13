//
//  ARMAppDelegate.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 1/31/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "TestAppDelegate.h"
#import "ARMPlayerInfo.h"

@implementation TestAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self prepareDocumentsDirectory];
    
    // Initialize our User Data
    [ARMPlayerInfo sharedInstance];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[ARMPlayerInfo sharedInstance] saveInstanceToArchive];
    
}

- (void)prepareDocumentsDirectory
{
    // Check for the default images that Unity will use
    NSArray *fileNamesArray = @[@"Purple.png", @"Blue.png", @"Orange.png", @"Green.png"];
    
    NSBundle* myBundle = [NSBundle mainBundle];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pathToImagesDirectory = [documentsDirectory stringByAppendingPathComponent:[kImageFolderName copy]];
    
    NSError *error = nil;
    BOOL isDirectory;
    NSLog(@"Copying bundle resources into Documets Directory: \n-->ImagesDirectory: %@", pathToImagesDirectory);
    
    // First: Create the images directory
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToImagesDirectory isDirectory:&isDirectory])
    {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:pathToImagesDirectory withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSLog(@"Error while creating images directory: %@", error);
        }
        error = nil;
    }
    else if (!isDirectory)
    {
        NSLog(@"Error: image folder name '%@' is not a directory!", [kImageFolderName copy]);
    }
    
    // First delete all images in the images directory
    NSArray *filesInImageDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToImagesDirectory error:nil];
    if ([filesInImageDirectory count] > 0)
    {
        NSLog(@"Removing old images from images Directory");
        for (NSString *imagePath in filesInImageDirectory)
        {
            [[NSFileManager defaultManager] removeItemAtPath:[pathToImagesDirectory stringByAppendingPathComponent:imagePath] error:&error];
            if (error)
            {
                NSLog(@"Error removing old image files at launch: %@", [error description]);
            }
        }
    }
    
    // Second: Copy all default images over
    NSString *sourcePath;
    NSString *destinationPath;
    for (NSInteger ii = 0; ii < [fileNamesArray count]; ++ii)
    {
        sourcePath = [myBundle pathForResource:[fileNamesArray[ii] stringByDeletingPathExtension] ofType:[kDefaultImageFileName pathExtension]];
        destinationPath = [pathToImagesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:[kAvatarImageFilenameFormatString copy], [NSString stringWithFormat:@"%ld", (long)ii]]];
        if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error])
        {
            NSLog(@"Error while copying bundle resources: %@", error);
        }
    }
}


@end
