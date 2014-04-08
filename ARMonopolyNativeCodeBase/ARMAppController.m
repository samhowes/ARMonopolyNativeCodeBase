
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
    NSBundle* myBundle = [NSBundle mainBundle];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pathToImagesDirectory = [documentsDirectory stringByAppendingPathComponent:[kImageFolderName copy]];
    NSString *destinationPath = [documentsDirectory stringByAppendingPathComponent:[kImageFolderName stringByAppendingPathComponent:[kDefaultImageFileName copy]]];
    
    NSError *error;
    BOOL isDirectory;
    NSString* sourcePath = [myBundle pathForResource:[kDefaultImageFileName stringByDeletingPathExtension] ofType:[kDefaultImageFileName pathExtension]];
    NSLog(@"Copying bundle resources into Documets Directory: Source Path: %@\n Documents Path: %@ \n Folder Path: %@", sourcePath, documentsDirectory, destinationPath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:[destinationPath stringByDeletingLastPathComponent] isDirectory:&isDirectory])
    {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[destinationPath stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSLog(@"Error while creating images directory: %@", error);
        }
        error = nil;
    }
    else if (!isDirectory)
    {
        NSLog(@"Error: image folder name '%@' is not a directory!", [kImageFolderName copy]);
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
        error = nil;
    }
    
    if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error])
    {
        NSLog(@"Error while copying bundle resources: %@", error);
    }
    else
    {
        NSLog(@"Successfully copied bundle resources!");
    }
    
    // Delete Old images from the last game session if there are any
    NSArray *filesInImageDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[destinationPath stringByDeletingLastPathComponent] error:&error];
    if ([filesInImageDirectory count] >1)
    {
        NSLog(@"Removing old images from images Directory");
        for (NSString *imagePath in filesInImageDirectory)
        {
            if (![imagePath isEqualToString:[kDefaultImageFileName copy]])
            {
                [[NSFileManager defaultManager] removeItemAtPath:[pathToImagesDirectory stringByAppendingPathComponent:imagePath] error:&error];
                if (error)
                {
                    NSLog(@"Error removing old image files at launch: %@", error);
                }
            }
        }
    }
}

@end

// Tell unity to replace the AppController with this class
IMPL_APP_CONTROLLER_SUBCLASS(ARMAppController)
