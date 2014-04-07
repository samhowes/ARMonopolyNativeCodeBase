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


@interface ARMNetworkViewController : UITableViewController <ARMGSCommunicatorDelegate, UITableViewDelegate, NSURLSessionTaskDelegate>

-(IBAction)userDidPressBarButtonItem:(id)sender;

- (void)setActivityIndicatorsVisible:(BOOL)shouldBeVisible;

@end
