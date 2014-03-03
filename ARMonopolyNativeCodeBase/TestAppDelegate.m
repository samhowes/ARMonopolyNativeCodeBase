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
