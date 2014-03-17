//
//  ARMEditProfileViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/25/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//
#import <MobileCoreServices/MobileCoreServices.h>
#import "ARMEditProfileViewController.h"

@interface ARMEditProfileViewController ()

@property UIImagePickerController *cameraUI;

@end

@implementation ARMEditProfileViewController


@synthesize userDisplayStringTextField;
@synthesize userDisplayImageView;
@synthesize cameraToolbar;
@synthesize cameraUI;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	cameraToolbar.clipsToBounds = YES; // Remove the top border of the toolbar
	[userDisplayImageView.layer setBorderColor:[[UIColor grayColor] CGColor]]; // add a border to the image view
	[userDisplayImageView.layer setBorderWidth:1.0];
	
	ARMPlayerInfo *userData = [ARMPlayerInfo sharedInstance];
    if ([userData playerDisplayName])
    {
        [userDisplayStringTextField setText:[userData playerDisplayName]];
    }
    if ([userData playerDisplayImage])
    {
        userDisplayImageView.image = [userData playerDisplayImage];
    }
    else
    {
        [userData setPlayerDisplayImage:userDisplayImageView.image];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/****************************************************************************/
/*							UI protocols									*/
/****************************************************************************/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField != userDisplayStringTextField)
	{
		return NO;
	}
	[[ARMPlayerInfo sharedInstance] setPlayerDisplayName:[textField text]];
	[textField resignFirstResponder];
	return YES;
}


- (IBAction)cameraButtonWasPressed:(id)sender {
	UIActionSheet *chooseImageActionSheeet =
	[[UIActionSheet alloc] initWithTitle:nil delegate:self
					   cancelButtonTitle:@"Cancel"
				  destructiveButtonTitle:nil
					   otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
	
	[chooseImageActionSheeet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0: 			// Take Photo
			[self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
			break;
		case 1:				// Choose photo
			[self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
			break;
		case 2: 			// Cancel
			break;
			
		default:
			break;
	}
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
	cameraUI = [[UIImagePickerController alloc] init];
	cameraUI.sourceType = sourceType;
	//imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
	
	cameraUI.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
	cameraUI.allowsEditing = YES;
	cameraUI.delegate = self;
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
	[self presentViewController:cameraUI animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate Methods
/****************************************************************************/
/*					UIImagePickerControllerDelegate							*/
/****************************************************************************/

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
	UIImage *originalImage, *editedImage, *imageToSave;
	
	if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
	{
		editedImage = 	(UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
		originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
		if (editedImage) {
			imageToSave = editedImage;
		} else {
			imageToSave = originalImage;
		}
		
        // Save the new image (original or edited) to the Camera Roll
        UIImageWriteToSavedPhotosAlbum (imageToSave, nil, nil , nil);
		userDisplayImageView.image = imageToSave;
		[[ARMPlayerInfo sharedInstance] setPlayerDisplayImage:imageToSave];
	}
	
	if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo)
	{
		NSLog(@"Error: movie encounterd as a result of the image picker!");
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	cameraUI = nil;
}



@end
