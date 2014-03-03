//
//  ARMEditProfileViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/25/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARMPlayerInfo.h"

@interface ARMEditProfileViewController : UITableViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextField *userDisplayStringTextField;
@property (strong, nonatomic) IBOutlet UIImageView *userDisplayImageView;
@property (weak, nonatomic) IBOutlet UIToolbar *cameraToolbar;

@property (strong, nonatomic) ARMPlayerInfo *userData;

@end
