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
    // Check for the default images that Unity will use
    NSBundle* myBundle = [NSBundle mainBundle];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pathToImagesDirectory = [documentsDirectory stringByAppendingPathComponent:[kImageFolderName copy]];
    NSString *destinationPath = [documentsDirectory stringByAppendingPathComponent:[kImageFolderName stringByAppendingPathComponent:[kDefaultImageFileName copy]]];
    
    NSError *error;
    BOOL isDirectory;
    NSString* sourcePath = [myBundle pathForResource:[kDefaultImageFileName stringByDeletingPathExtension] ofType:[kDefaultImageFileName pathExtension]];
    NSLog(@"Copying bundle resources into Documets Directory: Source Path: %@\n Documents Path: %@ \n Folder Path: %@", sourcePath, documentsDirectory, destinationPath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:[destinationPath stringByDeletingLastPathComponent] isDirectory:&isDirectory])
    {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[destinationPath stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSLog(@"Error while creating images directory: %@", error);
        }
        error = nil;
    }
    else if (!isDirectory)
    {
        NSLog(@"Error: image folder name '%@' is not a directory!", [kImageFolderName copy]);
    }
    
    if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error])
    {
        NSLog(@"Error while copying bundle resources: %@", error);
    }
    else
    {
        NSLog(@"Successfully copied bundle resources!");
    }
    
    // Delete Old images from the last game session if there are any
    NSArray *filesInImageDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[destinationPath stringByDeletingLastPathComponent] error:&error];
    if ([filesInImageDirectory count] >1)
    {
        NSLog(@"Removing old images from images Directory");
        for (NSString *imagePath in filesInImageDirectory)
        {
            if (![imagePath isEqualToString:kDefaultImageFileName])
            {
                [[NSFileManager defaultManager] removeItemAtPath:[pathToImagesDirectory stringByAppendingPathComponent:imagePath] error:&error];
                if (error)
                {
                    NSLog(@"Error removing old image files at launch: %@", error);
                }
            }
        }
    }
    
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

@end
