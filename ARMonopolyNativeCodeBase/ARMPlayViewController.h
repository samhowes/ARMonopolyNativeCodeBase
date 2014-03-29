//
//  PlayViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/3/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
ARMUnityScreenOrientation
{
    armOrientationUnknown,
    armPortrait,
    armPortraitUpsideDown,
    armLandscapeLeft,
    armLandscapeRight,
    armAutorotation,
    armOrientationCount
}
ARMUnityScreenOrientation;

ARMUnityScreenOrientation ARMUnityScreenOrientationFromUIInterfaceOrientation(UIInterfaceOrientation newOrientation);

@interface ARMUnityView : UIView

- (void)willRotateTo:(ARMUnityScreenOrientation)orientation;
- (void)didRotate;
- (void)addUnityViewController:(UIViewController *)unityViewController;


@end

@interface ARMPlayViewController : UIViewController

@end



