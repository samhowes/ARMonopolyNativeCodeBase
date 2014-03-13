//
//  ARMNetworkViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/26/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARMPlayerInfo.h"

const NSString *kGameServerCreateSessionPostBodyKey = @"sessionName";
const NSString *kGameServerCreateSessionURLString = @"/game_sessions/create";
const NSString *ARMGameServerURLString = @"http://111.18.0.252:3000";

typedef enum GameServerConnectionStatus {
    kNotInitialized,
    kConnectingToServer,
    kSendingProfile,
    kRetrievingGameSessions,
    kConnectedToServer,
    kJoiningGameSession,
    kInGameSession,
    kFailedToConnectToServer,
    kCreatingGameSession
} GameServerConnectionStatus;

@interface ARMNetworkViewController : UITableViewController <UITableViewDelegate, NSURLSessionTaskDelegate>

-(IBAction)userDidPressBarButtonItem:(id)sender;

@end
