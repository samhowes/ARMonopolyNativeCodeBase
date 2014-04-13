//
//  TestViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/3/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ARMPlayViewController.h"
#import "ARMGameServerCommunicator.h"
#import "ARMNetworkPlayer.h"

@interface ARMPlayViewController ()

@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UILabel *currentPlayersLabel;
@property (weak, nonatomic) IBOutlet UIButton *displayAllPlayersButton;

@end



@implementation ARMPlayViewController

@synthesize currentPlayersLabel;
@synthesize displayAllPlayersButton;

static ARMUnityCallbackWithBool unityAcquireCameraCallback;

+ (void)setUnityAcquireCameraCallback:(ARMUnityCallbackWithBool)callbackWithBool
{
    unityAcquireCameraCallback = callbackWithBool;
}

// Vuforia 2.8 workaround on iOS7 - save the current format and frame rate durations
// so the camera doesn't crash when we try to use it again.
- (void) saveOrRestoreCaptureFormat:(BOOL)shouldSaveCaptureFormat
{
    static AVCaptureDeviceFormat *captureFormat = nil;
    static CMTime captureMinFrameRateDuration;
    static CMTime captureMaxFrameRateDuration;
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        if (shouldSaveCaptureFormat)
        {
            AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            captureFormat = videoDevice.activeFormat;
            captureMinFrameRateDuration = videoDevice.activeVideoMinFrameDuration;
            captureMaxFrameRateDuration = videoDevice.activeVideoMaxFrameDuration;
        }
        else if (captureFormat) // only load the capture format if we have already saved it
        {
            AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            [videoDevice lockForConfiguration:nil];
            videoDevice.activeFormat = captureFormat;
            videoDevice.activeVideoMaxFrameDuration = captureMaxFrameRateDuration;
            videoDevice.activeVideoMinFrameDuration = captureMinFrameRateDuration;
            [videoDevice unlockForConfiguration];
        }
    }
}


#pragma mark Lifecycle Methods

- (void)viewWillAppear:(BOOL)animated
{
    UIImage *armSplashImage =[UIImage imageNamed:@"LaunchImage*"];
    [currentPlayersLabel setTextColor:[currentPlayersLabel tintColor]];
    if (unityAcquireCameraCallback)
    {
        [self saveOrRestoreCaptureFormat:NO];
        unityAcquireCameraCallback(YES);
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	
	[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
	self.navigationController.navigationBar.shadowImage = [UIImage new];
	self.navigationController.view.backgroundColor = [UIColor clearColor];
	self.navigationController.navigationBar.translucent = YES;
    [self populatePlayersLabel];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (unityAcquireCameraCallback)
    {
        [self saveOrRestoreCaptureFormat:YES];
        unityAcquireCameraCallback(NO);
    }
    [super viewWillDisappear:animated];
}

- (void)populatePlayersLabel
{
    NSArray *playersArray = [[ARMGameServerCommunicator sharedInstance] playersInSessionArray];
    NSString *errorString = @"No Players: Tap ⚙ to join a game";
    NSString *titleString = @"Players:";
    NSMutableString *displayString = [NSMutableString new];
    
    if (!playersArray || [playersArray count] == 0)
    {
        if ([[ARMGameServerCommunicator sharedInstance] currentSessionName])
        {
            [displayString appendString:@"Waiting for more players..."];
        }
        else
        {
            [displayString appendString:errorString];
            [displayAllPlayersButton setHidden:YES];
        }
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
    for (ARMNetworkPlayer *player in [[ARMGameServerCommunicator sharedInstance] playersInSessionArray])
    {
        [listPlayersString appendFormat:@"%@\n", [player playerName]];
    }
    [[[UIAlertView alloc] initWithTitle:@"All Current Players:"
                                message:listPlayersString
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil] show];
      
}

- (void)addUnityViewController:(UIViewController *)unityViewController withUnityView:(UIView *)unityView
{
    [self addChildViewController:unityViewController];          // 1. Establish Child parent relationship
    
    unityView.frame = self.view.frame;           // 2. Set the frame (explicitly or with constraints)
    [self.view addSubview:unityView];            // 2.1 Add the subview AFTER you set the frame
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[unityView]|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(unityView)]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:[unityView]|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(unityView)]];
    
    
    [self.view sendSubviewToBack:unityView];
    [unityViewController didMoveToParentViewController:self];   // 3. Tell the child what happened
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"willRotate was callled! @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    NSArray *children = [self childViewControllers];
    if ([children count] != 0)
    {
        UIViewController *childVC = children[0];        // we will only ever have one child.
        [childVC willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
   [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"DidRotate was callled! @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    NSArray *children = [self childViewControllers];
    if ([children count] != 0)
    {
        UIViewController *childVC = children[0];
        [childVC didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

@end

#if __cplusplus
extern "C" {
#endif

void ARMRegisterUnityCameraCallback(ARMUnityCallbackWithBool callbackWithBool)
{
    [ARMPlayViewController setUnityAcquireCameraCallback:callbackWithBool];
}

#if __cplusplus
}
#endif
    
