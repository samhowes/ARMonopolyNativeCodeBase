//
//  ViewController.m
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMBluetoothViewController.h"
#import "ARMBluetoothManager.h"

@interface ARMBluetoothViewController () <ARMBluetoothManagerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    ARMBluetoothManager *bluetoothManager;
}
@property (retain, nonatomic) NSMutableArray		*connectedServices;         //rename
@property (retain, nonatomic) IBOutlet UILabel 		*currentlyConnectedDevice;  //rename
@property (retain, nonatomic) IBOutlet UITableView 	*devicesTable;              //rename
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *bluetoothActivitySpinner;

@end

@implementation ARMBluetoothViewController

@synthesize connectedServices;
@synthesize currentlyConnectedDevice;
@synthesize devicesTable;


#pragma mark - View lifecycle
/****************************************************************************/
/*								View Lifecycle                              */
/****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
	[devicesTable setDataSource:self];
	[devicesTable reloadData];          //change
    
    bluetoothManager = [ARMBluetoothManager sharedInstance];
	[bluetoothManager setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [bluetoothManager startBluetooth];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [bluetoothManager finishTasksWithoutDelegateAndPreserveState];
    [super viewWillDisappear:animated];
}


#pragma mark - TableView Delegate
/****************************************************************************/
/*                       	TableViewDelegate Methods                       */
/****************************************************************************/
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section//rework completely
{
	return 0;
  /*  NSInteger numberOfPeripherals = [[bleDelegate foundPeripherals] count];
	if (![bleDelegate isBluetoothOn])
	{
		return 0;
	}
	else if (numberOfPeripherals == 0)
	{
		return 1;						// If there aren't any peripherals, display a message
	}
	else
	{
		return numberOfPeripherals;
	} */
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (!bluetoothManager)
    {
        return @"System Bluetooth not initialized";
    }
    else
    {
        switch ([bluetoothManager state])
        {
            case kInitializing:
                return @"Starting Bluetooth...";
                break;
            
            case kWaitingForBluetoothToBeEnabled:
                return @"Bluetooth disabled";
                break;
                
            case kReadyToScan:
                return @"Ready to scan for devices";
                break;
            
            case kResettingBecauseOfSystemReset:
                return @"Restarting Bluetooth...";
                break;
            
            case kFatalUnauthorized:
                return @"Bluetooth Unauthorized";
                break;
            
            case kFatalUnsupported:
                return nil; // we'll put the message in the footer
                break;
            
            case kNotInitialized:
            default:
                return @"Bluetooth not initialized";
                break;

        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	switch ([bluetoothManager state]) {
        case kFatalUnauthorized:
            return @"Enable Bluetooth access in Settings";
            break;
            
        case kFatalUnsupported:
            return @"Bluetooth Low Energy is not supported on this device.";
            break;
            
        case kWaitingForBluetoothToBeEnabled:
            return @"Please enable Bluetooth. This app will not function properly with Bluetooth disabled.";
            break;
            
        default:
            return nil;
            break;
    }
    /*if (![bleDelegate isBluetoothOn])   // use bleDelegate connectionState in a switch statemet
	{
		return @"Device's Bluetooth is powered off. Go to System Settings enable Bluetooth.";
	}
	else
	{
		return @"";
	} */
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellID = @"DeviceList"; // move this to a konstant at the top
    // use bleDelegate connectionState in a switch statemet
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
	
	/*if ([[bleDelegate foundPeripherals] count] == 0)
	{
		cell.textLabel.text = @"Searching for devices...";
	}
	else
	{
		cell.textLabel.text = [[[bleDelegate foundPeripherals] objectAtIndex:indexPath.row] name];
	} */
	
	return cell;
}


#pragma mark - LeDiscoveryDelegate
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void)bluetoothManagerDidRefreshWithError:(NSError *)error
{
    if (error)
    {
        NSString *errorString;
        switch ([error code])
        {
            case kBluetoothPoweredOffErrorCode:
                // The system will notify the user the first time this error occurs
                break;
                
            case kBluetoothPoweredOffWhenResumingErrorCode:
                errorString = @"Bluetooth is disabled. Please enable Bluetooth in Settings.\n\nThis app will not function properly with Bluetooth disabled.";
                break;
                
            case kBluetoothUnauthorizedErrorCode:
                errorString = @"This app needs Bluetooth permissions to function properly. Please grant permissions in Settings";
                break;
            case kBluetoothUnsupportedErrorCode:
                errorString = @"This device does not support Bluetooth Low Energy.\nThis app will not function properly without Bluetooth Low Energy.";
                break;
            case kBluetoothUnknownStateErrorCode:
                errorString = @"An unknown internal error has occured.";
                break;
            case kBluetoothResettingErrorCode:
                errorString = @"Please be patient while Bluetooth restarts.";
                break;
            default:
                errorString = @"An unknown developer error has occured.";
                break;
        }
        
        if (errorString)
        {
            [[[UIAlertView alloc] initWithTitle:@"Bluetooth Error"
                                        message:errorString
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
    else
    {
        // not sure what to do here now.
        switch ([bluetoothManager state]) {
            case kNotInitialized:
                //TODO
                break;
               /* kInitializing,
                kReadyToScan,
                kResettingBecauseOfSystemReset,
                kFatalUnauthorized,
                kFatalUnsupported*/
            default:
                break;
        }
    }
    
	[devicesTable reloadData];
}

@end

