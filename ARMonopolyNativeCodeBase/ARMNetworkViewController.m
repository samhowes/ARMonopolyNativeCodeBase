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

const NSInteger kTableCellTagForGameSessionCheckmark = 1;
const NSInteger kTableCellTagForGameSessionTitleLabel = 2;
const NSInteger kTableCellTagForPlayeNameLabel = 1;

const NSString *ARMReuseIdentifierForDefaultTableViewHeader = @"ARMReuseIdentifierForDefaultTableViewHeader";

const NSString *kBarButtonItemLeaveGameTitle = @"Leave Game";
const NSString *kImageDownloadingErrorAlertTitle = @"Error Downloading Player Images";

@interface ARMNetworkViewController ()
{
    NSInteger selectedCellNumber;
    BOOL isReturningFromNewGamePrompt;
}

@property (weak, nonatomic) IBOutlet UITableView *gameSessionsTableView;
@property (weak, nonatomic) UIActivityIndicatorView *networkActivityIndicator;
@property (weak, nonatomic) UIActivityIndicatorView *selectedCellActivityIndicator;

@property (weak, nonatomic) UIBarButtonItem *rightBarButtonItem;
@property BOOL isShowingLeaveGameButton;

@end


@implementation ARMNetworkViewController

@synthesize isShowingLeaveGameButton;

@synthesize networkActivityIndicator;
@synthesize gameSessionsTableView;

/*
switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
{
    case kNotInitialized: break;
    case kFailedToConnectToServer: break;
    case kNotConnectedToGameServer: break;
    case kLoggingIn: break;
    case kLoggingOut: break;
    case kSendingImage: break;
    case kLoggedIn: break;
    case kRetrievingGameSessions: break;
    case kJoiningGameSession: break;
    case kCreatingGameSession: break;
    case kInGameSession: break;
    case kRetrievingSessionInfo: break;
    case kRefreshingSessionInfo: break;
    case kDownloadingPlayerProfiles: break;
    case kLeavingGameSession: break;
}

*/
#pragma mark - Life Cycle
/****************************************************************************/
/*                              Life Cycle                                  */
/****************************************************************************/

- (void)viewDidLoad
{
    [self.gameSessionsTableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:[ARMReuseIdentifierForDefaultTableViewHeader copy]];
    
    [self.gameSessionsTableView registerClass:[ARMTableHeaderViewWithActivityIndicator class] forHeaderFooterViewReuseIdentifier:[ARMReuseIdentifierForTableViewHeaderWithActivityIndicator copy]];
    
    [self registerCompletionHandlers];
    
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[ARMGameServerCommunicator sharedInstance] setDelegate:self];

    //DEBUG: Populate static data for testing
    [[ARMPlayerInfo sharedInstance] setPlayerDisplayName:       @"Sam"];
    [[ARMPlayerInfo sharedInstance] setGameTileImageTargetID:   @"1"];
    [[ARMPlayerInfo sharedInstance] setPlayerDisplayImage:      [UIImage new]];
    
    if (![[ARMPlayerInfo sharedInstance] isReadyForLogin])
    {
        [[[UIAlertView alloc] initWithTitle:@"Configuration Error"
                                    message:@"Complete Steps 1 and 2 before connecting to the Game Server"
                                   delegate:nil
                          cancelButtonTitle:@"I'll do that now!"
                          otherButtonTitles:nil] show];
        return;
    }
    if (isReturningFromNewGamePrompt)
    {
        isReturningFromNewGamePrompt = NO;
    }
    else
    {
        switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
        {
            //--------------------- Get all sessions Cases ----------------------------//
            case kLoggedIn:
            case kRetrievingGameSessions:
            case kJoiningGameSession:
            case kCreatingGameSession:
                [self hideRightNavigationBarButtonItem];
                [[ARMGameServerCommunicator sharedInstance] getAllGameSessionsWithCompletionHandler:nil];
                break;
                
            //----------------- Get the current session Cases -------------------------//
            case kInGameSession:
            case kLeavingGameSession:
                [self showRightBarButtonItemWithBool:YES];
                [[ARMGameServerCommunicator sharedInstance] getCurrentSessionInfoWithCompletionHandler:nil];
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
    [self refreshDisplayWithAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[ARMGameServerCommunicator sharedInstance] finishTasksWithoutCompletionHandlerAndPreserveState];
    [super viewWillDisappear:animated];
}

- (IBAction)returnFromNewGamePrompt:(UIStoryboardSegue *)segue
{
    isReturningFromNewGamePrompt = YES;
    ARMNewGamePromptViewController *source = [segue sourceViewController];
    if ([source nameOfNewGame])
    {
        [[ARMGameServerCommunicator sharedInstance] createSessionWithName:[source nameOfNewGame] completionHandler:nil];
    }
    [self refreshDisplayWithAnimation];
    // else, the user just pressed the cancel button
}

- (void)registerCompletionHandlers
{
    // --------    Set up some default handlers    --------//
    __unsafe_unretained typeof(self) weakSelf = self;           // Make sure to avoid a retain loop
    
    BOOL (^basicHandler)(NSError *error);
    BOOL (^handlerWithCustomTitle)(NSError *error, const NSString *title);
    
    handlerWithCustomTitle = ^(NSError *error, NSString *title)
    {
        if (error)
        {
            [weakSelf handleNetworkingError:error withTitle:title];
        }
        
        [weakSelf refreshDisplayWithAnimation];
        if (error) {
            return YES;
        } else {
            return NO;
        }
    };
    
    basicHandler = ^(NSError *error)
    {
        return handlerWithCustomTitle(error, nil);
    };
    
    NSMutableDictionary *completionHandlerDictionary = [NSMutableDictionary new];
    
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
         [[ARMGameServerCommunicator sharedInstance] getAllGameSessionsWithCompletionHandler:nil];
     }
                                    forKey:kGSUploadImageCompletionKey];
    
    
    //---------------------------- Download Image -----------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
     {
         handlerWithCustomTitle(error, kImageDownloadingErrorAlertTitle);
     }
                                    forKey:kGSDownloadImageCompletionKey];
    
    
    //------------------------- GetCurrentGameSession -------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
     {
         if (basicHandler(error)) return;
         [[ARMGameServerCommunicator sharedInstance] downloadPlayerImagesWithCompletionHandler:nil];
     }
                                    forKey:kGSGetCurrentSessionInfoCompletionKey];
    
    //-------------------------- GetAllGameSessions ---------------------------//
    [completionHandlerDictionary setObject:basicHandler forKey:kGSGetAllGameSessionsCompletionKey];
    
    //-------------------------- CreateGameSession ----------------------------//
    [completionHandlerDictionary setObject:basicHandler forKey:kGSCreateGameSessionCompletionKey];
    
    //--------------------------- JoinGameSession -----------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
     {
         [weakSelf.selectedCellActivityIndicator stopAnimating];
         if (basicHandler(error)) return;
         
         [[ARMGameServerCommunicator sharedInstance] downloadPlayerImagesWithCompletionHandler:nil];
     }
                                    forKey:kGSJoinGameSessionCompletionKey];
    
    
    //-------------------------- LeaveGameSession -----------------------------//
    [completionHandlerDictionary setObject:^(NSError *error)
     {
         if (basicHandler(error)) return;
         
         [weakSelf showRightBarButtonItemWithBool:NO];
         [[ARMGameServerCommunicator sharedInstance] getAllGameSessionsWithCompletionHandler:nil];
     }
                                    forKey:kGSLeaveGameSessionCompletionKey];
    
    
    [[ARMGameServerCommunicator sharedInstance] setCompletionHandlerDictionary:completionHandlerDictionary];
}


#pragma mark - Utility Methods
/****************************************************************************/
/*                          Utility Methods                                 */
/****************************************************************************/

- (void)refreshDisplayWithAnimation
{
    // Need to properly set the following:
    //      Show/Hide the rightBarButtonItem
    //      enable/disable the rightBarButtonItem
    //      add/Remove the refreshControl
    switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
            // Just show the refresh control
        case kNotInitialized:
        case kFailedToConnectToServer:
        case kNotConnectedToGameServer:
            [self addRefreshControl];
            break;
            
            // Make sure Everything is hidden (all of the 'ing'/busy states)
        case kLoggingIn:
        case kLoggingOut:
        case kSendingImage:
            [self removeRefreshControl];
            [self hideRightNavigationBarButtonItem];
            break;
            
        case kLoggedIn:
        case kRetrievingGameSessions:
            [self addRefreshControl];
            [self showCreateGameBarButtonItem];
            break;
            
        case kJoiningGameSession:
        case kCreatingGameSession:
        case kRetrievingSessionInfo:
        case kRefreshingSessionInfo:
            [self rightBarButtonItemShouldBeEnabled:NO];
            break;
            
        case kInGameSession:
            [self addRefreshControl];
            [self showLeaveGameBarButtonItem];
            break;
            
        case kDownloadingPlayerProfiles:
            [self addRefreshControl];
            [self rightBarButtonItemShouldBeEnabled:YES];
            break;
            
        case kLeavingGameSession:
            [self rightBarButtonItemShouldBeEnabled:NO];
            [self removeRefreshControl];
            break;

       
    }
    
    // Finallly: Animate the reloading of the table
    NSRange indexRange = NSMakeRange(0, [self numberOfSectionsInTableView:gameSessionsTableView]);
    NSInteger previousSections = [gameSessionsTableView numberOfSections];
    NSInteger futureSections = [self numberOfSectionsInTableView:gameSessionsTableView];
    GameServerConnectionStatus connectionStatus = [[ARMGameServerCommunicator sharedInstance] connectionStatus];
    if (futureSections != previousSections)
    {
        [gameSessionsTableView beginUpdates];
        if (futureSections == 2) // if we are adding a section to the top
        {
            NSArray *playersArray = [[ARMGameServerCommunicator sharedInstance] playersInSessionArray];
            NSMutableArray *indexPathsArray = [NSMutableArray new];
            for (NSInteger index = 0; index < [gameSessionsTableView numberOfRowsInSection:0]; index += 1)
            {
                if (index != selectedCellNumber)
                {
                    [indexPathsArray addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                }
            }
        
            [gameSessionsTableView deleteRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [gameSessionsTableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            indexPathsArray = [NSMutableArray new];
            
            [playersArray enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
                [indexPathsArray addObject:[NSIndexPath indexPathForRow:index inSection:1]];
                
            }];
            
            [gameSessionsTableView insertRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else // else we are removing the second section
        {
            [gameSessionsTableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
       // [gameSessionsTableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:indexRange] withRowAnimation:UITableViewRowAnimationAutomatic];
        [gameSessionsTableView endUpdates];
    }
    [gameSessionsTableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:indexRange] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addRefreshControl
{
    if (!self.refreshControl)
    {
        self.refreshControl = [UIRefreshControl new];
        [self.refreshControl addTarget:self action:@selector(refreshControlDidActivate:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void)removeRefreshControl
{
    if (self.refreshControl)
    {
        self.refreshControl = nil;
    }
}

- (void)refreshControlDidActivate:(id)sender
{
    [self.refreshControl endRefreshing];
    switch ((GameServerConnectionStatus)[[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
            // Cases where we want to try logging in again
        case kFailedToConnectToServer:
        case kNotInitialized:
        case kNotConnectedToGameServer:
            NSLog(@"RE attempting to log in");
            [[ARMGameServerCommunicator sharedInstance] loginWithCompletionHandler:nil];
            break;
            
            // Reload the available game sessions
        case kLoggedIn:
            NSLog(@"Refreshing game sessions");
            [[ARMGameServerCommunicator sharedInstance] getAllGameSessionsWithCompletionHandler:nil];
            break;
            
            // Reload the session info
        case kInGameSession:
            NSLog(@"Refreshing session info");
            [[ARMGameServerCommunicator sharedInstance] getCurrentSessionInfoWithCompletionHandler:nil];
            break;
            
        case kLeavingGameSession:
        case kRefreshingSessionInfo:
        case kRetrievingSessionInfo:
        case kDownloadingPlayerProfiles:
        case kLoggingIn:
        case kLoggingOut:
        case kSendingImage:
        case kRetrievingGameSessions:
        case kJoiningGameSession:
        case kCreatingGameSession:
        default:
            return;
            break;
    }
    
    // By now we have started our own activity indicators, so we can stop this one now.
    dispatch_async(dispatch_get_main_queue(), ^{[self refreshDisplayWithAnimation];});        // Call this with dispatch so we execute it after the event has ended
    // if we don't dispatch, the refresh control will throw an Exception and crash the application
}

- (void)showCreateGameBarButtonItem
{
    [self showRightBarButtonItemWithBool:NO];
}

- (void)showLeaveGameBarButtonItem
{
    [self showRightBarButtonItemWithBool:YES];
}

- (void)showRightBarButtonItemWithBool:(BOOL)shouldShowLeaveGameButton
{
    UIBarButtonItem *newBarButtonItem;
    if (shouldShowLeaveGameButton)
    {
        if (!self.isShowingLeaveGameButton || !self.rightBarButtonItem)
        {
            newBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[kBarButtonItemLeaveGameTitle copy] style:UIBarButtonItemStylePlain target:self action:@selector(userDidPressBarButtonItem:)];
            self.isShowingLeaveGameButton = YES;
        }
    }
    else
    {
        if (self.isShowingLeaveGameButton || !self.rightBarButtonItem)
        {
            newBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(userDidPressBarButtonItem:)];
            self.isShowingLeaveGameButton = NO;
        }
    }
    
    if (newBarButtonItem)
    {
        [[self navigationItem] setRightBarButtonItem:newBarButtonItem animated:YES];
        self.rightBarButtonItem = newBarButtonItem;
    }
    else
    {
        [self rightBarButtonItemShouldBeEnabled:YES];
    }
}

- (void)rightBarButtonItemShouldBeEnabled:(BOOL)shouldEnableBarButtonItem
{
    if (!self.rightBarButtonItem) return;
    
    if (shouldEnableBarButtonItem)
    {
        if (!self.rightBarButtonItem.enabled)
        {
            [self.rightBarButtonItem setEnabled:YES];
        }
    }
    else
    {
        if (self.rightBarButtonItem.enabled)
        {
            [self.rightBarButtonItem setEnabled:NO];
        }
    }
}

- (void)hideRightNavigationBarButtonItem
{
    if (self.rightBarButtonItem)
    {
        self.rightBarButtonItem = nil;
        [[self navigationItem] setRightBarButtonItem:nil animated:YES];
    }
}

//-------------- ARMGameServerCommunicatorDelegate Protocol ----------------//
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
    [self refreshDisplayWithAnimation];
}

#pragma mark - Networking Methods
/****************************************************************************/
/*                        Networking Methods                                */
/****************************************************************************/

- (void)handleNetworkingError:(NSError *)error
{
    [self handleNetworkingError:error withTitle:nil];
}

- (void)handleNetworkingError:(NSError *)error withTitle:(const NSString *)titleString
{
#warning Incomplete Implementation without error recovery
    NSString *errorString;
    @try
    {
        if ([[error domain] isEqualToString:[ARMGameServerErrorDomain copy]])
        {
            switch ((GameServerConnectionStatus)[error code])
            {
                case ARMInvalidPostDataErrorCode:
                    errorString = @"Your information is incorrect. Please provide a valid user name to log in to the server.";
                    break;
                
                case ARMInvalidPutDataErrorCode:
                    errorString = @"Your profile image is invalid.";
                    break;
                    
                case ARMNoInternetConnectionErrorCode:
                    errorString = @"You are not connected to the internet\nPlease connect and try again";
                    break;
                    
                case ARMServerUnreachableErrorCode:
                    errorString = @"The GameServer is unreachable at this time.\nPlease try again later.";
                    break;
                    
                case ARMInvalidServerResponseErrorCode:
                    errorString = @"The server provided an invalid response\nPlease try again.";
                    break;
                    
                case ARMUnkownErrorCode:
                default:
                    errorString = @"An unknown networking error occured\nPlease try again";
                    break;
            }
        }
        else
        {
            errorString = @"An unknown error has occurred.\nPlease try again";
        }
    }
    @catch (NSException *e)
    {
        errorString = @"Unknown Error";
    }
    
    [[[UIAlertView alloc] initWithTitle:(titleString != nil ? [titleString copy]: @"Network Error")
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
        [[ARMGameServerCommunicator sharedInstance] leaveSessionWithCompletionHandler:nil];
        [self refreshDisplayWithAnimation];
    }
    else // otherwise we will be creating a game
    {
        [self performSegueWithIdentifier:@"CreateGameSegue" sender:self];
    }
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
    
    selectedCellNumber = indexPath.row;
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:[[selectedCell accessoryView] frame]];
    [spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [spinner setHidesWhenStopped:YES];
    [spinner startAnimating];
    [selectedCell setAccessoryView:spinner];
    
    self.selectedCellActivityIndicator = spinner;
    
    [[ARMGameServerCommunicator sharedInstance] joinSessionWithIndex:[indexPath row] completionHandler:nil];
}


#pragma mark - TableView Delegate/Datasource
/****************************************************************************/
/*                  TableView Delegate/Datasource Methods                   */
/****************************************************************************/

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *sectionHeaderView;
    ARMTableHeaderViewWithActivityIndicator *armSectionHeaderView;
    if (section == 0)
    {
        
        //---------    First: Dequeue the view if it is available    --------//
        armSectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[ARMReuseIdentifierForTableViewHeaderWithActivityIndicator copy]];
        armSectionHeaderView.titleLabel.text = [[self tableView:nil titleForHeaderInSection:section] uppercaseString];
        networkActivityIndicator = armSectionHeaderView.activityIndicator;
        
        if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible])
        {
            [networkActivityIndicator startAnimating];
        }
        
        sectionHeaderView = (UITableViewHeaderFooterView *)armSectionHeaderView;
    }
    else
    {
        sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[ARMReuseIdentifierForDefaultTableViewHeader copy]];
        if (!sectionHeaderView)
        {
            sectionHeaderView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:[ARMReuseIdentifierForDefaultTableViewHeader copy]];
        }
    }
   
    return (UITableViewHeaderFooterView *)sectionHeaderView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
        case kInGameSession:
        case kRetrievingSessionInfo:
        case kDownloadingPlayerProfiles:
        case kRefreshingSessionInfo:
            return 2;       // list [Current session, current players]
            break;
            
        default:
            return 1;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger count = 0;
    switch ([[ARMGameServerCommunicator sharedInstance] connectionStatus])
    {
            // display Current game session at the top, and the players in the bottom
        case kInGameSession:
        case kDownloadingPlayerProfiles:
        case kRetrievingSessionInfo:
        case kRefreshingSessionInfo:
            if (section == 0)
            {
                return 1;               // Display the current session
            }
            else
            {
                return [[ARMGameServerCommunicator sharedInstance] playersInSessionArray].count;
            }
            break;
            
        case kLoggedIn:
        case kLoggingOut:
        case kLeavingGameSession:
        case kJoiningGameSession:
        case kRetrievingGameSessions:
        case kCreatingGameSession:
            count = [[[ARMGameServerCommunicator sharedInstance] availableGameSessions] count];
            if (count == 0)
            {
                return 1;       // Show a "no available sessions" cell
            }
            else
            {
                return count;
            }
            break;
           
        default:
            return 0;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && tableView) return @" ";
    NSString *titleForHeader;
    
    if (![[ARMPlayerInfo sharedInstance] isReadyForLogin])
    {
        titleForHeader = @"Not Ready to Log in";
    }
    else
    {
        switch ((GameServerConnectionStatus)[[ARMGameServerCommunicator sharedInstance] connectionStatus])
        {
            case kFailedToConnectToServer:
                titleForHeader = @"Unable to connect to Server";
                break;
                
            case kLoggedIn:
            case kRetrievingGameSessions:
            case kJoiningGameSession:
            case kCreatingGameSession:
                titleForHeader = @"Available Games";
                break;
                
            case kInGameSession:
            case kRetrievingSessionInfo:
            case kRefreshingSessionInfo:
            case kDownloadingPlayerProfiles:
            case kLeavingGameSession:
                if (section == 0)
                {
                    titleForHeader = @"Current Game";
                }
                else
                {
                    titleForHeader = @"Players";
                }
                break;
                
            case kLoggingIn:
            case kLoggingOut:
            case kSendingImage:
            case kNotInitialized:
            case kNotConnectedToGameServer:
            default:
                titleForHeader = @"Not connected to Server";
                break;
                
        }
    }
    return titleForHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *leaveGamePrompt = @"Tap 'Leave Game' to join another game";
    NSString *refreshPrompt =   @"Pull down to refresh";
    
    NSString *titleForFooter;
    ARMPlayerInfo *playerInfo = [ARMPlayerInfo sharedInstance];
    if (![playerInfo isReadyForLogin])
    {
        if (!playerInfo.playerDisplayName)
        {
            titleForFooter = @"Edit your profile: add a Username";
        }
        else if (!playerInfo.playerDisplayImage)
        {
            titleForFooter = @"Edit your profile: add a Profile Picture";
        }
        else if (!playerInfo.gameTileImageTargetID)
        {
            titleForFooter = @"Connect to a GameTile";
        }
    }
    else
    {
        switch ((GameServerConnectionStatus)[[ARMGameServerCommunicator sharedInstance] connectionStatus])
        {
            case kFailedToConnectToServer:
                titleForFooter = @"Pull down to try again";
                break;
                
            case kLoggingIn:
                titleForFooter = @"Logging in to Game Server...";
                break;
                
            case kLoggingOut:
                titleForFooter = @"Logging out of Game Server...";
                break;
                
            case kSendingImage:
                titleForFooter = @"Uploading profile to Game Server...";
                break;
            
            case kRetrievingGameSessions:
                titleForFooter = @"Retrieving games from server...";
                break;
                
            case kJoiningGameSession:
                titleForFooter = @"Attempting to join game...";
                break;
                
            case kCreatingGameSession:
                titleForFooter = @"Attempting to create new game...";
                break;
                
            case kInGameSession:
                if (section == 0)
                {
                    titleForFooter = leaveGamePrompt;
                    break;
                }
                else
                {
                    titleForFooter = refreshPrompt;
                }
                break;
                
            case kLoggedIn:
                titleForFooter = refreshPrompt;
                break;
            
            case kRefreshingSessionInfo:
            case kRetrievingSessionInfo:
                if (section == 0)
                {
                    titleForFooter = leaveGamePrompt;
                }
                else
                {
                    titleForFooter = @"Retrieving Game Information...";
                }
                break;
                
            case kDownloadingPlayerProfiles:
                if (section == 0)
                {
                    titleForFooter = leaveGamePrompt;
                }
                else
                {
                    titleForFooter = @"Downloading Player Profiles...";
                }
                break;
                
            case kLeavingGameSession:
                if (section == 0)
                {
                    titleForFooter = @"Leaving Game...";
                }
                else
                {
                    titleForFooter = refreshPrompt;
                }
                break;
                
            case kNotInitialized:
            case kNotConnectedToGameServer:
            default:
                titleForFooter = @"Pull down to login";
                break;
                
        }
    }
    
    return titleForFooter;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *GameSessionCellIdentifier = @"GameSessionCell";
    static NSString *PlayerCellIdentifier = @"PlayerCell";

    UITableViewCell *cell;
    NSString *text;
    
    // Configure the cell...
    ARMGameServerCommunicator *gameServerComm = [ARMGameServerCommunicator sharedInstance];
    if ([gameServerComm currentSessionName])
    {
        if (indexPath.section == 0)     // Display the current game session at the top
        {
            cell = [tableView dequeueReusableCellWithIdentifier:GameSessionCellIdentifier forIndexPath:indexPath];
            
            [(UILabel *)[cell viewWithTag:kTableCellTagForGameSessionTitleLabel] setText:[gameServerComm currentSessionName]];
            [[cell viewWithTag:kTableCellTagForGameSessionCheckmark] setHidden:NO];
            
            [cell setUserInteractionEnabled:NO];
        }
        else    // display the Current players below
        {
            cell = [tableView dequeueReusableCellWithIdentifier:PlayerCellIdentifier forIndexPath:indexPath];
            NSArray *playersArray = [gameServerComm playersInSessionArray];
            
            if ([playersArray count] == 0)
            {
                text = @"Waiting for players...";
            }
            else
            {
                text = [(ARMNetworkPlayer *)[playersArray objectAtIndex:indexPath.row] playerName];
            }
            [cell.textLabel setText:text];
            
            [cell setUserInteractionEnabled:NO];
        }
    }
    else
    {   // Display a current game session
        cell = [tableView dequeueReusableCellWithIdentifier:GameSessionCellIdentifier forIndexPath:indexPath];
        
        NSArray *availableGameSessions = [[ARMGameServerCommunicator sharedInstance] availableGameSessions];
        if ([availableGameSessions count] == 0)
        {
            text = @"No Games Available";
        }
        else
        {
            text = [(ARMGameSession *)availableGameSessions[indexPath.row] name];
        }
        
        // Set Our custom Label
        [(UILabel *)[cell viewWithTag:kTableCellTagForGameSessionTitleLabel] setText:text];
        
        // Hide the Checkmark because this cell is not selected
        [[cell viewWithTag:kTableCellTagForGameSessionCheckmark] setHidden:YES];
        
        // Allow the user to select this cell
        [cell setUserInteractionEnabled:YES];
    }
    
    return cell;
}


@end
