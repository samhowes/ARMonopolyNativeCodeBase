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
{
    NSInteger currentImageIndex;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) NSMutableArray *imagesArray;

@end

@implementation ARMImageSelectionViewController

@synthesize imagesArray;
@synthesize imageView;

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
    currentImageIndex = 0;
    
    [imageView setImage:imagesArray[currentImageIndex]];
   /*
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(didSwipe:)];
    [imageView addGestureRecognizer:rightSwipe];
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(didSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [imageView addGestureRecognizer:leftSwipe];*/
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![[ARMPlayerInfo sharedInstance] isReadyToConnectToGameTile])
    {
        [[[UIAlertView alloc] initWithTitle:@"Configuration Error"
                                    message:@"You must customize your profile before you can connect to a GameTile"
                                   delegate:nil
                          cancelButtonTitle:@"I will go do that!"
                          otherButtonTitles:nil] show];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [[ARMPlayerInfo sharedInstance] bluetoothDidConnectToGameTileWithName:@"UserSelected" imageTargetID:[NSString stringWithFormat:@"%ld", (long)currentImageIndex]];
    [super viewWillDisappear:animated];
}

- (IBAction)stepperDidChange:(id)sender
{
    static double oldSteperValue = 0;
    UIStepper *stepper = (UIStepper *)sender;
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

-(IBAction)didSwipe : (UISwipeGestureRecognizer *) sender
{
    UISwipeGestureRecognizerDirection direction = sender.direction;
    switch (direction)
    {
        case UISwipeGestureRecognizerDirectionRight:
            currentImageIndex = (currentImageIndex + 1) % 4;
            break;
            
        case UISwipeGestureRecognizerDirectionLeft :
            currentImageIndex -= 1;
            if (currentImageIndex == 0)
            {
                currentImageIndex = 3;
            }
            break;
            
        default:
            break;
    }
    
    imageView.image = imagesArray[currentImageIndex];
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
