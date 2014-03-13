//
//  ViewController.h
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LeDiscovery.h"
#import "ARMPlayerInfo.h"

@interface ARMBluetoothViewController : UIViewController

@property (retain, nonatomic) LeDiscovery *bleDelegate;

- (void)initBluetooth;
- (void)destroyBluetooth;

@end