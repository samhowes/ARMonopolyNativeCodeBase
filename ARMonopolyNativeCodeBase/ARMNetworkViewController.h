//
//  ARMNetworkViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/26/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARMGameServerCommunicator.h"
#import "ARMPlayerInfo.h"

/*const NSString *kGameServerCreateSessionPostBodyKey = @"sessionName";
const NSString *kGameServerCreateSessionURLString = @"/game_sessions/create";
const NSString *ARMGameServerURLString = @"http://111.18.0.252:3000"; */


@interface ARMNetworkViewController : UITableViewController <ARMGSCommunicatorDelegate, UITableViewDelegate, NSURLSessionTaskDelegate>

-(IBAction)userDidPressBarButtonItem:(id)sender;

- (void)setActivityIndicatorsVisible:(BOOL)shouldBeVisible;

@end
