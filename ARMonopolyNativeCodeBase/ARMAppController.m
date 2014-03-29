
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
    [ARMPlayerInfo sharedInstance]; // initialize the player data
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

@end

// Tell unity to replace the AppController with this class
IMPL_APP_CONTROLLER_SUBCLASS(ARMAppController)
