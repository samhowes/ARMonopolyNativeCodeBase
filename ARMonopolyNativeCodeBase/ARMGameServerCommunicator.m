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

const NSString *ARMGameServerURLString =                        @"http://155.41.123.15:3000";
const NSString *kGSHTTPUserAgentHeaderString =                  @"ARMonopoy iOS";
const NSString *kGSHTTPAcceptContentHeaderString =              @"application/json";
const NSString *kGSHTTPClientCookieName =                       @"clientID";


const NSString *kGSLoginEndpointURLString =                     @"/login";
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
const NSString *kGSUserNamePostKey =                            @"username";
const NSString *kGSDeviceIDPostKey =                            @"gameTileID";
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


#pragma mark - C Helper/Inline functions

void dispatchCompletionHandler(CompletionHandlerType completionHandler, NSError *error)
{
    if (completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{completionHandler(error);});
    }
}

void throwError(NSError *error) {
    @throw [ARMException exceptionWithError:error];
}

NSData *dataWithJSONObject(NSDictionary *jsonObject)
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
    ARMPlayerInfo *userData;
    NSUInteger loginTaskIdentifier;
}

@property (strong, nonatomic) NSURLSession *mainURLSession;
@property (strong, nonatomic) NSURLSessionConfiguration *mainURLSessionConfig;

@end

#pragma mark - Implementation
@implementation ARMGameServerCommunicator

@synthesize mainURLSession;
@synthesize mainURLSessionConfig;
@synthesize connectionStatus;
@synthesize availableGameSessions;
@synthesize clientIDCookie;
@synthesize currentSessionID;
@synthesize currentSessionName;

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
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
        
        mainURLSessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        [mainURLSessionConfig setAllowsCellularAccess:YES];
        [mainURLSessionConfig setHTTPAdditionalHeaders:@{@"User-Agent":kGSHTTPUserAgentHeaderString, @"Accept": kGSHTTPAcceptContentHeaderString}];
        [mainURLSessionConfig setTimeoutIntervalForRequest:30.0];
        [mainURLSessionConfig setTimeoutIntervalForResource:60.0];
        [mainURLSessionConfig setHTTPMaximumConnectionsPerHost:1];
        
        mainURLSession = [NSURLSession sessionWithConfiguration:mainURLSessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        userData = [ARMPlayerInfo sharedInstance];
    }
    return self;
}

- (void)haltTasksAndPreserveState
{
    //TODO
}

#pragma mark - Networking Methods
/****************************************************************************/
/*							Networking Methods                              */
/****************************************************************************/

- (void)loginWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kLoggingIn;
    
    NSMutableURLRequest *loginRequest;
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
    
    
    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[ARMGameServerURLString copy]]];
        NSLog(@"After the first sever response we have %d cookies", (int)[cookies count]);
        assert([cookies count] == 1);
        
        NSHTTPCookie *clientCookie = cookies[0];
        NSLog(@"Cookie with name %@ recieved, with value: %@", [clientCookie name], [clientCookie value]);
        assert([[clientCookie name] isEqualToString:[kGSHTTPClientCookieName copy]]);
        
        NSURL *urlWeShouldBeRedirectedTo = [self URLWithRelativePathString:[NSString stringWithFormat:[kGSImagesEndpointURLFormatString copy], [clientCookie value]]];
        
        [self setClientIDCookie:[clientCookie value]];
        
        NSDictionary *responseHeaders = [httpResponse allHeaderFields];
        NSURL *urlWeAreBeingRedirectedTo = [self URLWithRelativePathString:responseHeaders[@"Location"]];
        // DO something with the http response here
        assert([[urlWeShouldBeRedirectedTo absoluteURL] isEqual:urlWeAreBeingRedirectedTo]);
    };
    
    NSURLSessionDataTask *loginTask = [mainURLSession dataTaskWithRequest:loginRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        // pass the data and handlers to our midleware
        [self handleGameServerResponseWithProcessor:processor successStatusCode:302
                                  completionHandler:completionHandler data:data response:response error:error];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [loginTask resume];
    
}

- (void)putProfileImageToServerWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kSendingImage;
    
    UIImage *imageToUpload = [[ARMPlayerInfo sharedInstance] playerDisplayImage];
    NSMutableURLRequest *uploadImageRequest;
    @try {
        // DO Something with imageURL here
        if (!imageToUpload)
        {
            @throw [NSException new];
        }
        uploadImageRequest = [self requestWithRelativeURLString:[NSString stringWithFormat:[kGSImagesEndpointURLFormatString copy], clientIDCookie]
                                     withPostJSONObject: nil];
        NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[uploadImageRequest allHTTPHeaderFields]];
        
        [uploadImageRequest setHTTPMethod:@"POST"];
        headers[@"Content-Type"] = [kGSUploadImageContentTypeHeader copy];
        [uploadImageRequest setAllHTTPHeaderFields:headers];
        
        // Prepare all the data we want to post in the HTTP Body
        // Start with the Form data
        NSMutableString *postBodyHeader = [NSMutableString stringWithFormat:@"%@", kGSUploadImageFormBoundaryHeaderValue];
        [postBodyHeader appendFormat:@"\n%@; %@; %@", kGSUploadContentDispositionString, kGSUploadFormValueFieldString,
                                [NSString stringWithFormat:[kGSUploadFilenameFormatString copy], clientIDCookie]];
        
        [postBodyHeader appendFormat:@"\n%@", kGSUploadContentTypeString];
        [postBodyHeader appendFormat:@"\n\n"];
        
        // Now the actual image upload
        NSData *imageData = UIImagePNGRepresentation(imageToUpload);
        
        // end with the form boundary again
        NSMutableString *postBodyFooter = [NSMutableString stringWithFormat:@"\n%@--\n\n", kGSUploadImageFormBoundaryHeaderValue];
        
        [postBodyHeader replaceOccurrencesOfString:@"\n" withString:@"\r\n" options:NSLiteralSearch range:NSMakeRange(0, [postBodyHeader length])];
        [postBodyFooter replaceOccurrencesOfString:@"\n" withString:@"\r\n" options:NSLiteralSearch range:NSMakeRange(0, [postBodyFooter length])];
         
        
        NSMutableData *bodyData = [NSMutableData new];
        [bodyData appendData:[postBodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:imageData];
        [bodyData appendData:[postBodyFooter dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Finally set the actual request body
        [uploadImageRequest setHTTPBody:bodyData];
    }
    @catch (NSException *e)
    {
        completionHandler([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidPutDataErrorCode userInfo:nil]);
        return;
    }
    
    // TODO: Make this an upload task
    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kLoggedIn;
    };
    
    NSURLSessionDataTask *uploadImageTask = [mainURLSession dataTaskWithRequest:uploadImageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
       // pass the data and handlers to our midleware
       [self handleGameServerResponseWithProcessor:processor successStatusCode:200
                                 completionHandler:completionHandler
                                              data:data response:response error:error];
    }];
    
    [uploadImageTask resume];

}

- (void)getActiveSessionsWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kRetrievingGameSessions;
    
    NSURL *getSessionsURL = [NSURL URLWithString:[kGSActiveSessionsEndpointURLString copy] relativeToURL:[NSURL URLWithString:[ARMGameServerURLString copy]]];
    
    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        NSMutableArray *activeSessions = [NSMutableArray new];
        for (NSDictionary *gameSession in jsonObject[kGSActiveSessionsReplyKey])
        {
            [activeSessions addObject:[[ARMGameSession alloc] initWithName:gameSession[kGSSessionNameReplyKey] withID:gameSession[kGSSessionIDReplyKey]]];
        }
        availableGameSessions = activeSessions;
        connectionStatus = kReadyForSelection;
    };
    
    NSURLSessionDataTask *getSessionsTask = [mainURLSession dataTaskWithURL:getSessionsURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    [getSessionsTask resume];
}

- (void)joinSessionWithIndex:(NSInteger)indexOfSessionToJoin completionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kJoiningGameSession;
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
    
    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kInGameSession;
        [self receiveCurrentSessionResponseWithJSONObject:jsonObject];
        availableGameSessions = nil;
    };
    
    NSURLSessionDataTask *joinSessionTask = [mainURLSession dataTaskWithRequest:joinSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [joinSessionTask resume];
}

- (void)getCurrentPlayersInSessionWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    NSMutableURLRequest *getSessionInfoRequest = [self requestWithRelativeURLString:[NSString stringWithFormat:[kGSGetPlayersInSessionEndpointURLFormatString copy], self.currentSessionID] withPostJSONObject:nil];
    
    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        [self receiveCurrentSessionResponseWithJSONObject:jsonObject];
    };
    
    NSURLSessionDataTask *getSessionInfoTask = [mainURLSession dataTaskWithRequest:getSessionInfoRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [getSessionInfoTask resume];
}

- (void)leaveSessionWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kLeavingGameSession;
    NSMutableURLRequest *leaveSessionRequest = [self requestWithRelativeURLString:[kGSLeaveSessionEndpointURLString copy]
                                                               withPostJSONObject: nil];

    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kLoggedIn;
        currentSessionID = nil;
        currentSessionName = nil;
        [userData applicationDidLeaveGameSession];
        
    };
    
    NSURLSessionDataTask *leaveSessionTask = [mainURLSession dataTaskWithRequest:leaveSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [leaveSessionTask resume];
    
}

- (void)createSessionWithName:(NSString *)newSessionName completionHandler:(CompletionHandlerType)completionHandler
{
    connectionStatus = kCreatingGameSession;
    NSMutableURLRequest *createSessionRequest;
    @try {
        createSessionRequest = [self requestWithRelativeURLString:[kGSCreateSessionEndpointURLString copy]
                                             withPostJSONObject: @{kGSSessionIDPostKey:newSessionName}];
    }
    @catch (NSException *e)
    {
        completionHandler([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidPostDataErrorCode userInfo:nil]);
        return;
    }
    
    HTTPURLProcessorType processor = ^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonObject)
    {
        connectionStatus = kInGameSession;
        currentSessionID = [jsonObject objectForKey:kGSSessionIDReplyKey];
        currentSessionName = [jsonObject objectForKey:kGSSessionNameReplyKey];
        [self receiveCurrentSessionResponseWithJSONObject:jsonObject];
        availableGameSessions = nil;
    };
    
    NSURLSessionDataTask *createSessionTask = [mainURLSession dataTaskWithRequest:createSessionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        [self handleGameServerResponseWithProcessor:processor successStatusCode:200 completionHandler:completionHandler data:data response:response error:error];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [createSessionTask resume];
}

- (void)receiveCurrentSessionResponseWithJSONObject:(NSDictionary *)jsonObject
{
    NSString *receivedSessionID = jsonObject[kGSSessionIDReplyKey];
    NSAssert([receivedSessionID isEqualToString:self.currentSessionID], @"Server replied with the incorrect session.");
    
    NSMutableArray *currentPlayers = [NSMutableArray new];
    for (NSDictionary *player in jsonObject[kGSCurrentPlayersReplyKey])
    {
        [currentPlayers addObject:
         [[ARMNetworkPlayer alloc]
          initWithName:                 (NSString *)[player objectForKey:kGSPlayerNameReplyKey]
          gameTileImageTargetID:        (NSString *)[player objectForKey:kGSPlayerImageTargetIDReplyKey]
          imageNetworkRelativeURLString:(NSString *)[player objectForKey:kGSPlayerImageURLReplyKey]
          ]
         ];
    }
    [userData setSessionName:[jsonObject objectForKey:kGSSessionNameReplyKey]];
    [userData setPlayersInSessionArray:currentPlayers];
}

- (void)downloadPlayerImagesWithCompletionHandler:(CompletionHandlerType)completionHandler
{
    NSMutableArray *downloadTasksArray = [NSMutableArray new];
    if ([[userData playersInSessionArray] count] == 0) return;
    
    // Create a download task for each player
    for (ARMNetworkPlayer *player in [userData playersInSessionArray])
    {
        NSMutableURLRequest *getSessionInfoRequest = [self requestWithRelativeURLString:
                            [player imageNetworkRelativeURLString] withPostJSONObject:nil];
        
        ARMImageProcessorType processor = ^(NSHTTPURLResponse *httpResponse, UIImage *downloadedImage)
        {
            // Save the file to the documents directory so vuforia can access it
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:[player imageLocalFileName]];
            NSData *imageData = UIImagePNGRepresentation(downloadedImage);
            [imageData writeToFile:saveImagePath atomically:NO];
        };
        
        [downloadTasksArray addObject:
         [mainURLSession dataTaskWithRequest:getSessionInfoRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            [self handleGameServerResponseWithImageProcessor:processor successStatusCode:200 completionHandler:completionHandler imageData:data response:response error:error];
        }]];
    }
    
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    // Start all the downloads
    for (NSURLSessionDataTask *downloadTask in downloadTasksArray)
    {
        [downloadTask resume];
    }
}

#pragma mark Helper Methods
//----------------------- Networking Helper methods ------------------------//
- (NSURL *)URLWithRelativePathString:(NSString *)relativePath
{
    return [[NSURL URLWithString:relativePath relativeToURL:[NSURL URLWithString:[ARMGameServerURLString copy]]] absoluteURL];
}

- (NSMutableURLRequest *)requestWithRelativeURLString:(NSString *)relativePath withPostJSONObject:(NSDictionary *)postJSONObject
{
    NSError *jsonError;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLWithRelativePathString:relativePath]];
    
    if (postJSONObject)
    {
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

- (void)handleGameServerResponseWithProcessor:(HTTPURLProcessorType)processor successStatusCode:(NSInteger)statusCode completionHandler:(CompletionHandlerType)completionHandler data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    // Default: handle local errors
    [self changeConnectionStatusInError];
    if (error) {dispatchCompletionHandler(completionHandler, error); return;}
    
    // Default: get JSONObject and httpResponse
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
            if (error) throwError([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidServerResponseDataErrorCode userInfo:nil]);
            // Default: Check status code
            if ([httpResponse statusCode] != statusCode)
            {
                error = [self handleGameServerErrorWithJSONObject:[jsonObject objectForKey:kGSErrorReplyKey]];
                throwError(error);
            }
        }
        
        // Custom: Process response
        if (processor) processor(httpResponse, jsonObject);
        
    }
    @catch (NSException *e) // Default: Process any errors
    {
        [self changeConnectionStatusInError];
        if ([e isKindOfClass:[ARMException class]])
        {
            error = [(ARMException *)e errorObject];
        }
    }
    // Default: call completion handler
    
    // Allow the caller to complete execution
    if (completionHandler) dispatchCompletionHandler(completionHandler, error);
}

- (void)handleGameServerResponseWithImageProcessor:(ARMImageProcessorType)imageProcessor successStatusCode:(NSInteger)statusCode completionHandler:(CompletionHandlerType)completionHandler imageData:(NSData *)imageData response:(NSURLResponse *)response error:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    // Default: handle local errors
    [self changeConnectionStatusInError];
    if (error) {dispatchCompletionHandler(completionHandler, error); return;}
    
    // Default: get JSONObject and httpResponse
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    UIImage *downloadedImage;
    @try
    {
        // Default: Check status code
        if ([httpResponse statusCode] != statusCode)
        {
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:imageData options:0 error:&error];
            if (error) throwError([NSError errorWithDomain:[ARMGameServerErrorDomain copy] code:ARMInvalidServerResponseDataErrorCode userInfo:nil]);
            error = [self handleGameServerErrorWithJSONObject:[jsonObject objectForKey:kGSErrorReplyKey]];
            throwError(error);
        }
        
        downloadedImage = [UIImage imageWithData:imageData];
        
        // Custom: Process response
        if (imageProcessor) imageProcessor(httpResponse, downloadedImage);
        
    }
    @catch (NSException *e) // Default: Process any errors
    {
        [self changeConnectionStatusInError];
        if ([e isKindOfClass:[ARMException class]])
        {
            error = [(ARMException *)e errorObject];
        }
    }
    // Default: call completion handler
    
    // Allow the caller to complete execution
    if (completionHandler) dispatchCompletionHandler(completionHandler, error);
}

- (NSError *)handleGameServerErrorWithJSONObject:(NSDictionary *)jsonObject
{
    [self changeConnectionStatusInError];
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

- (void)changeConnectionStatusInError
{
    switch (connectionStatus)
    {
        case kNotInitialized:
            // no need to change anything
            break;
        case kLoggingIn:
            connectionStatus = kNotInitialized;
            break;
        case kSendingImage:
            connectionStatus = kNotInitialized;
            break;
        case kLoggedIn:
            // no need to change anything
            break;
        case kRetrievingGameSessions:
            connectionStatus = kLoggedIn;
            break;
        case kReadyForSelection:
            // no need to change anything
            break;
        case kJoiningGameSession:
            connectionStatus = kReadyForSelection;
            break;
        case kCreatingGameSession:
            connectionStatus = kReadyForSelection;
            break;
        case kInGameSession:
            // no need to change anything
            break;
        case kLeavingGameSession:
            connectionStatus = kLoggedIn;
            break;
        case kFailedToConnectToServer:
            // No need to change anything
            break;
        default:
            connectionStatus = kNotInitialized;
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


#pragma mark - UITableViewDataSource Methods
/****************************************************************************/
/*					   UITableViewDatasource Methods                        */
/****************************************************************************/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (connectionStatus == kInGameSession)
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
    
    NSString *titleForHeader;
    switch (connectionStatus) {
        case kNotInitialized:
            titleForHeader = @"Not connected to Game Server";
            break;
        case kLoggingIn:
            titleForHeader = @"Loggin in to Game Server...";
            break;
        case kSendingImage:
            titleForHeader = @"Uploading profile image to Game Server...";
            break;
        case kRetrievingGameSessions:
            titleForHeader = @"Retrieving active sessions...";
            break;
        case kReadyForSelection:
            titleForHeader = @"Select a session...";
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
    if (connectionStatus == kReadyForSelection)
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
            return [[userData  playersInSessionArray] count];
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
        if (indexPath.section == 0)     // Display the current game session at the top
        {
            cell.textLabel.text = [userData  sessionName];
            [cell setUserInteractionEnabled:NO];
        }
        else    // display the Current players below
        {
            cell.textLabel.text = [[[userData  playersInSessionArray]
                                    objectAtIndex:indexPath.row] playerName];
            [cell setUserInteractionEnabled:NO];
        }
    }
    else
    {   // Display a current game session
        cell.textLabel.text = [(ARMGameSession *)availableGameSessions[indexPath.row] name];
        [cell setUserInteractionEnabled:YES];
    }
    
    return cell;
}




@end
