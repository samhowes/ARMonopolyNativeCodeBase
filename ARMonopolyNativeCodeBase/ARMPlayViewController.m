//
//  TestViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/3/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMPlayViewController.h"
#import "ARMPlayerInfo.h"
#import "ARMNetworkPlayer.h"

@interface ARMPlayViewController ()

@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UILabel *currentPlayersLabel;
@property (weak, nonatomic) IBOutlet UIButton *displayAllPlayersButton;

@end



@implementation ARMPlayViewController

@synthesize currentPlayersLabel;
@synthesize displayAllPlayersButton;

#pragma mark Lifecycle Methods

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	
	[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
	self.navigationController.navigationBar.shadowImage = [UIImage new];
	self.navigationController.view.backgroundColor = [UIColor clearColor];
	self.navigationController.navigationBar.translucent = YES;
    [self populatePlayersLabel];
    
}

- (void)populatePlayersLabel
{
    NSArray *playersArray = [[ARMPlayerInfo sharedInstance] playersInSessionArray];
    NSString *errorString = @"No Players: Tap ⚙ to join a game";
    NSString *titleString = @"Players:";
    NSMutableString *displayString = [NSMutableString new];
    
    if ([playersArray count] == 0)
    {
        [displayString appendString:errorString];
        [displayAllPlayersButton setHidden:YES];
    }
    else
    {
        [displayAllPlayersButton setHidden:NO];
        [displayString appendString:titleString];
        
        // add each player to the toolbar
        for (ARMNetworkPlayer *player in playersArray)
        {
            [displayString appendFormat:@"  %@", [player playerName]];
        }
    }
    
    [self.currentPlayersLabel setText:displayString];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)displayCurrentPlayers:(id)sender
{
    NSMutableString *listPlayersString = [NSMutableString new];
    for (ARMNetworkPlayer *player in [[ARMPlayerInfo sharedInstance] playersInSessionArray])
    {
        [listPlayersString appendFormat:@"%@\n", [player playerName]];
    }
    [[[UIAlertView alloc] initWithTitle:@"All Current Players:"
                                message:listPlayersString
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil] show];
      
}

@end



