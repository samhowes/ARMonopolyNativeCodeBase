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
#import "ARMGameSession.h"
#import "ARMGameServerCommunicator.h"
#import "ARMTableHeaderViewWithActivityIndicator.h"
#import "ARMNewGamePromptViewController.h"

const NSString *kBarButtonItemLeaveGameTitle = @"Leave Game";
const NSString *kImageDownloadingErrorAlertTitle = @"Error Downloading Player Images";

@interface ARMNetworkViewController ()


@property (strong, nonatomic) IBOutlet UITableView *gameSessionsTableView;
@property (weak, nonatomic) UIActivityIndicatorView *networkActivityIndicator;

@property BOOL isShowingLeaveGameButton;
@property (strong, nonatomic) NSMutableDictionary *completionHandlerDictionary;

@end


@implementation ARMNetworkViewController

@synthesize completionHandlerDictionary;
@synthesize isShowingLeaveGameButton;

@synthesize networkActivityIndicator;
@synthesize gameSessionsTableView;


#pragma mark - Life Cycle
/****************************************************************************/
/*                              Life Cycle                                  */
/****************************************************************************/

- (void)viewDidLoad
{
    __unsafe_unretained typeof(self) weakSelf = self;
    
    BOOL (^basicHandler)(NSError *error);
    BOOL (^handlerWithCustomTitle)(NSError *error, const NSString *title);
    
    basicHandler = ^(NSError *error)
    {
        return handlerWithCustomTitle(error, nil);
    };
    
    handlerWithCustomTitle = ^(NSError *error, NSString *title)
    {
        if (error)
        {
            [weakSelf handleNetworkingError:error withTitle:title];
        }
        
        [weakSelf.gameSessionsTableView reloadData];
        if (error) {
            return YES;
        } else {
            return NO;
        }
    };

    //-------------------------------- Login ----------------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
    {
        if (basicHandler(error)) return;
        [[ARMGameServerCommunicator sharedInstance] putProfileImageToServerWithCompletionHandler:nil];
    }
                                    forKey:kGSLoginCompletionKey];

    
    //-------------------------------- Logout ---------------------------------//
    [completionHandlerDictionary setObject:basicHandler forKey:kGSLogoutCompletionKey];

    
    //----------------------------- Upload Image ------------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
     {
         if (basicHandler(error)) return;
         [[ARMGameServerCommunicator sharedInstance] getActiveSessionsWithCompletionHandler:nil];
     }
                                    forKey:kGSUploadImageCompletionKey];
    
    
    //---------------------------- Download Image -----------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
    {
        handlerWithCustomTitle(error, kImageDownloadingErrorAlertTitle);
    }
                                    forKey:kGSDownloadImageCompletionKey];
    
    
    //------------------------- GetCurrentGameSession -------------------------//
    [completionHandlerDictionary setObject:basicHandler forKey:kGSGetCurrentGameSessionCompletionKey];
    
    
    //-------------------------- GetAllGameSessions ---------------------------//
    [completionHandlerDictionary setObject:basicHandler forKey:kGSGetCurrentGameSessionCompletionKey];
    
    //-------------------------- CreateGameSession ----------------------------//
    [completionHandlerDictionary setObject:basicHandler forKey:kGSCreateGameSessionCompletionKey];
    
    //--------------------------- JoinGameSession -----------------------------//
    // This one needs access to its custom data, we won't make one here
    
    //-------------------------- LeaveGameSession -----------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
     {
         if (basicHandler(error)) return;
         
         [weakSelf showLeaveGameButtonWithBool:NO];
         [[ARMGameServerCommunicator sharedInstance] getActiveSessionsWithCompletionHandler:nil];
     }
                                    forKey:kGSDownloadImageCompletionKey];
    
    
    [[ARMGameServerCommunicator sharedInstance] setCompletionHandlerDictionary:completionHandlerDictionary];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [gameSessionsTableView setDataSource:[ARMGameServerCommunicator sharedInstance]];
    [gameSessionsTableView reloadData];
    [[ARMGameServerCommunicator sharedInstance] setDelegate:self];

    //DEBUG: Populate static data for testing
    [[ARMPlayerInfo sharedInstance] setPlayerDisplayName:     @"Sam"];
    [[ARMPlayerInfo sharedInstance] setGameTileImageTargetID:   @"12"];
    [[ARMPlayerInfo sharedInstance] setPlayerDisplayImage:[UIImage new]];
    
    if (![[ARMPlayerInfo sharedInstance] isReadyForLogin])
    {
        [self showAlertWithTitle:@"Configuration Error"
                         message:@"Complete Steps 1 and 2 before connecting to the Game Server"
               cancelButtonTitle:@"OK"];
        return;
    }
    
    switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
        //--------------------- Get all sessions Cases ----------------------------//
        case kLoggedIn:
        case kRetrievingGameSessions:
        case kReadyForSelection:
        case kJoiningGameSession:
        case kCreatingGameSession:
            [self hideRightNavigationBarButtonItem];
            [[ARMGameServerCommunicator sharedInstance] getActiveSessionsWithCompletionHandler:nil];
            break;
            
        //----------------- Get the current session Cases -------------------------//
        case kInGameSession:
        case kLeavingGameSession:
            [self showLeaveGameButtonWithBool:YES];
            [[ARMGameServerCommunicator sharedInstance] getCurrentPlayersInSessionWithCompletionHandler:nil];
            break;

        //----------------------------- Login Cases -------------------------------//
        case kNotInitialized:
        case kFailedToConnectToServer:
        case kLoggingIn:
        case kSendingImage:
        default:
            [[ARMGameServerCommunicator sharedInstance] loginWithCompletionHandler:nil];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[ARMGameServerCommunicator sharedInstance] finishTasksWithoutCompletionHandlerAndPreserveState];
    [super viewWillDisappear:animated];
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    ARMNewGamePromptViewController *source = [segue sourceViewController];
    if ([source nameOfNewGame])
    {
        [self createGameSessionWithName:[source nameOfNewGame]];
        //TODO: handle the "creating Game session" state properly
        
    }
    // else, the user just pressed the cancel button
}

#pragma mark - Life Cycle
/****************************************************************************/
/*                          Utility Methods                                 */
/****************************************************************************/

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

- (void)showLeaveGameButtonWithBool:(BOOL)showLeaveGameButton
{
    if (showLeaveGameButton)
    {
        [[self navigationItem] setRightBarButtonItem:
         [[UIBarButtonItem alloc] initWithTitle:[kBarButtonItemLeaveGameTitle copy] style:UIBarButtonItemStylePlain target:self action:@selector(userDidPressBarButtonItem:)] animated:YES];
        self.isShowingLeaveGameButton = YES;
    } else {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(userDidPressBarButtonItem:)] animated:YES];
        self.isShowingLeaveGameButton = NO;
    }
    
}

- (void)hideRightNavigationBarButtonItem
{
    [[self navigationItem] setRightBarButtonItem:nil animated:YES];
}


#pragma mark - Life Cycle
/****************************************************************************/
/*                        Network Access Methods                            */
/****************************************************************************/

- (void)createGameSessionWithName:(NSString *)gameName
{
    [[ARMGameServerCommunicator sharedInstance] createSessionWithName:gameName completionHandler:nil];
}

-(void)leaveCurrentGameSession
{
    [self setActivityIndicatorsVisible:YES];
    [[ARMGameServerCommunicator sharedInstance] leaveSessionWithCompletionHandler:nil];
}

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


#pragma mark - User Input
/****************************************************************************/
/*                              User Input                                  */
/****************************************************************************/
- (IBAction)userDidPressBarButtonItem:(id)sender
{
    // If we should leave a game
    if (self.isShowingLeaveGameButton)
    {
        [self leaveCurrentGameSession];
    }
    else // otherwise we will be creating a game
    {
        [self performSegueWithIdentifier:@"CreateGameSegue" sender:self];
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

#pragma mark - UITableViewDataSource Methods
/****************************************************************************/
/*					   UITableViewDatasource Methods                        */
/****************************************************************************/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Code in this method is under active review
    // Return the number of sections.
    if ([[ARMGameServerCommunicator sharedInstance] connectionStatus] == kInGameSession)
    {
        return 2;       // list [Current session, current players]
    }
    else
    {
        return 1;       // List the available game sessions
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
#warning Code in this method is under active review
    if (tableView) return @" ";
    NSString *titleForHeader;
    switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
        case kNotInitialized:
            titleForHeader = @"Not connected to Game Server";
            break;
        
        case kLoggingIn:
            titleForHeader = @"Logging in to Game Server...";
            break;
        
        case kSendingImage:
            titleForHeader = @"Uploading profile image to Game Server...";
            break;
        
        case kRetrievingGameSessions:
            titleForHeader = @"Retrieving active games...";
            break;
            
        case kLoggedIn:
            titleForHeader = @"Select a game...";
            break;
        
        case kInGameSession:
            if (section == 0)
            {
                titleForHeader = @"Current Game Session";
            }
            else
            {
                titleForHeader = @"Current Players";
            }
            break;
        
        case kFailedToConnectToServer:
            titleForHeader = @"Error connecting to Game Server!";
            break;
        
        default:
            titleForHeader = @"Not connected to Game Server and Failed Switch";
            break;
    }
    return titleForHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
#warning Code in this method is under active review
    GameServerConnectionStatus connectionStatus = [[ARMGameServerCommunicator sharedInstance] connectionStatus];
    
    if (connectionStatus)
    {
        return @"Tap '+' to create your own";
    }
    else if (connectionStatus == kInGameSession && section == 0)
    {
        return @"Tap 'Leave' to join a different session";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Code in this method is under active review
    // Return the number of rows in the section.
    if ([[ARMGameServerCommunicator sharedInstance] connectionStatus] == kInGameSession)
    {
        if (section == 0)
        {
            return 1;       // just display the current game session
        }
        else {
            return [[[ARMPlayerInfo sharedInstance]  playersInSessionArray] count];
        }
    }
    else
    {
        return [[[ARMGameServerCommunicator sharedInstance] availableGameSessions] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#warning Code in this method is under active review
    static NSString *CellIdentifier = @"GameSessionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if ([[ARMGameServerCommunicator sharedInstance] connectionStatus] == kInGameSession)
    {
        if (indexPath.section == 0)     // Display the current game session at the top
        {
            cell.textLabel.text = [[ARMPlayerInfo sharedInstance] sessionName];
            [cell setUserInteractionEnabled:NO];
        }
        else    // display the Current players below
        {
            cell.textLabel.text = [[[[ARMPlayerInfo sharedInstance]  playersInSessionArray]
                                        objectAtIndex:indexPath.row] playerName];
            
            [cell setUserInteractionEnabled:NO];
        }
    }
    else
    {   // Display a current game session
        NSArray *availableGameSessions = [[ARMGameServerCommunicator sharedInstance] availableGameSessions];
        cell.textLabel.text = [(ARMGameSession *)availableGameSessions[indexPath.row] name];
        
        [cell setUserInteractionEnabled:YES];
    }
    
    return cell;
}


@end
