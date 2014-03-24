//
//  StaticTableViewController.m
//  ARMonopolyNativeCodeBase
//
//  Created by Samuel Howes on 2/5/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMSettingsViewController.h"

@interface ARMSettingsViewController ()

@end

@implementation ARMSettingsViewController

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

@end
