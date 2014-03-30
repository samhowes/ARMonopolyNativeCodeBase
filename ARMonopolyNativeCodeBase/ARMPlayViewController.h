//
//  PlayViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/3/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

#if __cplusplus
extern "C" {
#endif
    
    typedef void (*ARMUnityCallbackWithBool)(BOOL);
    
#if __cplusplus
}   // Extern C
#endif

@interface ARMPlayViewController : UIViewController

+ (void)setUnityAcquireCameraCallback:(ARMUnityCallbackWithBool)callbackWithBool;

@end



