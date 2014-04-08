//
//  ARMGameServerCommunicator.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/13/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARMGameServerCommunicator.h"
#import "ARMPlayerInfo.h"
#import "ARMNetworkPlayer.h"
#import "ARMGameSession.h"
#import "ARMException.h"

/****************************************************************************/
/*                  Initialization of Constants                             */
/****************************************************************************/

//--------------------------- URL/HTTP Constants ---------------------------//
const NSString *ARMGameServerErrorDomain =                      @"ARMGameServerErrorDomain";

const NSString *ARMGameServerURLString =                        @"http://168.122.170.131:3000";
const NSString *kGSHTTPUserAgentHeaderString =                  @"ARMonopoy iOS";
const NSString *kGSHTTPAcceptContentHeaderString =              @"application/json";
const NSString *kGSHTTPClientCookieName =                       @"clientID";


const NSString *kGSLoginEndpointURLString =                     @"/login";
const NSString *kGSLogoutEndpointURLString =                    @"/logout";
const NSString *kGSImagesEndpointURLFormatString =              @"/images/%@.png";
const NSString *kGSActiveSessionsEndpointURLString =            @"/game_sessions";
const NSString *kGSCreateSessionURLString =                     @"/game_sessions/create";
const NSString *kGSJoinSessionEndpointURLString =               @"/game_sessions/join";
const NSString *kGSCreateSessionEndpointURLString =             @"/game_sessions/create";
const NSString *kGSLeaveSessionEndpointURLString =              @"/game_sessions/leave";
const NSString *kGSGetPlayersInSessionEndpointURLFormatString = @"/game_sessions/%@";

//-------------------- HTTP Header Request Constants -----------------------//
const NSString *kGSUploadImageContentTypeHeader =               @"multipart/form-data; boundary=----WebKitFormBoundaryOtZ7JwoUlFLeKECK";//ARMonpolyiOSFormBoundary";
const NSString *kGSUploadImageFormBoundaryHeaderValue =         @"------WebKitFormBoundaryOtZ7JwoUlFLeKECK";//----ARMonpolyiOSFormBoundary";

//---------------------- HTTP Body Request Constants -----------------------//
const NSString *kGSUserNamePostKey =                            @"userName";
const NSString *kGSDeviceIDPostKey =                            @"deviceID";
const NSString *kGSSessionIDPostKey =                           @"sessionID";
const NSString *kGSCreateSessionPostKey =                       @"sessionName";

const NSString *kGSUploadContentDispositionString =             @"Content-Disposition: form-data";
const NSString *kGSUploadFormValueFieldString =                 @"name=\"image\"";
const NSString *kGSUploadFilenameFormatString =                 @"filename=\"%@.png\"";
const NSString *kGSUploadContentTypeString =                    @"Content-Type: image/png";

//--------------------- HTTP Body Response Constants ----------------------//
const NSString *kGSErrorReplyKey =                              @"Error";
const NSString *kGSErrorCodeReplyKey =                          @"code";
const NSString *kGSErrorReasonReplyKey =                        @"reason";
const NSString *kGSErrorDescriptionReplyKey =                   @"description";

const NSString *kGSActiveSessionsReplyKey =                     @"activeSessions";
const NSString *kGSSessionNameReplyKey =                        @"sessionName";
const NSString *kGSSessionIDReplyKey =                          @"sessionID";
const NSString *kGSCurrentPlayersReplyKey =                     @"currentPlayers";
const NSString *kGSPlayerNameReplyKey =                         @"name";
const NSString *kGSPlayerImageTargetIDReplyKey =                @"deviceID";
const NSString *kGSPlayerImageURLReplyKey =                     @"imageURL";

//----------------------- Completion Key Constants ------------------------//
const NSString *kGSLoginCompletionKey =                         @"kGSLoginCompletionKey";
const NSString *kGSLogoutCompletionKey =                        @"kGSLogoutCompletionKey";
const NSString *kGSUploadImageCompletionKey =                   @"kGSUploadImageCompletionKey";
const NSString *kGSDownloadImageCompletionKey =                 @"kGSDownloadImageCompletionKey";
const NSString *kGSGetCurrentSessionInfoCompletionKey =         @"kGSGetCurrentSessionInfoCompletionKey";
const NSString *kGSGetAllGameSessionsCompletionKey =            @"kGSGetAllGameSessionsCompletionKey";
const NSString *kGSCreateGameSessionCompletionKey =             @"kGSCreateGameSessionCompletionKey";
const NSString *kGSJoinGameSessionCompletionKey =               @"kGSJoinGameSessionCompletionKey";
const NSString *kGSLeaveGameSessionCompletionKey =              @"kGSLeaveGameSessionCompletionKey";



#pragma mark - C Helper/Inline functions

void throwError(NSError *error) {
    @throw [ARMException exceptionWithError:error];
}

void dispatchOnMainQueue(void (^block)(void))
{
    dispatch_async(dispatch_get_main_queue(), block);
}

NSData *dataFromJSONObject(NSDictionary *jsonObject)
{
    NSError *jsonError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&jsonError];
    if (jsonError) throwError(jsonError);
    return data;
}


/****************************************************************************/
/*                              Implementation                              */
/****************************************************************************/
@interface ARMGameServerCommunicator () <NSURLSessionTaskDelegate>
{
    BOOL shouldSkipCompletionHandler;
    NSMutableArray *networkImagePathStringsArray;
}

@property (strong, nonatomic) NSURLSession *mainURLSession;
@property (strong, nonatomic) NSURLSessionConfiguration *mainURLSessionConfig;

@end

#pragma mark - Implementation
@implementation ARMGameServerCommunicator

@synthesize delegate;
@synthesize completionHandlerDictionary;
@synthesize mainURLSession;
@synthesize mainURLSessionConfig;
@synthesize connectionStatus;
@synthesize availableGameSessions;
@synthesize clientIDCookie;
@synthesize currentSessionID;
@synthesize currentSessionName;
@synthesize playersInSessionArray;

#pragma mark - Lifecycle
/****************************************************************************/
/*                              Lifecycle Methods                           */
/****************************************************************************/
+ (id)sharedInstance
{
    static ARMGameServerCommunicator *this = nil;
    if (!this)
    {
        this = [[ARMGameServerCommunicator alloc] init];
    }
    return this;
}

- (id)init
{
    self = [super init];
    if (self) {
        // custom initialization
        shouldSkipCompletionHandler = YES;
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
        
        mainURLSessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        [mainURLSessionConfig setAllowsCellularAccess:YES];
        [mainURLSessionConfig setHTTPAdditionalHeaders:@{@"User-Agent":kGSHTTPUserAgentHeaderString, @"Accept": kGSHTTPAcceptContentHeaderString}];
        [mainURLSessionConfig setTimeoutIntervalForRequest:30.0];
        [mainURLSessionConfig setTimeoutIntervalForResource:60.0];
        [mainURLSessionConfig setHTTPMaximumConnectionsPerHost:1];
        
        mainURLSession = [NSURLSession sessionWithConfiguration:mainURLSessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
    }
    return self;
}

- (void)setDelegate:(id<ARMGSCommunicatorDelegate>)newDelegate
{
    delegate = newDelegate;
    self->shouldSkipCompletionHandler = NO;
}

- (void)finishTasksWithoutCompletionHandlerAndPreserveState
{
#warning incomplete implementation
    shouldSkipCompletionHandler = YES;
}

- (void)continueTasksWithCompletionHandler
{
    shouldSkipCompletionHandler = NO;
}

- (void)purgeNetworkImagesFromFileSystem
{
    if (networkImagePathStringsArray)
    {
        NSError *error;
        for (NSString *filePath in networkImagePathStringsArray)
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error)
            {
                NSLog(@"Error deleting network image files: %@", error);
            }
        }
    }
    networkImagePathStringsArray = nil;
}

#pragma mark - Public Networking Methods
/****************************************************************************/
/*                      Public Networking Methods                           */
/****************************************************************************/

- (void)loginWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kLoggingIn;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSLoginCompletionKey];
    }
    
    //---------    First: Create a request with the User's Info to POST    --------//
    NSMutableURLRequest *loginRequest;
    ARMPlayerInfo *userData = [ARMPlayerInfo sharedInstance];
    @try {
        loginRequest = [self requestWithRelativeURLString:[kGSLoginEndpointURLString copy]
                                       withPostJSONObject: @{kGSUserNamePostKey: [userData playerDisplayName],
                                                             kGSDeviceIDPostKey: [userData gameTileImageTargetID]
                                                            }];
    }
    @catch (NSException *e)
    {
        completionHandler([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidPostDataErrorCode userInfo:nil]);
        return;
    }
    
    
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject) {
        // Check our cookie: it is our client ID
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[ARMGameServerURLString copy]]];
        
        NSHTTPCookie *clientCookie = cookies[0];
        [self setClientIDCookie:[clientCookie value]];
        
        // Make sure we're going to the right place
        NSURL *urlWeShouldBeRedirectedTo = [self URLWithRelativePathString:[NSString stringWithFormat:[kGSImagesEndpointURLFormatString copy], [clientCookie value]]];
        
        NSDictionary *responseHeaders = [httpResponse allHeaderFields];
        NSURL *urlWeAreBeingRedirectedTo = [self URLWithRelativePathString:responseHeaders[@"Location"]];
        
        // Raise an exception any of these checks fail. This means we weren't able to properly log in.
        if ([cookies count] < 1 ||
            ![[clientCookie name] isEqualToString:[kGSHTTPClientCookieName copy]] ||
            ![[urlWeShouldBeRedirectedTo absoluteURL] isEqual:urlWeAreBeingRedirectedTo])
        {
            return [NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidServerResponseErrorCode userInfo:nil];
        }
        return nil;
    };
    
    NSURLSessionDataTask *loginTask = [mainURLSession dataTaskWithRequest:loginRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        // pass the data and handlers to our midleware
        [self handleGameServerResponseWithProcessor:processor successStatusCode:302
                                  completionHandler:completionHandler data:data response:response error:error];
    }];
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [loginTask resume];
    
}

- (void)logoutWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kLoggingOut;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSLogoutCompletionKey];
    }
    
    //---------    First: Prepare the DELETE Request    --------//
    NSMutableURLRequest *logoutRequest = [self requestWithRelativeURLString:[kGSLogoutEndpointURLString copy]
                                                               withPostJSONObject: nil];
    [logoutRequest setHTTPMethod:@"DELETE"];
    
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        // Clean up our instance variables
        connectionStatus = kNotConnectedToGameServer;
        clientIDCookie = nil;
        currentSessionID = nil;
        currentSessionName = nil;
        playersInSessionArray = nil;
        return nil;
    };
    
    //---------    Finally: Submit the request    --------//
    NSURLSessionDataTask *logoutTask = [mainURLSession dataTaskWithRequest:logoutRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [logoutTask resume];
    
}

- (void)putProfileImageToServerWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kSendingImage;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSUploadImageCompletionKey];
    }
    
    UIImage *imageToUpload = [[ARMPlayerInfo sharedInstance] playerDisplayImage];
    NSMutableURLRequest *uploadImageRequest;
    
    @try {
        // DO Something with imageURL here
        if (!imageToUpload)
        {
            @throw [NSException new];
        }
        //---------    First: Create a request    --------//
        uploadImageRequest = [self requestWithRelativeURLString:[NSString stringWithFormat:[kGSImagesEndpointURLFormatString copy], clientIDCookie] withPostJSONObject: nil];
        
        // Alter the headers
        NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[uploadImageRequest allHTTPHeaderFields]];
        headers[@"Content-Type"] = [kGSUploadImageContentTypeHeader copy];
        [uploadImageRequest setAllHTTPHeaderFields:headers];
        
        [uploadImageRequest setHTTPMethod:@"POST"];
        
        //---------    Second: Prepare the data    --------//
        
        // Start with the Form data
        NSMutableString *postBodyHeader = [NSMutableString stringWithFormat:@"%@", kGSUploadImageFormBoundaryHeaderValue];
        [postBodyHeader appendFormat:@"\n%@; %@; %@", kGSUploadContentDispositionString, kGSUploadFormValueFieldString,
                                [NSString stringWithFormat:[kGSUploadFilenameFormatString copy], clientIDCookie]];
        
        [postBodyHeader appendFormat:@"\n%@", kGSUploadContentTypeString];
        [postBodyHeader appendFormat:@"\n\n"];
        
        
        // Now prepare the image data
        NSData *imageData = UIImagePNGRepresentation(imageToUpload);
        
        // Finally set the footer
        NSMutableString *postBodyFooter = [NSMutableString stringWithFormat:@"\n%@--\n\n", kGSUploadImageFormBoundaryHeaderValue];
        
        
        //---------    Third: Package everything for submission    --------//
        
        // Switch to network line endings
        [postBodyHeader replaceOccurrencesOfString:@"\n" withString:@"\r\n" options:NSLiteralSearch range:NSMakeRange(0, [postBodyHeader length])];
        [postBodyFooter replaceOccurrencesOfString:@"\n" withString:@"\r\n" options:NSLiteralSearch range:NSMakeRange(0, [postBodyFooter length])];
        
        // Pack the final data
        NSMutableData *bodyData = [NSMutableData new];
        [bodyData appendData:[postBodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:imageData];
        [bodyData appendData:[postBodyFooter dataUsingEncoding:NSUTF8StringEncoding]];
        
        [uploadImageRequest setHTTPBody:bodyData];
    }
    @catch (NSException *e)
    {
        completionHandler([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidPutDataErrorCode userInfo:nil]);
        return;
    }
    
    //---------    Finally: Send out the request    --------//
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kLoggedIn;
        return nil;
    };
    
    NSURLSessionDataTask *uploadImageTask = [mainURLSession dataTaskWithRequest:uploadImageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
       // pass the data and handlers to our midleware
       [self handleGameServerResponseWithProcessor:processor successStatusCode:200
                                 completionHandler:completionHandler
                                              data:data response:response error:error];
    }];
    
     dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [uploadImageTask resume];

}

- (void)getAllGameSessionsWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kRetrievingGameSessions;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSGetAllGameSessionsCompletionKey];
    }
    
    //---------    SimpleRequest: Only use a URL and a Processor    --------//
    NSURL *getSessionsURL = [NSURL URLWithString:[kGSActiveSessionsEndpointURLString copy] relativeToURL:[NSURL URLWithString:[ARMGameServerURLString copy]]];
    
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        NSMutableArray *activeSessions = [NSMutableArray new];
        for (NSDictionary *gameSession in jsonObject[kGSActiveSessionsReplyKey])
        {
            [activeSessions addObject:[[ARMGameSession alloc] initWithName:gameSession[kGSSessionNameReplyKey] withID:gameSession[kGSSessionIDReplyKey]]];
        }
        availableGameSessions = activeSessions;
        connectionStatus = kLoggedIn;
        return nil;
    };
    
    //---------    Submit the request    --------//
    NSURLSessionDataTask *getSessionsTask = [mainURLSession dataTaskWithURL:getSessionsURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [getSessionsTask resume];
}

- (void)joinSessionWithIndex:(NSInteger)indexOfSessionToJoin completionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kJoiningGameSession;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSJoinGameSessionCompletionKey];
    }
    
    //---------    First: Prepare the POST Data    --------//
    NSMutableURLRequest *joinSessionRequest;
    @try {
        self.currentSessionID = [(ARMGameSession *)availableGameSessions[indexOfSessionToJoin] ID];
        joinSessionRequest = [self requestWithRelativeURLString:[kGSJoinSessionEndpointURLString copy]
                                             withPostJSONObject: @{kGSSessionIDPostKey:self.currentSessionID}];
    }
    @catch (NSException *e)
    {
        completionHandler([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidPostDataErrorCode userInfo:nil]);
        return;
    }
    
    //---------    Last: Declare the processor and submit the request    --------//
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kInGameSession;
        [self receiveCurrentSessionResponseWithJSONObject:jsonObject];          // Allow our middleware to handle this part
        availableGameSessions = nil;                                            // Forget the game sessions so we never use stale data
        return nil;
    };
    
    NSURLSessionDataTask *joinSessionTask = [mainURLSession dataTaskWithRequest:joinSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [joinSessionTask resume];
}

- (void)getCurrentSessionInfoWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    if (connectionStatus == kInGameSession)
    {
        connectionStatus = kRefreshingSessionInfo;
    }
    else
    {
        connectionStatus = kRetrievingSessionInfo;
    }
    
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSGetCurrentSessionInfoCompletionKey];
    }
    
    //---------    Prepare a simple GET    --------//
    NSMutableURLRequest *getSessionInfoRequest = [self requestWithRelativeURLString:[NSString stringWithFormat:[kGSGetPlayersInSessionEndpointURLFormatString copy], self.currentSessionID] withPostJSONObject:nil];
    
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        [self receiveCurrentSessionResponseWithJSONObject:jsonObject];
        return nil;
    };
    
    //---------    Submit    --------//
    NSURLSessionDataTask *getSessionInfoTask = [mainURLSession dataTaskWithRequest:getSessionInfoRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [getSessionInfoTask resume];
}

- (void)createSessionWithName:(NSString *)newSessionName completionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kCreatingGameSession;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSCreateGameSessionCompletionKey];
    }
    
    //---------    First: Prepare the POST Data    --------//
    NSMutableURLRequest *createSessionRequest;
    @try {
        createSessionRequest = [self requestWithRelativeURLString:[kGSCreateSessionEndpointURLString copy]
                                               withPostJSONObject: @{kGSCreateSessionPostKey:newSessionName}];
    }
    @catch (NSException *e)
    {
        completionHandler([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidPostDataErrorCode userInfo:nil]);
        return;
    }
    
    //---------    Second: Prepare the Processor    --------//
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kInGameSession;
        currentSessionID = [jsonObject objectForKey:kGSSessionIDReplyKey];
        currentSessionName = [jsonObject objectForKey:kGSSessionNameReplyKey];
        [self receiveCurrentSessionResponseWithJSONObject:jsonObject];
        availableGameSessions = nil;
        return nil;
    };
    
    //---------    Finally: Submit the request    --------//
    NSURLSessionDataTask *createSessionTask = [mainURLSession dataTaskWithRequest:createSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [createSessionTask resume];
}

- (void)leaveSessionWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kLeavingGameSession;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSLeaveGameSessionCompletionKey];
    }
    [self purgeNetworkImagesFromFileSystem];
    
    //---------    First: Prepare the DELETE Request    --------//
    NSMutableURLRequest *leaveSessionRequest = [self requestWithRelativeURLString:[kGSLeaveSessionEndpointURLString copy]
                                                               withPostJSONObject: nil];
    [leaveSessionRequest setHTTPMethod:@"DELETE"];
    
    HTTPURLProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        // Clean up our instance variables
        connectionStatus = kLoggedIn;
        currentSessionID = nil;
        currentSessionName = nil;
        playersInSessionArray = nil;
        return nil;
    };
    
    //---------    Finally: Submit the request    --------//
    NSURLSessionDataTask *leaveSessionTask = [mainURLSession dataTaskWithRequest:leaveSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    [leaveSessionTask resume];
    
}

- (void)downloadPlayerImagesWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    if ([self.playersInSessionArray count] == 0)
    {
        return;
    }
    connectionStatus = kDownloadingPlayerProfiles;
    if (completionHandler == nil)
    {
        completionHandler = [completionHandlerDictionary objectForKey:kGSDownloadImageCompletionKey];
    }
    
    
    //---------    First: Prepare our pool of Download Tasks    --------//
    NSMutableArray *downloadTasksArray = [NSMutableArray new];
    if (!networkImagePathStringsArray)
    {
        networkImagePathStringsArray = [NSMutableArray new];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *imagesDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"images"];

    NSMutableArray *remainingPlayersToDownload = [NSMutableArray new];
    // Create a download task for each player
    for (ARMNetworkPlayer *player in self.playersInSessionArray)
    {
        NSMutableURLRequest *getPlayerInfoRequest = [self requestWithRelativeURLString:
                            [player imageNetworkRelativeURLString] withPostJSONObject:nil];
        [remainingPlayersToDownload addObject:player];
        
        ARMImageProcessorType processor = ^NSError *(NSHTTPURLResponse *httpResponse, UIImage *downloadedImage)
        {
            [remainingPlayersToDownload removeObject:player];
            
            // Save the file to the documents directory so vuforia can access it
            NSString *saveImagePath = [imagesDirectory stringByAppendingPathComponent:[player imageLocalFileName]];
            
            // Save the file path so we can delete it when we leave the game session
            [networkImagePathStringsArray addObject:saveImagePath];

            NSData *imageData = UIImagePNGRepresentation(downloadedImage);
            [imageData writeToFile:saveImagePath atomically:YES];
            
            
            if ([remainingPlayersToDownload count] == 0)
            {
                connectionStatus = kInGameSession;
                dispatchOnMainQueue(^{
                    [delegate setActivityIndicatorsVisible:NO];
                });
                [self dispatchCompletionHandler:completionHandler withError:nil];
            }
            return nil;
        };
        
        [downloadTasksArray addObject:
         [mainURLSession dataTaskWithRequest:getPlayerInfoRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            [self handleGameServerResponseWithImageProcessor:processor successStatusCode:200 completionHandler:completionHandler imageData:data response:response error:error];
        }]];
    }
    
    dispatchOnMainQueue(^{[delegate setActivityIndicatorsVisible:YES];});
    
    //---------    Finally: Start all the downloads    --------//
    for (NSURLSessionDataTask *downloadTask in downloadTasksArray)
    {
        [downloadTask resume];
    }
}


#pragma mark - Public Networking Methods
/****************************************************************************/
/*                      Private Network Helper Methods                      */
/****************************************************************************/

- (NSURL *)URLWithRelativePathString:(NSString *)relativePath
{
    return [[NSURL URLWithString:relativePath relativeToURL:[NSURL URLWithString:[ARMGameServerURLString copy]]] absoluteURL];
}

- (NSMutableURLRequest *)requestWithRelativeURLString:(NSString *)relativePath withPostJSONObject:(NSDictionary *)postJSONObject
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLWithRelativePathString:relativePath]];
    
    if (postJSONObject)
    {
        NSError *jsonError;
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:postJSONObject options:NSJSONWritingPrettyPrinted error:&jsonError]];
        if (jsonError) throwError(jsonError);
    }
    else
    {
        [request setHTTPMethod:@"GET"];
    }
    
    return request;
}

- (void)receiveCurrentSessionResponseWithJSONObject:(NSDictionary *)jsonObject
{
    NSString *receivedSessionID = jsonObject[kGSSessionIDReplyKey];
    //NSAssert([receivedSessionID isEqualToString:self.currentSessionID], @"Server replied with the incorrect session.");
    
    playersInSessionArray = [NSMutableArray new];
    for (NSDictionary *player in jsonObject[kGSCurrentPlayersReplyKey])
    {
        [playersInSessionArray addObject:
         [[ARMNetworkPlayer alloc]
          initWithName:                 (NSString *)[player objectForKey:kGSPlayerNameReplyKey]
          gameTileImageTargetID:        (NSString *)[player objectForKey:kGSPlayerImageTargetIDReplyKey]
          imageNetworkRelativeURLString:(NSString *)[player objectForKey:kGSPlayerImageURLReplyKey]
          ]
         ];
    }
    
    currentSessionName = [jsonObject objectForKey:kGSSessionNameReplyKey];
}

- (void)handleGameServerResponseWithProcessor:(HTTPURLProcessorType)processor successStatusCode:(NSInteger)statusCode completionHandler:(CompletionHandlerType)completionHandler data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error
{
    dispatchOnMainQueue(^{
        [delegate setActivityIndicatorsVisible:NO];
    });
    
    // First: Handle any local errors that may have occurred
    if (error)
    {
        error = [self processLocalError:error];
        [self updateConnectionStatusInError];
        [self dispatchCompletionHandler:completionHandler withError:error];
        return;
    }
    
    // Second: Get the HTTPResponse and try to extract some JSON from it
    NSDictionary *jsonObject;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    @try
    {
        if (data == nil || [data length] == 0)
        {
            jsonObject = nil;
        }
        else
        {
            jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) throwError([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidServerResponseErrorCode userInfo:nil]);
            
            // Third: Validate the status code
            if ([httpResponse statusCode] != statusCode)
            {
                error = [self ARMErrorFromJSONObject:[jsonObject objectForKey:kGSErrorReplyKey]];
                throwError(error);
            }
        }
    }
    @catch (NSException *e) // Default: Process any errors
    {
        [self updateConnectionStatusInError];
        if ([e isKindOfClass:[ARMException class]])
        {
            error = [(ARMException *)e errorObject];
        }
    }

#warning incomplete implementation without attempting to retry failed requests
    // Allow the callers to complete execution
    if (processor)          error = processor(httpResponse, jsonObject);
    if (completionHandler)  [self dispatchCompletionHandler:completionHandler withError:error];
}

- (void)handleGameServerResponseWithImageProcessor:(ARMImageProcessorType)imageProcessor successStatusCode:(NSInteger)statusCode completionHandler:(CompletionHandlerType)completionHandler imageData:(NSData *)imageData response:(NSURLResponse *)response error:(NSError *)error
{
    // First: Handle any local errors that may have occurred
    if (error)
    {
        error = [self processLocalError:error];
        [self updateConnectionStatusInError];
        [self dispatchCompletionHandler:completionHandler withError:error];
        return;
    }
    
    // Second: Get the HTTPResponse and try to extract the image from it
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    UIImage *downloadedImage;
    @try
    {
        if ([httpResponse statusCode] != statusCode)
        {
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:imageData options:0 error:&error];
            if (error) throwError([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidServerResponseErrorCode userInfo:nil]);
            error = [self ARMErrorFromJSONObject:[jsonObject objectForKey:kGSErrorReplyKey]];
            throwError(error);
        }
        
        if (imageData == nil || [imageData length] == 0)
        {
            downloadedImage = nil;
            throwError([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidServerResponseErrorCode userInfo:nil]);
        }
        
        downloadedImage = [UIImage imageWithData:imageData];
        
        // Custom: Process response
        
        
    }
    @catch (NSException *e) // Default: Process any errors
    {
        [self updateConnectionStatusInError];
        if ([e isKindOfClass:[ARMException class]])
        {
            error = [(ARMException *)e errorObject];
        }
    }
    
#warning incomplete implementation without attempting to retry failed requests
    // Allow the callers to complete execution
    if (imageProcessor)     imageProcessor(httpResponse, downloadedImage);
    // the image Processor will take care of the completion handler here
}

- (void)dispatchCompletionHandler:(CompletionHandlerType)completionHandler withError:(NSError *)error
{
    if (!self->shouldSkipCompletionHandler && completionHandler)
    {
       dispatchOnMainQueue( ^{completionHandler(error);});
    }
}

- (NSError *)processLocalError:(NSError *)error
{
#warning Implementation under review! You may want to handle more errors
    NSInteger returnErrorCode = ARMUnkownErrorCode;
    NSMutableDictionary *returnUserInfo = [NSMutableDictionary new];
    
    if ([[error domain] isEqualToString:NSURLErrorDomain])
    {
        switch ([error code])
        {
            case NSURLErrorBadURL:
            case NSURLErrorTimedOut:
            case NSURLErrorUnsupportedURL:
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
                returnErrorCode = ARMServerUnreachableErrorCode;
                returnUserInfo[NSURLErrorFailingURLStringErrorKey] = [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey];
                break;
            case NSURLErrorNotConnectedToInternet:
                returnErrorCode = ARMNoInternetConnectionErrorCode;
                break;
                
            case NSURLErrorBadServerResponse:
                returnErrorCode = ARMInvalidServerResponseErrorCode;
                break;
                
            default:
                returnErrorCode = ARMUnkownErrorCode;
                break;
        }
    }
    if ([returnUserInfo count] == 0)
    {
        returnUserInfo = nil;
    }
    error = [NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:returnErrorCode userInfo:returnUserInfo];
    return error;
}

- (NSError *)ARMErrorFromJSONObject:(NSDictionary *)jsonObject
{
    [self updateConnectionStatusInError];
    // Get the error descriptions in a non-exception raising way
    NSNumber *errorCode =   [jsonObject objectForKey:kGSErrorCodeReplyKey];
    NSString *reason =      [jsonObject objectForKey:kGSErrorReasonReplyKey];
    NSString *description = [jsonObject objectForKey:kGSErrorDescriptionReplyKey];
    
    
    return [NSError errorWithDomain:[ARMGameServerErrorDomain copy]
                               code:(errorCode == nil ? ARMUnkownErrorCode: [errorCode integerValue])
                           userInfo:@{
                                      NSLocalizedFailureReasonErrorKey: reason,
                                      NSLocalizedDescriptionKey: description
                                      }];
}

- (void)updateConnectionStatusInError
{
#warning Code Section needs review, You probably want to change this to a "Recover from error" method
    switch (connectionStatus)
    {
        case kLoggingIn:
        case kSendingImage:
            connectionStatus = kFailedToConnectToServer;
            break;
            
        case kLoggingOut:
            connectionStatus = kNotConnectedToGameServer;
            break;
            
        case kRetrievingGameSessions:
        case kJoiningGameSession:
        case kCreatingGameSession:
        case kLeavingGameSession:
            connectionStatus = kLoggedIn;
            break;
        
        case kRetrievingSessionInfo:
        case kRefreshingSessionInfo:
        case kDownloadingPlayerProfiles:
            connectionStatus = kInGameSession;
            break;
        case kInGameSession:
        case kNotInitialized:
        case kFailedToConnectToServer:
        case kNotConnectedToGameServer:
        case kLoggedIn:
        default:
            break;
        
    }
}

#pragma mark - NSURLSessionDataTaskDelegate Methods
/****************************************************************************/
/*                 NSURLSessionDataTaskDelegate Methods                     */
/****************************************************************************/
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSLog(@"ResponseReceived called!");
    
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    
    completionHandler(disposition);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSLog(@"Redirect Handler Called");
    if ([[[response URL] absoluteURL] isEqual:[self URLWithRelativePathString:[kGSLoginEndpointURLString copy]]])
    {
        request = nil;
    }           
    
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSLog(@"Did Complete with error Called!");
    
}


@end
