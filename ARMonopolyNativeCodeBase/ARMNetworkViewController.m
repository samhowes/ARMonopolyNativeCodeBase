//
//  ARMNetworkViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/26/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMNetworkViewController.h"

static NSString     *kGameServerURLString = @"http://172.18.0.173:3000";
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

@property (strong, nonatomic) IBOutlet UITableView *gameSessionsTableView;

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionConfiguration *sessionConfig;
    
@end

void throwError(NSError *error) {
    @throw [NSException exceptionWithName:[error domain] reason:[error localizedFailureReason] userInfo:[error userInfo]];
}

@implementation ARMNetworkViewController

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
      @"singleGameSession": [NSString stringWithFormat:@"/game_sessions/%%@"]    // The sessionID will be inserted here
      };
    
    kGameServerPostParameters =
    @{
      @"username": @"username",
      @"deviceID": @"gameTileID"
      };
    kGameServerReturnParameters =
    @{
      @"error": @"Error",
      @"gameSessions": @"activeSessions"
      };
    kGameServerSessionObjectKeys =
    @{
      @"name":  @"name",
      @"id":    @"id"
      };
    
    connectionStatus = kNotInitialized;
    
    // make sure we can accept the server's session cookie
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    _sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [_sessionConfig setHTTPAdditionalHeaders:@{@"User-Agent":@"armonopoly_ios", @"Accept": @"application/json"}];
    [_sessionConfig setAllowsCellularAccess:YES];
    [_sessionConfig setTimeoutIntervalForRequest:30.0];
    [_sessionConfig setTimeoutIntervalForResource:60.0];
    [_sessionConfig setHTTPMaximumConnectionsPerHost:1];
    _session = [NSURLSession sessionWithConfiguration:_sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];

    [self connectToGameServer];
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
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSMutableString *titleForHeader = [NSMutableString stringWithString:@"Not connected to Game Server"];
    switch (connectionStatus) {
        case kNotInitialized:
            // Don't change the string
            break;
        case kConnectingToServer:
            [titleForHeader setString:@"Connecting to Game Server"];
            break;
        case kSendingProfile:
            [titleForHeader setString:@"Sending profile to Game Server"];
            break;
        case kRetrievingGameSessions:
            [titleForHeader setString:@"Retrieving active sessions"];
            break;
        case kConnectedToServer:
            [titleForHeader setString:@"Select a session"];
            break;
        case kFailedToConnectToServer:
            [titleForHeader setString:@"Error connecting to Game Server"];
            break;
        default:
            // don't change the original string
            break;
    }
    [titleForHeader appendString:@"..."];
    return titleForHeader;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (connectionStatus == kConnectedToServer)
    {
        return @"Tap '+' to create your own";
    } else {
        return nil;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [availableGameSessions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GameSessionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [availableGameSessions[indexPath.row] objectForKey:kGameServerSessionObjectKeys[@"name"]];
    
    return cell;
}

#pragma mark - Networking Methods
/****************************************************************************/
/*							Networking Metods                               */
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
    [userData setGameTileBluetoothID:   @"12"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // Prepare the endpoint string
    NSURL *loginURL = [NSURL URLWithString:kGameServerEndpointURLStrings[@"login"] relativeToURL:kGameServerURL];
    
    NSMutableURLRequest *loginRequest = [NSMutableURLRequest requestWithURL:loginURL];
    [loginRequest setHTTPMethod:@"POST"];
    
    // Prepare the data to POST to the server
    NSError *jsonError;
    NSDictionary *postBodyDictionary =
        @{
          kGameServerPostParameters[@"username"]: [userData playerDisplayName],
          kGameServerPostParameters[@"deviceID"]: [userData gameTileBluetoothID]
          };
    
    // Serialize our dictionary
    NSData *postBodyData = [NSJSONSerialization
                            dataWithJSONObject:postBodyDictionary
                            options:NSJSONWritingPrettyPrinted
                            error:&jsonError];
    assert(!jsonError);
    
    [loginRequest setHTTPBody:postBodyData];
    
    NSURLSessionDataTask *loginTask = [self.session dataTaskWithRequest:loginRequest
                                                      completionHandler:^(NSData *data,
                                                                          NSURLResponse *response,
                                                                          NSError *error)
    {
        assert(!jsonError);
        dispatch_async(dispatch_get_main_queue(),
            ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200)
                {
                    [self getSessionsFromGameServer];
                }
                else
                {
                    [self gameServerDidRespondWithError:(NSError*)error
                                               response:(NSHTTPURLResponse *)response
                                                   data:data];
                }
            });
    }];
    
    [loginTask resume];
}

/* Step 2: PUT to /images/<clientID>.png */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
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
    
    
    NSLog(@"Redirect URL: %@", [[request URL] absoluteString]);
    assert([[request URL] isEqual:[urlWeShouldBeRedirectedTo absoluteURL]]);
    
    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[request URL]];
    [newRequest setHTTPMethod:@"PUT"];
    [newRequest setHTTPBody:[@"HEY! This works!" dataUsingEncoding:NSUTF8StringEncoding]];
    
    request = newRequest;
    
    completionHandler(request);     // allow the modified redirect
}


-(void)getSessionsFromGameServer
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
                [availableGameSessions addObject:
                 @{
                   @"name": gameSession[kGameServerSessionObjectKeys[@"name"]],
                   @"id":   gameSession[kGameServerSessionObjectKeys[@"id"]]
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
        jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        if (jsonError) throwError(jsonError);
        errorString = jsonData[kGameServerReturnParameters[@"error"]];
    }
    @catch (NSException *e) {
        errorString = @"Unknown Error";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                message:errorString
                               delegate:nil
                      cancelButtonTitle:@"Dismiss"
                      otherButtonTitles:nil] show];
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
