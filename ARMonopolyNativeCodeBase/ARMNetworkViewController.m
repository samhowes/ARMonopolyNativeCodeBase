//
//  ARMNetworkViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/26/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <Foundation/NSError.h>
#import "ARMNetworkViewController.h"
#import "ARMNetworkPlayer.h"
#import "ARMGameServerCommunicator.h"
#import "ARMTableHeaderViewWithActivityIndicator.h"

const NSString *kBarButtonItemLeaveGameTitle = @"Leave Game";
const NSString *kImageDownloadingErrorAlertTitle = @"Error Downloading Player Images";

@interface ARMNetworkViewController ()

@property (strong, nonatomic) IBOutlet UITableView *gameSessionsTableView;
@property (weak, nonatomic) UIActivityIndicatorView *networkActivityIndicator;

@end


@implementation ARMNetworkViewController

@synthesize networkActivityIndicator;
@synthesize gameSessionsTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [gameSessionsTableView setDataSource:[ARMGameServerCommunicator sharedInstance]];
    [gameSessionsTableView reloadData];
    
    [[ARMGameServerCommunicator sharedInstance] continueTasksWithCompletionHandler];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle
{
    if (cancelButtonTitle == nil)
    {
        cancelButtonTitle = @"Dismiss";
    }
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:cancelButtonTitle
                      otherButtonTitles:nil] show];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[ARMGameServerCommunicator sharedInstance] finishTasksWithoutCompletionHandlerAndPreserveState];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[ARMGameServerCommunicator sharedInstance] continueTasksWithCompletionHandler];
    // Populate static data for testing
    [[ARMPlayerInfo sharedInstance] setPlayerDisplayName:     @"Sam"];
    [[ARMPlayerInfo sharedInstance] setGameTileImageTargetID:   @"12"];
    
    if (![[ARMPlayerInfo sharedInstance] isReadyForLogin])
    {
        [self showAlertWithTitle:@"Configuration Error"
                         message:@"Complete Steps 1 and 2 before connecting to the Game Server"
               cancelButtonTitle:@"OK"];
        return;
    }
    
    switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
            // cases where we want to retrieve active game sessions
        case kLoggedIn:
        case kRetrievingGameSessions:
        case kReadyForSelection:
        case kJoiningGameSession:
        case kCreatingGameSession:
        {
            [self hideRightNavigationBarButtonItem];
            [[ARMGameServerCommunicator sharedInstance] getActiveSessionsWithCompletionHandler:^(NSError *error) {
                [gameSessionsTableView reloadData];
                if (error)
                {
                    [self handleNetworkingError:error];
                    return;
                }
                [self showLeaveGameButtonWithBool:NO];
            }];
        }
            break;
            // Cases where we want to get the current game session
        case kInGameSession:
        case kLeavingGameSession:
        {
            [[ARMGameServerCommunicator sharedInstance] getCurrentPlayersInSessionWithCompletionHandler:^(NSError *error)
             {
                 [gameSessionsTableView reloadData];
                 if (error)
                 {
                     [self handleNetworkingError:error withTitle:kImageDownloadingErrorAlertTitle];
                     return;
                 }
                 [self showLeaveGameButtonWithBool:YES];
                 
                 [[ARMGameServerCommunicator sharedInstance] downloadPlayerImagesWithCompletionHandler:^(NSError *error)
                  {
                      [gameSessionsTableView reloadData];
                      if (error) [self handleNetworkingError:error withTitle:kImageDownloadingErrorAlertTitle];
                  }];
             }];
        }
            break;
            // Cases where we want to login to the server
        case kFailedToConnectToServer:
        case kNotInitialized:
        case kLoggingIn:
        case kSendingImage:
        default:
        {
            [[ARMGameServerCommunicator sharedInstance] loginWithCompletionHandler:^(NSError *error){
                if (error)
                {
                    [self handleNetworkingError:error];
                    return;
                }
                
                // If there wasn't an error in Login step 1, continue to Login step 2
                [[ARMGameServerCommunicator sharedInstance] putProfileImageToServerWithCompletionHandler:^(NSError *error) {
                    if (error)
                    {
                        [self handleNetworkingError:error];
                        return;
                    }
                    
                    [[ARMGameServerCommunicator sharedInstance] getActiveSessionsWithCompletionHandler:^(NSError *error) {
                        [gameSessionsTableView reloadData];
                        if (error)
                        {
                            [self handleNetworkingError:error];
                            return;
                        }
                        [self showLeaveGameButtonWithBool:NO];
                        
                    }];
                }];
            }];
        }
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setActivityIndicatorsVisible:(BOOL)shouldBeVisible
{
    if (shouldBeVisible)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [networkActivityIndicator startAnimating];
    }
    else
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [networkActivityIndicator stopAnimating];
    }
}

#pragma mark - Table view data source
/****************************************************************************/
/*							TableView Delegate                              */
/****************************************************************************/

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"headerIndicatorView"];
    if (sectionHeaderView == nil) {
        sectionHeaderView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"headerIndicatorView"];
    }
    
    UINib *contentViewNib = [UINib nibWithNibName:@"ARMSectionHeaderView" bundle:nil];
    ARMTableHeaderViewWithActivityIndicator *contentView = [[contentViewNib instantiateWithOwner:self options:nil] firstObject];
    
    networkActivityIndicator = contentView.activityInidcator;
    contentView.titleLabel.text = [[[ARMGameServerCommunicator sharedInstance] tableView:nil titleForHeaderInSection:section] uppercaseString];
    [[sectionHeaderView contentView] addSubview:contentView];

    return sectionHeaderView;
}

//------------------------------------------ User Input
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GameServerConnectionStatus connectionStatus = [[ARMGameServerCommunicator sharedInstance] connectionStatus];
    if (connectionStatus == kJoiningGameSession ||
        connectionStatus == kInGameSession)
    {
        return; // do nothing if we are already joining a game session, or in a game session
    }
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:[[selectedCell accessoryView] frame]];
    [spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [spinner setHidesWhenStopped:YES];
    [spinner startAnimating];
    [selectedCell setAccessoryView:spinner];
    
    [[ARMGameServerCommunicator sharedInstance] joinSessionWithIndex:[indexPath row] completionHandler:^(NSError *error) {
        [spinner stopAnimating];
        if (error)
        {
            [self handleNetworkingError:error];
            return;
        }
        
        [self showLeaveGameButtonWithBool:YES];
        
        [gameSessionsTableView reloadData];
        [[ARMGameServerCommunicator sharedInstance] downloadPlayerImagesWithCompletionHandler:^(NSError *error)
        {
            if (error) {
                [self handleNetworkingError:error withTitle:kImageDownloadingErrorAlertTitle];
            }
        }];
    }];
    
 /*   [self joinGameServerSessionWithIndex:indexPath.row completionHandler:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [spinner stopAnimating];
            
            rightNavigationBarButtonItem  = [[UIBarButtonItem alloc]
                                             initWithTitle:kBarButtonItemLeaveGameTitle
                                             style:UIBarButtonItemStylePlain target:self
                                             action:@selector(userDidPressBarButtonItem:)];
            
            [tableView reloadData]; //BOOKMARK */
            
            /* Animate the reload data
            //-- Hide the game sessions and show the current players instead --//
            [tableView beginUpdates];
            
            NSMutableArray *deleteIndexPaths = [NSMutableArray new];
            for (NSIndexPath *visibleCellPath in [tableView indexPathsForVisibleRows])
            {
                if ([indexPath isEqual:visibleCellPath]) {
                    continue;
                } else {
                    [deleteIndexPaths addObject:visibleCellPath];
                }
            }
            
            NSMutableArray *insertIndexPaths = [NSMutableArray new];
            for (int ii = 0; ii < [[[ARMPlayerInfo sharedInstance] playersInSessionArray] count]; ++ii)
            {
                [insertIndexPaths addObject:]
            }
            
            [tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            [tableView insertRowsAtIndexPaths: withRowAnimation:];
            
            [tableView endUpdates]; */
   //     });
 //   }];
}

- (void)showLeaveGameButtonWithBool:(BOOL)showLeaveGameButton
{
    if (showLeaveGameButton)
    {
        [[self navigationItem] setRightBarButtonItem:
         [[UIBarButtonItem alloc] initWithTitle:[kBarButtonItemLeaveGameTitle copy] style:UIBarButtonItemStylePlain target:self action:@selector(userDidPressBarButtonItem:)] animated:YES];
    } else {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc]
                                                      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(userDidPressBarButtonItem:)]
                                            animated:YES];
    }
    
}

- (void)hideRightNavigationBarButtonItem
{
    [[self navigationItem] setRightBarButtonItem:nil animated:YES];
}

- (IBAction)userDidPressBarButtonItem:(id)sender
{
    
    // If we should leave a game
    if ([[ARMGameServerCommunicator sharedInstance] connectionStatus] == kInGameSession)
    {
        [self setActivityIndicatorsVisible:YES];
        [[ARMGameServerCommunicator sharedInstance] leaveSessionWithCompletionHandler:^(NSError *error) {
            [gameSessionsTableView reloadData];
            if (error)
            {
                [self handleNetworkingError:error];
                [gameSessionsTableView reloadData];
                return;
            }
            
            [self showLeaveGameButtonWithBool:NO];
            
            [[ARMGameServerCommunicator sharedInstance] getActiveSessionsWithCompletionHandler:^(NSError *error) {
                [gameSessionsTableView reloadData];
                if (error)
                {
                    [self handleNetworkingError:error];
                    return;
                }
                
            }];
        }];
    }
    else // otherwise we will be creating a game
    {
        [self setActivityIndicatorsVisible:YES];
        [[ARMGameServerCommunicator sharedInstance] createSessionWithName:[[ARMPlayerInfo sharedInstance] playerDisplayName] completionHandler:^(NSError *error) {
            [gameSessionsTableView reloadData];
            if (error)
            {
                [self handleNetworkingError:error];
                [gameSessionsTableView reloadData];
                return;
            }
            [self showLeaveGameButtonWithBool:YES];
            
        }];
    }
}

#pragma mark - Networking Methods
/****************************************************************************/
/*                          Networking Methods                              */
/****************************************************************************/

//------------------------------------------ Error Methods
- (void)handleNetworkingError:(NSError *)error
{
    [self handleNetworkingError:error withTitle:nil];
}

- (void)handleNetworkingError:(NSError *)error withTitle:(const NSString *)titleString
{
    NSMutableString *errorString = [[NSMutableString alloc] init];
    @try
    {
        if ([[error domain] isEqualToString:NSURLErrorDomain])      // TODO: Move this into Game Server Communicator
        {
            switch ([error code])
            {
                case NSURLErrorBadURL:
                case NSURLErrorTimedOut:
                case NSURLErrorUnsupportedURL:
                case NSURLErrorCannotFindHost:
                case NSURLErrorCannotConnectToHost:
                    errorString = [NSMutableString stringWithFormat:@"Cannot connect to Game Server at URL: %@",
                                   [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
                    break;
                case NSURLErrorNotConnectedToInternet:
                    [errorString setString:@"No internet connection"];
                    break;
                    
                case NSURLErrorBadServerResponse:
                    [errorString setString:@"The server gave an invalid response, try again"];
                    break;
                    
                case NSURLErrorUnknown:
                default:
                    [errorString setString:@"Unknown Error"];
                    break;
            }
            
        }
        else if ([[error domain] isEqualToString:[ARMGameServerErrorDomain copy]])
        {
            switch ([error code])
            {
                case ARMInvalidPostDataErrorCode:
                    [errorString setString:@"Your information is incorrect. Please provide a valid user name to log in to the server."];
                    break;
                case ARMInvalidPutDataErrorCode:
                    [errorString setString:@"Your profile image is invalid."];
                    break;
                    
                case ARMInvalidServerResponseDataErrorCode:
                    [errorString setString:@"The server provided an invalid response, please try again."];
                    break;
                case ARMGameServerErrorResponseErrorCode:
                    if ([error localizedFailureReason])
                    {
                        [errorString appendString:[NSString stringWithFormat:@"%@:", [error localizedFailureReason]]];
                    }
                    if ([error localizedDescription])
                    {
                        [errorString appendString:[error localizedDescription]];
                    }
                        
                    break;
                case ARMUnkownErrorCode:
                default:
                    [errorString setString:@"An unknown networking error occured\nPlease try again"];
                    break;
            }
        }
    }
    @catch (NSException *e) {
        [errorString setString:@"Unknown Error"];
    }
    
    [[[UIAlertView alloc] initWithTitle:(titleString == nil ? [titleString copy]: @"Network Error")
                                message:errorString
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}



@end
