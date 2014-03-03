//
//  LeDiscovery.m
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "LeDiscovery.h"

NSString *const kTileConfigurationServiceUUIDString 		= @"DEADF154-0000-0000-0000-0000DEADF154";
NSString *const kTileDisplayStringCharacteristicUUIDString 	= @"4431";

@interface LeDiscovery () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager 	*centralManager;
	BOOL				pendingInit;
	NSString			*uuidStringToScanWith;
	
	CBService			*tileConfigurationService;
	CBCharacteristic	*tileDisplayStringCharacteristic;
	
	CBUUID				*tileConfigurationServiceUUID;
	CBUUID				*tileDisplayStringUUID;
	
	NSString			*stringToWriteToTile;
	
}

- (void) clearDevices;

@end


@implementation LeDiscovery

@synthesize foundPeripherals;
@synthesize connectedServices;
@synthesize currentlyConnectedDevice;
@synthesize stringReadFromPeripheral;

@synthesize discoveryDelegate;
@synthesize peripheralDelegate;

#pragma mark - Public Actions
/****************************************************************************/
/*									Lifecycle								*/
/****************************************************************************/

+ (id) sharedInstance
{
	static LeDiscovery *this = nil;		// Get a permanent pointer to our main instance

	if (!this) {
		this = [[LeDiscovery alloc] init];
	}
	
	return this;
}

- (void) deleteSharedInstance
{
	[centralManager stopScan];
	[self disconnectPeripheral];
	currentlyConnectedDevice = nil;
	centralManager = nil;				// Drop our reference to the central manager
}

- (id) init
{
	self = [super init];
	if (self) {
		pendingInit = YES;
		uuidStringToScanWith = nil;
		centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];	// get the BT Manager kicked off with the main queue
		
		foundPeripherals = 			[[NSMutableArray alloc] init];
		connectedServices = 		[[NSMutableArray alloc] init];
		currentlyConnectedDevice =	nil;
		
		tileConfigurationServiceUUID 	= [CBUUID UUIDWithString:kTileConfigurationServiceUUIDString];
		tileDisplayStringUUID			= [CBUUID UUIDWithString:kTileDisplayStringCharacteristicUUIDString];
	}
	return self;
}

- (void) dealloc
{
	assert(NO);							// Do not call dealloc because this is a singleton class!
}


#pragma mark Discovery

/****************************************************************************/
/*								Discovery                                   */
/****************************************************************************/

- (void) startScanningForUUIDString:(NSString *)uuidString
{
	uuidStringToScanWith = uuidString;
	if ([centralManager state] != CBCentralManagerStatePoweredOn) {		// Only start scanning if the bluetooth is actually on
		return;
	}
	
	NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:uuidStringToScanWith],nil];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
	
	[centralManager scanForPeripheralsWithServices:uuidArray options:options];
}

- (void) stopScanning
{
	[centralManager stopScan];
}

- (BOOL) isBluetoothOn
{
	if ([centralManager state] == CBCentralManagerStatePoweredOn)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark Connectivity
/****************************************************************************/
/*						Connection/Disconnection                            */
/****************************************************************************/
- (void) connectPeripheral:(CBPeripheral *)peripheral
{
	/*receive instruction from viewcontroller */
	[centralManager connectPeripheral:peripheral options:nil];
}

- (void) disconnectPeripheral
{
	tileDisplayStringCharacteristic = nil;
	tileConfigurationService = nil;
	if (currentlyConnectedDevice)
	{
		[centralManager cancelPeripheralConnection:currentlyConnectedDevice];
	}
}

- (void) clearDevices
{
	[foundPeripherals removeAllObjects];
	[connectedServices removeAllObjects];
}

#pragma mark Read/Write
/****************************************************************************/
/*								Read/Write		                            */
/****************************************************************************/

- (void) readStringFromPeripheral
{
	if (!tileDisplayStringCharacteristic){
		NSLog(@"Error: Peripheral not yet connected!");
		return;
	}
	[currentlyConnectedDevice readValueForCharacteristic:tileDisplayStringCharacteristic];
}

- (void) writeStringToPeripheral:(NSString *)stringToWrite
{
	if (stringToWrite) {						// Make sure to store the string, because we might not be able to write it now
		stringToWriteToTile = stringToWrite;
		NSLog(@"String queued for delivery");
	}
	if (tileDisplayStringCharacteristic) {		// Make sure our peripheral is actually connected.
		[currentlyConnectedDevice writeValue:[stringToWriteToTile dataUsingEncoding:NSASCIIStringEncoding]
						   forCharacteristic:tileDisplayStringCharacteristic
										type:CBCharacteristicWriteWithResponse];
	}
}

#pragma mark - CBManagerDelegate
/****************************************************************************/
/*						CBManager Delagate methods							*/
/****************************************************************************/

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
	static CBCentralManagerState previousState = -1;
	
	switch ([centralManager state]) {
		case CBCentralManagerStatePoweredOff:
			[self clearDevices];
			[discoveryDelegate discoveryDidRefresh];
			
			/* Tell the user to turn BT on if this is not the first time. */
			if (previousState == -1) {
				[discoveryDelegate discoveryStatePoweredOff];
			}
			break;
			
		case CBCentralManagerStateUnauthorized:
			/* Tell user the app is not allowed and cleanup */
			break;
		case CBCentralManagerStateUnsupported:
			/*hopefully the framework will tell the user */
			break;
			
		case CBCentralManagerStateUnknown:
			/* Not sure what to do, lets just wait until something else happens */
			break;
			
		case CBCentralManagerStatePoweredOn:
			pendingInit = NO;
			// we're not going to bother implementing saved devices
			[centralManager retrieveConnectedPeripheralsWithServices:[NSArray new]];	// we won't really have many peripherals so this is okay for now
			[discoveryDelegate discoveryDidRefresh];							// tell the view controller to update
			
			if (uuidStringToScanWith) {
				[self startScanningForUUIDString:uuidStringToScanWith];
			}
			break;
			
		case CBCentralManagerStateResetting:
			[self clearDevices];
			[discoveryDelegate discoveryDidRefresh];
			
			pendingInit = YES;
			break;
	}
	previousState = [centralManager state];
}

#pragma mark Discovery
//----------------------Discovery Functions--------------------------------//
- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
	  advertisementData:(NSDictionary *)advertisementData
				   RSSI:(NSNumber *)RSSI
{
	if (![foundPeripherals containsObject:peripheral]) {
		[foundPeripherals addObject:peripheral];
		[discoveryDelegate discoveryDidRefresh];
	}
}

#pragma mark Connectivity
//----------------------Connect/Disconnect--------------------------------//

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"Peripheral Connected");
	peripheral.delegate = self;
	currentlyConnectedDevice = peripheral;
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
				  error:(NSError *)error
{
	if (peripheral != currentlyConnectedDevice) {
		NSLog(@"Error disconnected peripheral is not the peripheral this app is managing!");
		return;
	}
	if (error) {
		NSLog(@"Error with disconnecting peripheral: %@", error);
		return;
	}
	currentlyConnectedDevice = nil;
}

#pragma mark - CBPeripheralDelegate - Discovery
/****************************************************************************/
/*					CBPeripheral Delagate methods							*/
/****************************************************************************/
//----------------------Discovery Functions---------------------------------//
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *) error
{
	if (peripheral != currentlyConnectedDevice)
	{
		NSLog(@"Wrong peripheral sent to this app:%@\n", peripheral.name);
		return;
	}
	else if (error)
	{
		NSLog(@"Error: %@\n", error);
		return;
	}
	
	NSArray *services = nil;
	NSArray *uuids = [NSArray arrayWithObjects:tileDisplayStringUUID, nil];
	
	services = [peripheral services];
	if (services || ![services count]) {
		NSLog(@"Peripheral does not have any services.");
		return;
	}
	
	for (CBService *service in services)
	{
		NSLog(@"Service found with UUID %@", service.UUID);
		
		if ([service.UUID isEqual:tileDisplayStringUUID])
		{
			tileConfigurationService = service;
			break;
		}
	}
	
	if (!tileConfigurationService) {
		NSLog(@"Error: Tile Configuration service not found! Was the correct device connected?");
		return;
	}
	
	[currentlyConnectedDevice discoverCharacteristics:uuids forService:tileConfigurationService];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
			  error:(NSError *)error
{
	NSArray *characteristics = [service characteristics];
	
	if (peripheral != currentlyConnectedDevice)
	{
		NSLog(@"Wrong peripheral sent to this app:%@\n", peripheral.name);
		return;
	}
	else if (service != tileConfigurationService)
	{
		NSLog(@"Wrong service reportin to this peripheral: %@\n", service.UUID);
		return;
	}
	else if (error)
	{
		NSLog(@"Error: %@\n", error);
		return;
	}
	
	// Find the characteristic to set the display of the tile
	for (CBCharacteristic *characteristic in characteristics) {
		if ([[characteristic UUID] isEqual:tileDisplayStringUUID])
		{
			tileDisplayStringCharacteristic = characteristic;
			break;
		}
	}
	if (tileDisplayStringCharacteristic == nil) {
		NSLog(@"Error: tileDisplayStringCharacteristic not found!");
		return;
	}
	
	if (stringToWriteToTile) {					// If our string is ready to write, then write it.
		[self writeStringToPeripheral:nil];		// We don't pass a string, because it is already stored.
	} else {
		[currentlyConnectedDevice readValueForCharacteristic:tileDisplayStringCharacteristic];	
	}
	
}

#pragma mark Characteristics
//------------------Characteristic Read/Write------------------------------//

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
			  error:(NSError *)error
{
	if (error) {
		NSLog(@"Error writing value to characteristic: %@\n", [error localizedDescription]);
	}
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
			  error:(NSError *)error
{
	if (error) {
		NSLog(@"Error updating value for characteristic: %@\n", [error localizedDescription]);
	}
	stringReadFromPeripheral = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding]; //Endinaness warning!!!
	[discoveryDelegate discoveryDidRefresh];
}


@end
