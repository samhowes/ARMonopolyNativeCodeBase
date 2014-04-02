//
//  ARMNewGamePromptViewController.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/31/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ARMNewGamePromptViewController : UITableViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createGameBarButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButton;

@property (weak, nonatomic) IBOutlet UITextField *gameNameTextField;

@property (strong, nonatomic) NSString *nameOfNewGame;

@end
