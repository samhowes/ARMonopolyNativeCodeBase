//
//  LeDiscovery.m
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMBluetoothManager.h"

//----------------------Bluetooth Constants-------------------------------//

const NSString *ARMBluetoothManagerErrorDomain = @"ARMBluetoothManagerErrorDomain";

NSString *const kGameTileConfigurationServiceUUIDString 		= @"DEADF154-0000-0000-0000-0000DEADF154";
NSString *const kGameTileDisplayStringCharacteristicUUIDString 	= @"4431";


@interface ARMBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	
    CBCentralManager 	*centralManager;
	NSString			*uuidStringToScanWith;
	
	CBService			*tileConfigurationService;
	CBCharacteristic	*tileDisplayStringCharacteristic;
	
	CBUUID				*tileConfigurationServiceUUID;
	CBUUID				*tileDisplayStringUUID;
	
	NSString			*stringToWriteToTile;
	
}

@property (readwrite) BluetoothManagerState state;

@end


@implementation ARMBluetoothManager

@synthesize delegate;
@synthesize state;

#pragma mark - Public Actions
/****************************************************************************/
/*									Lifecycle								*/
/****************************************************************************/

+ (id) sharedInstance
{
	static ARMBluetoothManager *this = nil;		// Get a permanent pointer to our main instance

	if (!this) {
		this = [[ARMBluetoothManager alloc] init];
	}
	
	return this;
}

- (void)finishTasksWithoutDelegateAndPreserveState
{
	//if (centralManager) [centralManager stopScan];
	
    //TODO
    delegate = nil;
    // do something better with the central manager
}

- (id)init
{
	self = [super init];
	if (self) {
		state = kNotInitialized;
	}
	return self;
}

- (void)startBluetooth
{
    // Get the System BT Manager kicked off with the main queue
    if (!centralManager)
    {
        state = kInitializing;
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    else
    {
        if ([centralManager state] == CBCentralManagerStatePoweredOff)
        {
            state = kWaitingForBluetoothToBeEnabled;
            [self notifyDelegateWithError:[NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:kBluetoothPoweredOffWhenResumingErrorCode userInfo:nil]];
        }
    }
}

- (void)notifyDelegateWithError:(NSError *)error
{
    if (delegate)
    {
        [delegate bluetoothManagerDidRefreshWithError:error];
    }
}


#pragma mark - CBManagerDelegate
/****************************************************************************/
/*						CBManager Delagate methods							*/
/****************************************************************************/

- (void) centralManagerDidUpdateState:(CBCentralManager *)central // move this method up higher for progressive reading
{
	switch ([centralManager state]) {
		case CBCentralManagerStatePoweredOff:
			if (state == kNotInitialized || state == kInitializing || state == kReadyToScan)
            {
                state = kWaitingForBluetoothToBeEnabled;
                
                [self notifyDelegateWithError:[NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:kBluetoothPoweredOffErrorCode userInfo:nil]];
            }
            // TODO manage my data structures here
            
			[self notifyDelegateWithError:nil];
			
			break;
			
		case CBCentralManagerStateUnauthorized: //cleanup
			/* Tell user the app is not allowed and cleanup */
            state = kFatalUnauthorized;
            [self notifyDelegateWithError:[NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:kBluetoothUnauthorizedErrorCode userInfo:nil]];
            // clean some things up if necessary
            //TODO
            break;
		
        case CBCentralManagerStateUnsupported:  //cleanup
			/*hopefully the framework will tell the user */
            state = kFatalUnsupported;
			[self notifyDelegateWithError:[NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:kBluetoothUnsupportedErrorCode userInfo:nil]];
            break;
			
		case CBCentralManagerStateUnknown: // cleanup
			/* Not sure what to do, lets just wait until something else happens */
            //TODO Figure out what to set the state to and do here
			
            [self notifyDelegateWithError:[NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:kBluetoothUnknownStateErrorCode userInfo:nil]];
            break;
			
		case CBCentralManagerStatePoweredOn:
            state = kReadyToScan;
            
            // TODO manage internal data structures
            
            // Retrieve available devices without scanning
			
            // we're not going to bother implementing saved devices
            [centralManager retrieveConnectedPeripheralsWithServices:
             [NSArray arrayWithObject:[CBUUID UUIDWithString:kGameTileConfigurationServiceUUIDString]]];
            
            [self notifyDelegateWithError:nil];
			
            break;
			
		case CBCentralManagerStateResetting:
            state = kResettingBecauseOfSystemReset;
            [self notifyDelegateWithError:[NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:kBluetoothResettingErrorCode userInfo:nil]];
            // TODO: Manage internal data structures
			break;
	}
}

#pragma mark Discovery
/****************************************************************************/
/*								Discovery                                   */
/****************************************************************************/
/*
- (void)scanForGameTiles
{
	if ([centralManager state] != CBCentralManagerStatePoweredOn) {		// Only start scanning if the bluetooth is actually on
        // change this statement to make sure that the view controller only calls this in the right order
		return;
	}
	
	NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:uuidStringToScanWith],nil];   //rename local variable
    // comment on these options
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
	
	[centralManager scanForPeripheralsWithServices:uuidArray options:options]; // there must be a couple more checks i need here....
}

*/
#pragma mark Connectivity
/****************************************************************************/
/*						Connection/Disconnection                            */
/****************************************************************************/
/*
- (void) connectPeripheral:(CBPeripheral *)peripheral // WHen is this executed and by who? this should be an internal mapping after receiving an index path from tableview:didselectrowatindexpath:
{
	//receive instruction from viewcontroller
	[centralManager connectPeripheral:peripheral options:nil];
}

- (void) disconnectPeripheral       // I need some state check here, as well as error reporting
{
    //connectionstatuscheck
	tileDisplayStringCharacteristic = nil;
	tileConfigurationService = nil;
	//if (currentlyConnectedDevice)
	//{
//		[centralManager cancelPeripheralConnection:currentlyConnectedDevice];
//	}
    //connectionstatus update
}

*/
#pragma mark Read/Write
/****************************************************************************/
/*								Read/Write		                            */
/****************************************************************************/
/*
- (void) readStringFromPeripheral
{
	if (!tileDisplayStringCharacteristic){
		NSLog(@"Error: Peripheral not yet connected!");
		return;
	}
//	[currentlyConnectedDevice readValueForCharacteristic:tileDisplayStringCharacteristic];
}

- (void) writeStringToPeripheral:(NSString *)stringToWrite
{
	if (stringToWrite) {						// Make sure to store the string, because we might not be able to write it now
		stringToWriteToTile = stringToWrite;
		NSLog(@"String queued for delivery");
	}
	if (tileDisplayStringCharacteristic) {		// Make sure our peripheral is actually connected.
//		[currentlyConnectedDevice writeValue:[stringToWriteToTile dataUsingEncoding:NSASCIIStringEncoding]
//						   forCharacteristic:tileDisplayStringCharacteristic
//										type:CBCharacteristicWriteWithResponse];
	}
}
*/
#pragma mark Discovery
//----------------------Discovery Functions--------------------------------//
/*- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	if (![foundPeripherals containsObject:peripheral]) { // check the allow duplicates option
        // check if the array is initialized
		[foundPeripherals addObject:peripheral];
		[discoveryDelegate discoveryDidRefresh];    // add error reporting
	}
}*/

#pragma mark Connectivity
//----------------------Connect/Disconnect--------------------------------//
/*
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"Peripheral Connected");
    //update connection state
    //check if it is the right peripheral
	peripheral.delegate = self;
	currentlyConnectedDevice = peripheral;
    // update the view controller
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
				  error:(NSError *)error
{
    // conectionstate management
	if (peripheral != currentlyConnectedDevice) {
		NSLog(@"Error disconnected peripheral is not the peripheral this app is managing!");
		return;
	}
	if (error) {
		NSLog(@"Error with disconnecting peripheral: %@", error);
		return;
	}
	currentlyConnectedDevice = nil;
    //update the view controller
} */

#pragma mark - CBPeripheralDelegate - Discovery
/****************************************************************************/
/*					CBPeripheral Delagate methods							*/
/****************************************************************************/
//----------------------Discovery Functions---------------------------------//
/*
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *) error
{
	//connectionStatusUpdate
    //report error to view controller
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
	
	NSArray *services = nil;// name this better
	NSArray *uuids = [NSArray arrayWithObjects:tileDisplayStringUUID, nil]; // semantically name this variable
	
	services = [peripheral services];
	if (services || ![services count]) { // make this a better checking statement
		NSLog(@"Peripheral does not have any services.");
        //update connectionstatus
        //update delegate
		return;
	}
	
	for (CBService *service in services)
	{
		NSLog(@"Service found with UUID %@", service.UUID);
		
		if ([service.UUID isEqual:tileDisplayStringUUID])
		{
			tileConfigurationService = service;
            //update connectionStatus
			break;
		}
	}
	
	if (!tileConfigurationService) {
		NSLog(@"Error: Tile Configuration service not found! Was the correct device connected?");
        //update the delegate
		return;
	}
	
    // should this be done by the delegate?
	[currentlyConnectedDevice discoverCharacteristics:uuids forService:tileConfigurationService];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
			  error:(NSError *)error
{
	NSArray *characteristics = [service characteristics];//rename
	
    //updateConnectionStatus
    //notify delegate of errors
	if (peripheral != currentlyConnectedDevice)
	{
		NSLog(@"Wrong peripheral sent to this app:%@\n", peripheral.name);
		return;
	}
	else if (service != tileConfigurationService)
	{
		NSLog(@"Wrong service reporting to this peripheral: %@\n", service.UUID);
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
        //update delegate
        //update connectionstatus
		return;
	}
	
    //do this later with the delegate
	if (stringToWriteToTile) {					// If our string is ready to write, then write it.
		[self writeStringToPeripheral:nil];		// We don't pass a string, because it is already stored.
	} else {
		[currentlyConnectedDevice readValueForCharacteristic:tileDisplayStringCharacteristic];	
	}
	
} */

#pragma mark Characteristics
//------------------Characteristic Read/Write------------------------------//
/*
- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
			  error:(NSError *)error
{
	//update connectionStatus
    //update delegate with error
    if (error) {
		NSLog(@"Error writing value to characteristic: %@\n", [error localizedDescription]);
	}
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
			  error:(NSError *)error
{
    //update connectionstatus
    //update delegate
	if (error) {
		NSLog(@"Error updating value for characteristic: %@\n", [error localizedDescription]);
	}
	stringReadFromPeripheral = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding]; //Endinaness warning!!!
	[discoveryDelegate discoveryDidRefresh];
} */


@end
