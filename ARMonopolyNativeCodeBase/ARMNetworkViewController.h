//
//  ARMNetworkViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/26/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARMPlayerInfo.h"

typedef enum GameServerConnectionStatus {
    kNotInitialized = 0,
    kConnectingToServer = 1,
    kSendingProfile = 2,
    kRetrievingGameSessions = 3,
    kConnectedToServer = 4,
    kFailedToConnectToServer = 5
} GameServerConnectionStatus;

@interface ARMNetworkViewController : UITableViewController <UITableViewDelegate, NSURLSessionTaskDelegate>

@end
