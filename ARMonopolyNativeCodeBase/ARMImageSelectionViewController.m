//
//  ARMImageSelectionViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 4/15/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMImageSelectionViewController.h"
#import "ARMPlayerInfo.h"


@interface ARMImageSelectionViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) NSMutableArray *imagesArray;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@end

@implementation ARMImageSelectionViewController

@synthesize imagesArray;
@synthesize imageView;
@synthesize stepper;
@synthesize errorLabel;

static NSInteger currentImageIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    imagesArray = [NSMutableArray new];
    // Load our images from disk
    NSArray *imageTargetNames = @[@"frameMarker0",@"frameMarker1",@"frameMarker2",@"frameMarker3"];
    for (NSString *imageName in imageTargetNames)
    {
        [imagesArray addObject:[UIImage imageNamed:imageName]];
    }
    
    [imageView setImage:imagesArray[currentImageIndex]];
}

- (void)viewWillAppear:(BOOL)animated
{
    static UIColor *stepperTintColor = nil;
    [super viewWillAppear:animated];
    if (![[ARMPlayerInfo sharedInstance] isReadyToConnectToGameTile])
    {
        [stepper setEnabled:NO];
        stepperTintColor = [stepper tintColor];
        [stepper setTintColor:[UIColor grayColor]];
        [errorLabel setHidden:NO];
        [[[UIAlertView alloc] initWithTitle:@"Configuration Error"
                                    message:@"You must customize your profile before you can connect to a GameTile"
                                   delegate:nil
                          cancelButtonTitle:@"I will go do that!"
                          otherButtonTitles:nil] show];
    }
    else
    {
        if (stepperTintColor != nil)
        {
            [stepper setTintColor:stepperTintColor];
        }
        [stepper setEnabled:YES];
        [errorLabel setHidden:YES];
    }
    [stepper setValue:currentImageIndex];
}


- (void)viewWillDisappear:(BOOL)animated
{
    if ([[ARMPlayerInfo sharedInstance] isReadyToConnectToGameTile])
    {
        
        [[ARMPlayerInfo sharedInstance] bluetoothDidConnectToGameTileWithName:@"UserSelected" imageTargetID:[NSString stringWithFormat:@"%ld", (long)currentImageIndex]];
    }
    
    [super viewWillDisappear:animated];
}

- (IBAction)stepperDidChange:(id)sender
{
    static double oldSteperValue = 0;
    //UIStepper *stepper = (UIStepper *)sender;
    double newStepperValue = [stepper value];
    
    if (oldSteperValue == 0 && newStepperValue == 3)
    {
        [self incrementImageWithBool:NO];
    }
    else if (oldSteperValue == 3 && newStepperValue == 0)
    {
        [self incrementImageWithBool:YES];
    }
    else if (oldSteperValue < newStepperValue)
    {
        [self incrementImageWithBool:YES];
    }
    else
    {
        [self incrementImageWithBool:NO];
    }
    oldSteperValue = newStepperValue;
    
}

- (void)incrementImageWithBool:(BOOL)increment
{
    if (increment)
    {
        currentImageIndex = (currentImageIndex + 1) % 4;
    }
    else
    {
        if (currentImageIndex == 0)
        {
            currentImageIndex = 3;
        }
        else
        {
            currentImageIndex -= 1;
        }
    }
    
    imageView.image = imagesArray[currentImageIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
