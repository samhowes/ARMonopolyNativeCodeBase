#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UI/UnityView.h"
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
	/* Manually load the storyboard file
	 * Instantiate a window, root view controller, and it's root view
	 */
	UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	UIViewController *mainVC = [storyBoard instantiateInitialViewController];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = mainVC;
	
	for (UIViewController*vc in [(UINavigationController *)mainVC viewControllers])
	{
		if ([vc isKindOfClass: [ARMPlayViewController class]])
		{
			[vc.view addSubview:_unityView];
			[vc.view sendSubviewToBack:_unityView];
			break;
		}
	}
	
	_rootController = [self.window rootViewController];
	_rootView = _rootController.view;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[ARMPlayerInfo sharedInstance] saveInstanceToArchive];
    [super applicationDidEnterBackground:application];
}

@end

// Tell unity to replace the AppController with this class
IMPL_APP_CONTROLLER_SUBCLASS(ARMAppController)
