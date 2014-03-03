//
//  ViewController.m
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMBluetoothViewController.h"
#import "LeDiscovery.h"

@interface ARMBluetoothViewController () <LeDiscoveryDelegate, UITableViewDataSource, UITableViewDelegate>
{
	BOOL isRunningAsPlugin;
}


@property (retain, nonatomic) NSMutableArray		*connectedServices;
@property (retain, nonatomic) IBOutlet UILabel 		*currentlyConnectedDevice;
@property (retain, nonatomic) IBOutlet UITableView 	*devicesTable;

@end

@implementation ARMBluetoothViewController

@synthesize bleDelegate;
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
	isRunningAsPlugin = NO;
	[devicesTable setDataSource:self];
	//[devicesTable reloadData];
	[self initBluetooth];
}

- (void)initBluetooth
{
	connectedServices = [NSMutableArray new];
	
	bleDelegate = [LeDiscovery sharedInstance];
	[bleDelegate setDiscoveryDelegate:self];
	[bleDelegate startScanningForUUIDString:kTileConfigurationServiceUUIDString];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
	[self destroyBluetooth];
	[super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self destroyBluetooth];
	[super viewDidDisappear:animated];
}

- (void)destroyBluetooth
{
	if (!isRunningAsPlugin) {
		[self setDevicesTable:nil];
		[self setCurrentlyConnectedDevice:nil];
	}
	//[bleDelegate currentlyConnectedDevice];
	[bleDelegate stopScanning];
	[bleDelegate setDiscoveryDelegate:nil];
	[bleDelegate deleteSharedInstance];
	bleDelegate = nil;
}

- (NSArray *)getFoundDeviceNames
{
	NSMutableArray *outputArray = [[NSMutableArray alloc]init];
	for (CBPeripheral *peripheral in [bleDelegate foundPeripherals])
	{
		[outputArray addObject:[[NSString alloc] initWithString:peripheral.name]];
	}
	
	return outputArray;
}


#pragma mark - TableView Delegate
/****************************************************************************/
/*                       	TableViewDelegate Methods                       */
/****************************************************************************/
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numberOfPeripherals = [[bleDelegate foundPeripherals] count];
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
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (![bleDelegate isBluetoothOn])
	{
		return @"";
	}
	else
	{
		return @"GAME TILES";
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (![bleDelegate isBluetoothOn])
	{
		return @"Device's Bluetooth is powered off. Go to System Settings enable Bluetooth.";
	}
	else
	{
		return @"";
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellID = @"DeviceList";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
	
	if ([[bleDelegate foundPeripherals] count] == 0)
	{
		cell.textLabel.text = @"Searching for devices...";
	}
	else
	{
		cell.textLabel.text = [[[bleDelegate foundPeripherals] objectAtIndex:indexPath.row] name];
	}
	
	return cell;
}


#pragma mark - LeDiscoveryDelegate
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void) discoveryDidRefresh
{
	if (!isRunningAsPlugin) {
		if (bleDelegate.stringReadFromPeripheral) {
			[currentlyConnectedDevice setText:bleDelegate.stringReadFromPeripheral];
		}
		[devicesTable reloadData];
	}
	
}

- (void) discoveryStatePoweredOff
{
	NSLog(@"INFO: CBCentralManager has powered off!");
}


@end

