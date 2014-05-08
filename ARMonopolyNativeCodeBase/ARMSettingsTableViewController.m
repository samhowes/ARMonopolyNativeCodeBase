//
//  ARMSettingsTableViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 5/3/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMSettingsTableViewController.h"

NSString *const kConnectWithBluetoothSegueIdentifier = @"ConnectWithBluetoothSegue";
NSString *const kChooseImageTargetSegueIdentitfier = @"ChooseImageTargetSegue";

@interface ARMSettingsTableViewController () <UITableViewDelegate, UIActionSheetDelegate>

@end

@implementation ARMSettingsTableViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.navigationController.view.backgroundColor = [UIColor whiteColor];
	self.navigationController.navigationBar.translucent = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath indexAtPosition:0] == 1) // If we selected the Connect to game tile cell
    {
        UIActionSheet *chooseImageTargetSourceActionSheet =
        [[UIActionSheet alloc] initWithTitle:nil delegate:self
                           cancelButtonTitle:@"Cancel"
                      destructiveButtonTitle:nil
                           otherButtonTitles:@"Connect With Bluetooth", @"Manually Choose Target", nil];
        
        [chooseImageTargetSourceActionSheet showInView:self.view];
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0: 			// Connect with Bluetooth
            [self performSegueWithIdentifier:kConnectWithBluetoothSegueIdentifier sender:self];
			break;
		case 1:				// Manually choose target
            [self performSegueWithIdentifier:kChooseImageTargetSegueIdentitfier sender:self];
			break;
		case 2: 			// Cancel
			break;
			
		default:
			break;
	}
}

- (IBAction)unwindToSettingsList:(id)sender
{
    // No need to do anything
}

#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
