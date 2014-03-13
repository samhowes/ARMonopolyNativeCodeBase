//
//  ARMNetworkViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/26/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMNetworkViewController.h"
#import "ARMNetworkPlayer.h"

#define kCurrentPlayerNameKey           @"name"
#define kCurrentPlayerDeviceIDKey       @"deviceID"
#define kCurrentPlayerImageURLKey       @"imageURL"
#define kBarButtonItemLeaveGameTitle    @"Leave Game"

static NSString     *kGameServerURLString = @"http://111.18.0.252:3000";
static NSURL        *kGameServerURL;
static NSDictionary *kGameServerEndpointURLStrings;
static NSString     *kGameServerClientCookieName = @"clientID";
static NSDictionary *kGameServerPostParameters;
static NSDictionary *kGameServerReturnParameters;
static NSDictionary *kGameServerSessionObjectKeys;


@interface ARMNetworkViewController () {
    NSMutableArray *availableGameSessions;
    GameServerConnectionStatus connectionStatus;
}

@property (retain, nonatomic) IBOutlet UIBarButtonItem *rightNavigationBarButtonItem;

@property (strong, nonatomic) IBOutlet UITableView *gameSessionsTableView;

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionConfiguration *sessionConfig;
    
@end

void throwError(NSError *error) {
    @throw [NSException exceptionWithName:[error domain] reason:[error localizedFailureReason] userInfo:[error userInfo]];
}

@implementation ARMNetworkViewController

@synthesize rightNavigationBarButtonItem;
@synthesize gameSessionsTableView;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    availableGameSessions = [[NSMutableArray alloc] init];
    kGameServerURL = [NSURL URLWithString:kGameServerURLString];
    kGameServerEndpointURLStrings =
    @{
      @"login":             [NSString stringWithFormat:@"/login"],
      @"images":            [NSString stringWithFormat:@"/images/%%@.png"],   // The clientID will be inserted here
      @"allGameSessions":   [NSString stringWithFormat:@"/game_sessions"],
      @"joinGameSession":   [NSString stringWithFormat:@"/game_sessions/join"]    // The sessionID will be inserted here
      };
    
    kGameServerPostParameters =
    @{
      @"username": @"username",
      @"deviceID": @"gameTileID",
      @"sessionID": @"sessionID"
      };
    kGameServerReturnParameters =
    @{
      @"error": @"Error",
      @"gameSessions": @"activeSessions"
      };
    kGameServerSessionObjectKeys =
    @{
      @"name":          @"sessionName",
      @"id":            @"sessionID",
      @"currentPlayers":@"currentPlayers"
      };
    
    connectionStatus = [[ARMPlayerInfo sharedInstance] lastConnectionStatus];
    
    // make sure we can accept the server's session cookie
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    _sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [_sessionConfig setHTTPAdditionalHeaders:@{@"User-Agent":@"armonopoly_ios", @"Accept": @"application/json"}];
    [_sessionConfig setAllowsCellularAccess:YES];
    [_sessionConfig setTimeoutIntervalForRequest:30.0];
    [_sessionConfig setTimeoutIntervalForResource:60.0];
    [_sessionConfig setHTTPMaximumConnectionsPerHost:1];
    _session = [NSURLSession sessionWithConfiguration:_sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];

    switch (connectionStatus)
    {
        case kNotInitialized:
        case kConnectingToServer:
            [self connectToGameServer];
            break;
            
        case kSendingProfile:
            [self connectToGameServer];     // TODO add ARMGameServerDelegate Class with more sophisticated methods
            
        case kConnectedToServer:
        case kJoiningGameSession:
        case kRetrievingGameSessions:
            [self getSessionsFromGameServer];
            break;
        
        case kInGameSession:
            [self getCurrentPlayersInGameSession];
            break;
            
        case kFailedToConnectToServer:
        default:
            [self connectToGameServer];
            break;
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [[ARMPlayerInfo sharedInstance] setLastConnectionStatus:connectionStatus];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/****************************************************************************/
/*							TableView Delegate                              */
/****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (connectionStatus == kInGameSession)
    {
        return 2;   // list the current session in one section, and the current players in the other
    }
    else
    {
        return 1;   // List the available game sessions
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    NSMutableString *titleForHeader = [NSMutableString stringWithString:@"Not connected to Game Server"];
    switch (connectionStatus) {
        case kNotInitialized:
            // Don't change the string
            break;
        case kConnectingToServer:
            [titleForHeader setString:@"Connecting to Game Server..."];
            break;
        case kSendingProfile:
            [titleForHeader setString:@"Sending profile to Game Server..."];
            break;
        case kRetrievingGameSessions:
            [titleForHeader setString:@"Retrieving active sessions..."];
            break;
        case kConnectedToServer:
            [titleForHeader setString:@"Select a session..."];
            break;
        case kInGameSession:
            if (section == 0)
            {
                [titleForHeader setString:@"Current Game Session"];
            }
            else
            {
                [titleForHeader setString:@"Current Players"];
            }
            break;
        case kFailedToConnectToServer:
            [titleForHeader setString:@"Error connecting to Game Server!"];
            break;
        default:
            // don't change the original string
            break;
    }
    return titleForHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (connectionStatus == kConnectedToServer)
    {
        return @"Tap '+' to create your own";
    } else if (connectionStatus == kInGameSession && section == 0) {
        return @"Tap 'Leave' to join a different session";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (connectionStatus == kInGameSession)
    {
        if (section == 0)
        {
            return 1;       // just display the current game session
        }
        else {
            return [[[ARMPlayerInfo sharedInstance] playersInSessionArray] count];
        }
    }
    else
    {
        return [availableGameSessions count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GameSessionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (connectionStatus == kInGameSession)
    {
        if (indexPath.section == 0) // Display the current game session at the top
        {
            cell.textLabel.text = [[ARMPlayerInfo sharedInstance] sessionName];
            [cell setUserInteractionEnabled:NO];
        }
        else    // display the Current players below
        {
            cell.textLabel.text = [[[[ARMPlayerInfo sharedInstance] playersInSessionArray]
                                    objectAtIndex:indexPath.row] playerName];
            [cell setUserInteractionEnabled:NO];
        }
    }
    else
    {
        cell.textLabel.text = [availableGameSessions[indexPath.row] objectForKey:kGameServerSessionObjectKeys[@"name"]];
    }
    
    return cell;
}

//------------------------------------------ User Input
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (connectionStatus == kJoiningGameSession ||
        connectionStatus == kInGameSession)
    {
        return; // do nothing if we are already joining a game session, or in a game session
    }
    connectionStatus = kJoiningGameSession;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:[[selectedCell accessoryView] frame]];
    [spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [spinner setHidesWhenStopped:YES];
    [spinner startAnimating];
    [selectedCell setAccessoryView:spinner];
    
    [self joinGameServerSessionWithIndex:indexPath.row completionHandler:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [spinner stopAnimating];
            
            rightNavigationBarButtonItem  = [[UIBarButtonItem alloc]
                                             initWithTitle:kBarButtonItemLeaveGameTitle
                                             style:UIBarButtonItemStylePlain target:self
                                             action:@selector(userDidPressBarButtonItem:)];
            
            [tableView reloadData]; //BOOKMARK
            
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
        });
    }];
}

- (IBAction)userDidPressBarButtonItem:(id)sender
{
    if (connectionStatus == kInGameSession)
    {
        [self leaveGameServerSession];
        rightNavigationBarButtonItem = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                        target:self
                                        action:@selector(userDidPressBarButtonItem:)];
    }
    else
    {
        [self createGameServerSession];
    }
}

#pragma mark - Networking Methods
/****************************************************************************/
/*                          Networking Methods                              */
/****************************************************************************/

//------------------------------------------ Login Methods
/* Step 1: POST to /login */
- (void)connectToGameServer
{
    ARMPlayerInfo *userData = [ARMPlayerInfo sharedInstance];
   /* if (![userData isReadyForLogin])
    {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                   message:@"Complete Steps 1 and 2 before connecting to the Game Server"
                                   delegate:nil
                         cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil] show];
        return;
    }*/
    
    connectionStatus = kConnectingToServer;
    
    [userData setPlayerDisplayName:     @"Sam"];
    [userData setGameTileImageTargetID:   @"12"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // Prepare the data to POST to the server
    NSError *jsonError;
    
    // Serialize our dictionary
    NSData *postBodyData = [NSJSONSerialization
                            dataWithJSONObject:@{
                                                 kGameServerPostParameters[@"username"]: [userData playerDisplayName],
                                                 kGameServerPostParameters[@"deviceID"]: [userData gameTileImageTargetID]
                                                 }
                            options:NSJSONWritingPrettyPrinted
                            error:&jsonError];
    assert(!jsonError);
    
    NSMutableURLRequest *loginRequest =
            [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kGameServerEndpointURLStrings[@"login"]
                                                       relativeToURL:kGameServerURL]];
    
    [loginRequest setHTTPMethod:@"POST"];
    [loginRequest setHTTPBody:postBodyData];
    
    NSURLSessionDataTask *loginTask =
            [self.session dataTaskWithRequest:loginRequest
                            completionHandler:^(NSData *data,
                                                NSURLResponse *response,
                                                NSError *error)
    {
        dispatch_async(dispatch_get_main_queue(),
            ^{
                // In the successful case, we will be redirected, and called after a successful login
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200)
                {
                    [self getSessionsFromGameServer];
                }
                else
                {
                    [self gameServerDidRespondWithError:(NSError*)error
                                               response:httpResponse
                                                   data:data];
                }
            });
    }];
    
    [loginTask resume];
}

/* Step 2: PUT to /images/<clientID>.png */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                    willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse
                                    newRequest:(NSURLRequest *)request
                             completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    connectionStatus = kSendingProfile;
    
    // NSHTTPCookieStorage should automatically handle our session cookie.
    // This should be redirecting us to /image/client.png
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kGameServerURLString]];
    NSLog(@"After the first sever response we have %d cookies", (int)[cookies count]);
    assert([cookies count] == 1);
    NSHTTPCookie *clientIDCookie = cookies[0];
    NSLog(@"Cookie with name %@ recieved, with value: %@", [clientIDCookie name], [clientIDCookie value]);
    assert([[clientIDCookie name] isEqualToString:kGameServerClientCookieName]);
    
    NSURL *urlWeShouldBeRedirectedTo = [NSURL URLWithString:
                                        [NSString stringWithFormat:kGameServerEndpointURLStrings[@"images"],[clientIDCookie value]]
                                              relativeToURL:kGameServerURL];
    
    [[ARMPlayerInfo sharedInstance] setClientID:[clientIDCookie value]];
    
    NSLog(@"Redirect URL: %@", [[request URL] absoluteString]);
    assert([[request URL] isEqual:[urlWeShouldBeRedirectedTo absoluteURL]]);
    
    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[request URL]];
    [newRequest setHTTPMethod:@"PUT"];
    [newRequest setHTTPBody:[@"HEY! This works!" dataUsingEncoding:NSUTF8StringEncoding]];
    
    request = newRequest;
    
    completionHandler(request);     // allow the modified redirect
}

- (void)getSessionsFromGameServer
{
    connectionStatus = kSendingProfile;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURL *getGameSessionsURL = [NSURL URLWithString:kGameServerEndpointURLStrings[@"allGameSessions"] relativeToURL:kGameServerURL];
    NSURLSessionDataTask *getGameSessionsTask =
        [_session dataTaskWithURL:getGameSessionsURL completionHandler:
                            ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        // Populate the UI with the found game sessions
        NSDictionary *jsonData;
        NSError *jsonError;
        if (error) {
            [self networkingErrorDidOccur:error];
            //TODO: Recover somehow
            return;
        }
        
        @try {
            jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) throwError(jsonError);
            for (NSDictionary *gameSession in jsonData[kGameServerReturnParameters[@"gameSessions"]]) {
                NSString *sessionName = gameSession[kGameServerSessionObjectKeys[@"name"]];
                NSNumber *sessionID =   gameSession[kGameServerSessionObjectKeys[@"id"]];
                
                [availableGameSessions addObject:
                 @{
                   kGameServerSessionObjectKeys[@"name"]:   sessionName,
                   kGameServerSessionObjectKeys[@"id"]:     sessionID
                   }];
            }
            connectionStatus = kConnectedToServer;
            dispatch_async(dispatch_get_main_queue(), ^{
                [gameSessionsTableView reloadData];
            });
            
        }
        @catch (NSException *e) {
            [self gameServerDidProduceError:@"Invalid JSON Session objects"];
        }
    }];
    [getGameSessionsTask resume];
}

- (void)joinGameServerSessionWithIndex:(NSInteger)sessionIndex completionHandler:(void (^)(BOOL))completionHandler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSDictionary *bodyDict = @{
                               kGameServerPostParameters[@"sessionID"]:
                                   [availableGameSessions[sessionIndex] objectForKey:kGameServerSessionObjectKeys[@"id"]]
                               };
    NSError *jsonError;
    NSData *postBody = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&jsonError];
    
    assert(!jsonError);
    
    NSMutableURLRequest *joinSessionRequest =
            [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kGameServerEndpointURLStrings[@"joinGameSession"]
                                                       relativeToURL:kGameServerURL]];
    [joinSessionRequest setHTTPMethod:@"POST"];
    [joinSessionRequest setHTTPBody:postBody];
    
    NSURLSessionDataTask *joinSessionTask = [_session dataTaskWithRequest:joinSessionRequest
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        /**      Error Checking      **/
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self gameServerDidRespondWithError:error response:httpResponse data:data];
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
        
        /**      Process the actual response      **/
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) throwError(jsonError);
        @try {
            ARMPlayerInfo *userData = [ARMPlayerInfo sharedInstance];
            [userData setSessionID:jsonData[kGameServerSessionObjectKeys[@"id"]]];
            [userData setSessionName:jsonData[kGameServerSessionObjectKeys[@"name"]]];
            
            /**      Store the received data in ARMPlayerInfo      **/
            NSMutableArray *currentPlayersArray = [NSMutableArray new];
            NSArray *currentPlayersJSON = jsonData[kGameServerSessionObjectKeys[@"currentPlayers"]];
            for (NSDictionary *player in currentPlayersJSON)
            {
                NSURL *networkURL = [NSURL URLWithString:player[kCurrentPlayerImageURLKey]];
                
                [currentPlayersArray addObject:
                 [[ARMNetworkPlayer alloc] initWithName:player[kCurrentPlayerNameKey]
                                  gameTileImageTargetID:player[kCurrentPlayerDeviceIDKey]
                                        imageNetworkURL:networkURL]];
            }
            
            
            [userData setPlayersInSessionArray:currentPlayersArray];
            connectionStatus = kInGameSession;
            /**      Complete the specified task      **/
            if (completionHandler) completionHandler(YES);
            
            
        } /**      Display a standard message to the user for errors      **/
        @catch (NSException *e) {
            [self gameServerDidProduceError:@"Invalid server JSON response"];
            if (completionHandler) completionHandler(NO);
        }
    
    
    }];
    
    [joinSessionTask resume];
}

- (void)createGameServerSession
{
    connectionStatus = kCreatingGameSession;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSURL *createSessionURL = [NSURL URLWithString:kGameServerCreateSessionURLString
                                         relativeToURL:[NSURL URLWithString:ARMGameServerURLString]];
    NSDictionary *postBodyJSONObject =
        @{
          kGameServerCreateSessionPostBodyKey: [NSString stringWithFormat:@"%@'s Game", [[ARMPlayerInfo sharedInstance] playerName]]
          };
    NSError *jsonError;
    NSData *postBodyData = [NSJSONSerialization dataWithJSONObject:postBodyJSONObject options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonError) throwError(jsonError);
    NSMutableURLRequest *createSessionRequest = [NSMutableURLRequest requestWithURL:createSessionURL];
    [createSessionRequest setHTTPMethod:@"POST"];
    [createSessionRequest setHTTPBody:postBodyData];
    NSURLSessionDataTask *createSessionTask = [_session dataTaskWithRequest:createSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        /**      Error Checking      **/
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self gameServerDidRespondWithError:error response:httpResponse data:data];
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
        
        /**      Process the actual response      **/
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) throwError(jsonError);
        @try {
            ARMPlayerInfo *userData = [ARMPlayerInfo sharedInstance];
            [userData setSessionID:jsonData[kGameServerSessionObjectKeys[@"id"]]];
            [userData setSessionName:jsonData[kGameServerSessionObjectKeys[@"name"]]];
            
            /**      Store the received data in ARMPlayerInfo      **/
            NSMutableArray *currentPlayersArray = [NSMutableArray new];
            NSArray *currentPlayersJSON = jsonData[kGameServerSessionObjectKeys[@"currentPlayers"]];
            for (NSDictionary *player in currentPlayersJSON)
            {
                NSURL *networkURL = [NSURL URLWithString:player[kCurrentPlayerImageURLKey]];
                
                [currentPlayersArray addObject:
                 [[ARMNetworkPlayer alloc] initWithName:player[kCurrentPlayerNameKey]
                                  gameTileImageTargetID:player[kCurrentPlayerDeviceIDKey]
                                        imageNetworkURL:networkURL]];
            }
            
            
            [userData setPlayersInSessionArray:currentPlayersArray];
            connectionStatus = kInGameSession;
            /**      Complete the specified task      **/
            
        } /**      Display a standard message to the user for errors      **/
        @catch (NSException *e) {
            [self gameServerDidProduceError:@"Invalid server JSON response"];
        }
    }];
    [createSessionTask resume];
    
    
}

- (void)leaveGameServerSession
{
    
}

- (void)getCurrentPlayersInGameSession
{
    //TODO
}


//------------------------------------------ Error Methods
-(void)networkingErrorDidOccur:(NSError *)error
{
    connectionStatus = kFailedToConnectToServer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Local Device Network Error"
                                    message:[error localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil] show];
    });

}

-(void)gameServerDidProduceError:(NSString *)errorString
{
    connectionStatus = kFailedToConnectToServer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                    message:errorString
                                   delegate:nil
                          cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil] show];
    });
}

-(void)gameServerDidRespondWithError:(NSError *)error
                            response:(NSHTTPURLResponse *)response
                                data:(NSData *)data
{
    connectionStatus = kFailedToConnectToServer;
    NSString *errorString;
    NSDictionary *jsonData;
    NSError *jsonError;
    @try {
        if (error && [[error domain] isEqualToString:NSURLErrorDomain])      // A local error occured
        {
            switch ([error code])
            {
                case NSURLErrorBadURL:
                case NSURLErrorTimedOut:
                case NSURLErrorUnsupportedURL:
                case NSURLErrorCannotFindHost:
                case NSURLErrorCannotConnectToHost:
                    errorString = [NSString stringWithFormat:@"Cannot connect to Game Server at URL: %@",
                                   [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
                    break;
                case NSURLErrorNotConnectedToInternet:
                    errorString = @"No internet connection";
                    break;
                
                case NSURLErrorBadServerResponse:
                    errorString = @"The server gave an invalid response, try again";
                    break;
                    
                case NSURLErrorUnknown:
                default:
                    errorString = @"Unknown Error";
                    break;
            }
        
        }
        else
        {
            jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) throwError(jsonError);
            errorString = jsonData[kGameServerReturnParameters[@"error"]];
        }
    }
    @catch (NSException *e) {
        errorString = @"Unknown Error";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                message:errorString
                               delegate:nil
                      cancelButtonTitle:@"Dismiss"
                      otherButtonTitles:nil] show];
    [gameSessionsTableView reloadData];
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
