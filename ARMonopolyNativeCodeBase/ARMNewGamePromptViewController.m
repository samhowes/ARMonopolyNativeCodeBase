//
//  ARMNewGamePromptViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/31/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMNewGamePromptViewController.h"

@interface ARMNewGamePromptViewController ()

@end

@implementation ARMNewGamePromptViewController

@synthesize createGameBarButton;
@synthesize cancelBarButton;
@synthesize gameNameTextField;

@synthesize nameOfNewGame;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [gameNameTextField setDelegate:self];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *textFieldText = [textField.text stringByAppendingString:string];
    if (textFieldText.length >= 3)
    {
        [createGameBarButton setEnabled:YES];
    }
    else
    {
        [createGameBarButton setEnabled:NO];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField.text.length >= 3)
    {
        return YES;
    }
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Entry Error"
                                                  message:@"Name must be at least 3 characters long"
                                                 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField != gameNameTextField)	return NO;

	[textField resignFirstResponder];
	return YES;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if (sender != createGameBarButton)
    {
        nameOfNewGame = nil;
        return;
    }
    
    if (gameNameTextField.text.length > 2)
    {
        nameOfNewGame = gameNameTextField.text;
    }
    else
    {
        nameOfNewGame = nil;
    }
    
}


@end
