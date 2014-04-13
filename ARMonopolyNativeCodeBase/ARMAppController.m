
#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UI/UnityView.h"
#import "iPhone_View.h"
#import "ARMAppController.h"
#import "ARMPlayViewController.h"
#import "ARMPlayerInfo.h"

@implementation ARMAppController

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self prepareDocumentsDirectory];
        
    // Initialize our User Data
    [ARMPlayerInfo sharedInstance];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)createViewHierarchyImpl;
{
    NSLog(@"Creating the view hierarchy");
	/* Manually load the storyboard file
	 * Instantiate a window, root view controller, and it's root view
	 */
	UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	UIViewController *mainVC = [storyBoard instantiateInitialViewController];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = mainVC;
    
    _rootController = mainVC;
    _rootView = mainVC.view;
	
    // 1. Instantiate the UnityViewController
    UnityDefaultViewController *unityVC = [[UnityDefaultViewController alloc] init];
    
    // 2. Assign the UnityView
    [unityVC assignUnityView:_unityView];
    
	for (UIViewController*vc in [(UINavigationController *)mainVC viewControllers])
	{
		if ([vc isKindOfClass: [ARMPlayViewController class]])
		{
            NSLog(@"Found the Play view controller");
            ARMPlayViewController *playViewController = (ARMPlayViewController *)vc;
            // 3. Tell PlayViewController to add it as a child view controller
            [playViewController addUnityViewController:unityVC withUnityView:_unityView];
			break;
		}
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[ARMPlayerInfo sharedInstance] saveInstanceToArchive];
    [super applicationDidEnterBackground:application];
}

- (void)prepareDocumentsDirectory
{
    // Check for the default images that Unity will use
    NSArray *fileNamesArray = @[@"Purple.png", @"Blue.png", @"Orange.png", @"Green.png"];
    
    NSBundle* myBundle = [NSBundle mainBundle];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pathToImagesDirectory = [documentsDirectory stringByAppendingPathComponent:[kImageFolderName copy]];
    
    NSError *error = nil;
    BOOL isDirectory;
    NSLog(@"Copying bundle resources into Documets Directory: \n-->ImagesDirectory: %@", pathToImagesDirectory);
    
    // First: Create the images directory
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToImagesDirectory isDirectory:&isDirectory])
    {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:pathToImagesDirectory withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSLog(@"Error while creating images directory: %@", error);
        }
        error = nil;
    }
    else if (!isDirectory)
    {
        NSLog(@"Error: image folder name '%@' is not a directory!", [kImageFolderName copy]);
    }
    
    // First delete all images in the images directory
    NSArray *filesInImageDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToImagesDirectory error:nil];
    if ([filesInImageDirectory count] > 0)
    {
        NSLog(@"Removing old images from images Directory");
        for (NSString *imagePath in filesInImageDirectory)
        {
            [[NSFileManager defaultManager] removeItemAtPath:[pathToImagesDirectory stringByAppendingPathComponent:imagePath] error:&error];
            if (error)
            {
                NSLog(@"Error removing old image files at launch: %@", [error description]);
            }
        }
    }
    
    // Second: Copy all default images over
    NSString *sourcePath;
    NSString *destinationPath;
    for (NSInteger ii = 0; ii < [fileNamesArray count]; ++ii)
    {
        sourcePath = [myBundle pathForResource:[fileNamesArray[ii] stringByDeletingPathExtension] ofType:[kDefaultImageFileName pathExtension]];
        destinationPath = [pathToImagesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:[kAvatarImageFilenameFormatString copy], [NSString stringWithFormat:@"%ld", (long)ii]]];
        if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error])
        {
            NSLog(@"Error while copying bundle resources: %@", error);
        }
    }
    
}
@end

// Tell unity to replace the AppController with this class
IMPL_APP_CONTROLLER_SUBCLASS(ARMAppController)
