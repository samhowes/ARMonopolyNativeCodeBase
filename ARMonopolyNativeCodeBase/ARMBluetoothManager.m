//
//  LeDiscovery.m
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//
#import <CoreBluetooth/CBAdvertisementData.h>
#import <CoreBluetooth/CBUUID.h>
#import "ARMBluetoothManager.h"
#import "ARMPlayerInfo.h"

//----------------------Bluetooth Constants-------------------------------//

const NSString *ARMBluetoothManagerErrorDomain = @"ARMBluetoothManagerErrorDomain";

const NSString * kGameTileConfigurationServiceUUIDString 		= @"1123";
const NSString * kGameTileDisplayStringCharacteristicUUIDString = @"1125";
const NSString * kGameTileImageTargetIDCharacteristicUUIDString = @"1124";

const NSInteger kMaximumNumberOfConnectionAttempts =            4;
const NSInteger kMaximumNumberOfWriteAttempts =                 4;
const NSInteger kMaximumNumberOfReadAttempts =                  4;
const NSInteger kMaximumNumberOfAttributeDiscoveryAttempts =    4;

const NSInteger kMaximumNumberOfErrorRecoveryAttempts =         10;


NSError *ARMErrorWithCode(ARMBluetoothManagerErrorCode code)
{
    return [NSError errorWithDomain:[ARMBluetoothManagerErrorDomain copy] code:code userInfo:nil];
}

@interface ARMBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	
    CBCentralManager 	*centralManager;
    
    NSMutableArray      *discoveredGameTilePeripheralsArray;
    NSMutableArray      *discoveredInvalidPeripheralsArray;
    
    CBService           *gameTileConfigurationService;
    
    CBCharacteristic    *gameTileDisplayStringCharacteristic;
    CBCharacteristic    *gameTileImageTargetIDCharacteristic;
    
    CBPeripheral        *connectedGameTile;
    
    NSString            *valueStringReadFromImageTargetIDCharacteristic;
    
    ARMGameTileIDType   IDThatWasChosenToConnectTo;
    
    NSInteger           numberOfConnectionAttempts;
    NSInteger           numberOfWriteAttempts;
    NSInteger           numberOfReadAttempts;
    NSInteger           numberOfAttributeDiscoveryAttempts;
    
    NSInteger           numberOfAttemptsToRecoverFromError;
    
    BOOL displayStringHasBeenWritenToGameTile;
}


@property (readwrite) BluetoothManagerState state;
@property (readwrite) NSString *connectedGameTileNameString;
@property (readwrite) NSMutableArray *discoveredGameTileNamesArray;

@end


@implementation ARMBluetoothManager

@synthesize delegate;
@synthesize state;
@synthesize connectedGameTileNameString;
@synthesize discoveredGameTileNamesArray;

#pragma mark - Public Actions
/****************************************************************************/
/*									Lifecycle								*/
/****************************************************************************/

+ (id)sharedInstance
{
	static ARMBluetoothManager *this = nil;		// Get a permanent pointer to our main instance

	if (!this) {
		this = [[ARMBluetoothManager alloc] init];
	}
	
	return this;
}

- (id)init
{
	self = [super init];
	if (self) {
		state = kNotInitialized;
	}
	return self;
}

#pragma mark TODO Resume State Properly
- (void)startBluetooth
{
    // Get the System BT Manager kicked off with the main queue
    if (state == kFatalUnrecoverable)
    {
        return;
    }
    if (!centralManager)
    {
        state = kInitializing;
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    else
    {
        state = kInitializing;
        [self centralManagerDidUpdateState:centralManager];
    }
}

#pragma mark TODO preserve state properly
- (void)finishTasksWithoutDelegateAndPreserveState
{
    delegate = nil;
    if (centralManager)
    {
        [centralManager stopScan];
    }
    switch (state)
    {
        case kFatalUnauthorized: break;
        case kFatalUnsupported: break;
        case kNotInitialized: break;
        case kInitializing:
            state = kNotInitialized;
            break;
            
        case kWaitingForBluetoothToBeEnabled: break;
        case kReadyToScanForGameTiles: break;
            
        case kResettingBecauseOfSystemReset:
            state = kNotInitialized;
            break;
            
        case kScanningForGameTiles:
            
            state = kReadyToScanForGameTiles;
            break;
            
        default:
            state = kNotInitialized;
            break;
    }
}

- (void)notifyDelegateWithError:(NSError *)error
{
    if (delegate)
    {
        [delegate bluetoothManagerDidRefreshWithError:error];
    }
}


#pragma mark Discovery
/****************************************************************************/
/*                          Public Methods                                  */
/****************************************************************************/

- (NSError *)scanForGameTiles
{
    if (state == kScanningForGameTiles)
    {
        return nil;
    }
	if (state != kReadyToScanForGameTiles || [centralManager state] != CBCentralManagerStatePoweredOn)
    {
        // Only start scanning if the bluetooth is actually on
		return ARMErrorWithCode(kUnableToScanForGameTilesErrorCode);
	}
	state = kScanningForGameTiles;
    IDThatWasChosenToConnectTo = -1;
    [discoveredGameTilePeripheralsArray removeAllObjects];
    [discoveredGameTileNamesArray       removeAllObjects];
    
    // TODO: alter this from testing to only search for the GameTile Service
	NSArray *serviceUUIDToScanForArray = [NSArray new];//[NSArray arrayWithObject:[CBUUID UUIDWithString:kGameTileConfigurationServiceUUIDString]];
    
	[centralManager scanForPeripheralsWithServices:serviceUUIDToScanForArray options:nil];
    // there must be a couple more checks i need here....
    return nil;
}

- (NSError *)connectToGameTileWithID:(ARMGameTileIDType)gameTileID
{
    if (state != kScanningForGameTiles)
    {
        return ARMErrorWithCode(kNotReadyToConnectToGameTileErrorCode);
    }
    else if (connectedGameTile)
    {
        // if we're already connected to a game tile, don't connect to another one
        return ARMErrorWithCode(kAlreadyConnectedToGameTileErrorCode);
    }
    CBPeripheral *gameTileToConnectTo = [discoveredGameTilePeripheralsArray objectAtIndex:gameTileID];
	if (!gameTileToConnectTo)
    {
        return ARMErrorWithCode(kInvalidGameTileIDErrorCode);
    }
    
    IDThatWasChosenToConnectTo = gameTileID;
    valueStringReadFromImageTargetIDCharacteristic = nil;
    displayStringHasBeenWritenToGameTile = NO;
    numberOfConnectionAttempts = 0;
    
    [centralManager stopScan];
    [centralManager connectPeripheral:gameTileToConnectTo options:nil];
    state = kConnectingToGameTile; // only change state after we know there are no errors
    
    return nil;
}

- (NSError *)exchangeDataWithConnectedGameTile
{
    if (state != kReadyToExchangeDataWithGameTile || !connectedGameTile
        || !gameTileImageTargetIDCharacteristic || !gameTileDisplayStringCharacteristic)
    {
        return ARMErrorWithCode(kNotReadyToExchangeDataErrorCode);
    }
    
    
    state = kExchangingDataWithGameTile;
    numberOfWriteAttempts++;
    numberOfReadAttempts++;
    [connectedGameTile writeValue:[[[ARMPlayerInfo sharedInstance] playerDisplayName] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:gameTileDisplayStringCharacteristic type:CBCharacteristicWriteWithResponse];
    [connectedGameTile readValueForCharacteristic:gameTileImageTargetIDCharacteristic];
    return nil;
}

- (NSString *)getNameOfConnectedGameTile
{
    if (connectedGameTile)
    {
        return [connectedGameTile name];
    }
    else
    {
        return nil;
    }
}

- (void)disconnectFromGameTile
{
    NSLog(@"Initiating disconnect from GameTile");
    if ([connectedGameTile state] != CBPeripheralStateDisconnected)
    {
        state = kDisconnectingFromGameTile;
        [centralManager cancelPeripheralConnection:connectedGameTile];
    }
    else
    {
        connectedGameTile = nil;
        [centralManager stopScan];
        state = kReadyToScanForGameTiles;
    }
    
    return;
}

- (void)recoverFromError:(NSError *)error
{
    NSLog(@"Attempting to recover from error in state '%d'", state);
    numberOfAttemptsToRecoverFromError++;
    if (numberOfAttemptsToRecoverFromError >= kMaximumNumberOfErrorRecoveryAttempts)
    {
        [self notifyDelegateWithError:ARMErrorWithCode(kFatalErrorStateNotificationErrorCode)];
        state = kFatalUnrecoverable;
        centralManager = nil;
        return;
    }
    
    if ([[error domain] isEqualToString:[ARMBluetoothManagerErrorDomain copy]])
    {
        // reset our variables to a valid state so this error doesn't happen again
        switch ([error code])
        {
            case kUnableToScanForGameTilesErrorCode:
                // lets reinitialize with our standard method
                state = kInitializing;
                [self centralManagerDidUpdateState:centralManager];
                return;
                break;
                
            case kInvalidGameTileIDErrorCode:
                // We'll synchronize our arrays here and that will solve the problem
                discoveredGameTileNamesArray = [NSMutableArray new];
                for (CBPeripheral *peripheral in discoveredGameTilePeripheralsArray)
                {
                    NSString *peripheralName = [peripheral name];
                    if (!peripheralName)
                    {
                        peripheralName = @"Unknown";
                    }
                    
                    [discoveredGameTileNamesArray addObject:(NSString *)[peripheral name]];
                }
                state = kScanningForGameTiles;
                return;
                break;
                
            case kNotReadyToExchangeDataErrorCode:
                // Try to rediscover the services of the game tile
                numberOfAttributeDiscoveryAttempts++;
                state = kDiscoveringGameTileAttributes;
                [self discoverGameTileServices];
                return;
                break;
                
            default:
                break;
        }
    }
    
    // We fell through the above statement, recover based on internal state
    if ([centralManager state] != CBCentralManagerStatePoweredOn)
    {
        // assume that our state variable is invalid
        switch ([centralManager state])
        {
            case CBCentralManagerStatePoweredOff:
                state = kWaitingForBluetoothToBeEnabled;
                    
                [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothPoweredOffNotificationErrorCode)];
                // TODO manage my data structures here
                break;
                
            case CBCentralManagerStateUnauthorized:
                /* Tell user the app is not allowed and cleanup */
                state = kFatalUnauthorized;
                [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothUnauthorizedNotificationErrorCode)];
                // clean some things up if necessary
                //TODO
                break;
                
            case CBCentralManagerStateUnsupported:  //cleanup
                state = kFatalUnsupported;
                [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothUnsupportedNotificationErrorCode)];
                break;
                
            case CBCentralManagerStateUnknown: // cleanup
                /* Not sure what to do, lets just wait until something else happens */
                state = kInitializing;
                
                [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothUnknownStateNotificationErrorCode)];
                break;
                
            case CBCentralManagerStateResetting:
                state = kResettingBecauseOfSystemReset;
                [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothResettingNotificationErrorCode)];
                // TODO: Manage internal data structures
                break;
        }
    }
    else
    {
        // we've narrowed it down to a state with a valid Central Manager
        // at a minimum, we are in the ReadyToScanForGameTiles state
        // assume that the state variable is invalid and reset it to a valid
        // value and execute the right action to get us back on track.
        
        switch (state)
        {
            // This is okay, start trying to exchange data again
            case kCompletedExchangingDataWithGameTile:
            case kExchangingDataWithGameTile:
            {
                switch ([connectedGameTile state])
                {
                    case CBPeripheralStateConnected:
                        // lets rediscover our attributes
                        state = kDiscoveringGameTileAttributes;
                        [self discoverGameTileServices];
                        break;
                    
                    case CBPeripheralStateConnecting:
                        state = kConnectingToGameTile;
                        break;
                        
                    case CBPeripheralStateDisconnected:
                        if (numberOfConnectionAttempts < kMaximumNumberOfConnectionAttempts)
                        {
                            // try another connection
                            numberOfConnectionAttempts++;
                            [centralManager connectPeripheral:connectedGameTile options:nil];
                        }
                        else
                        {
                            // the view controller will take it from here
                            state = kReadyToScanForGameTiles;
                            connectedGameTile = nil;
                            [self notifyDelegateWithError:ARMErrorWithCode(kReconnectionLimitExceededNotificationErrorCode)];
                        }
                        return; // we don't need any more error handling from here
                        break;
                        
                    default:
                        connectedGameTile = nil;
                        break;
                }
            }
                break;
            
            // Not that bad, lets try to discover our peripheral's attributes again
            case kDiscoveringGameTileAttributes:
            case kReadyToExchangeDataWithGameTile:
                if (numberOfAttributeDiscoveryAttempts < kMaximumNumberOfAttributeDiscoveryAttempts)
                {
                    state = kDiscoveringGameTileAttributes;
                    numberOfAttributeDiscoveryAttempts++;
                    [self discoverGameTileServices];
                }
                else
                {
                    // We've exceeded our discovery attempts, it looks like we don't actually want this gametile
                    [self handleInvalidPeripheral];
                    return;
                }
                break;
             
            // Make sure we have canceled the connection and scan for game tiles again later
            case kConnectedToUnknownPeripheral:
                [self handleInvalidPeripheral];
                return;
                break;
                
            // We know that the central manager is on, so we can scan for tiles
            // Set the state accordingly, and tell our delegate that we are valid
            case kNotInitialized:
            case kInitializing:
            case kWaitingForBluetoothToBeEnabled:
            case kResettingBecauseOfSystemReset:
            case kFatalUnauthorized:
            case kFatalUnsupported:
                
            // Assume our connection failed and we have to scan for game tiles again
            case kConnectingToGameTile:
            case kDisconnectingFromGameTile:
                
            case kScanningForGameTiles:
            case kReadyToScanForGameTiles:
            default:
                connectedGameTile = nil;
                discoveredGameTileNamesArray = nil;
                discoveredGameTilePeripheralsArray = nil;
                discoveredInvalidPeripheralsArray = nil;
                gameTileConfigurationService = nil;
                gameTileDisplayStringCharacteristic = nil;
                gameTileImageTargetIDCharacteristic = nil;
                valueStringReadFromImageTargetIDCharacteristic = nil;
                
                numberOfReadAttempts = 0;
                numberOfWriteAttempts = 0;
                numberOfConnectionAttempts = 0;
                
                state = kReadyToScanForGameTiles;
                [self notifyDelegateWithError:nil];
                break;
        }
    }

}

- (void)discoverGameTileServices
{
    NSLog(@"Attempting to discover services for GameTile with name: '%@'", [connectedGameTile name]);
    [connectedGameTile discoverServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:[kGameTileConfigurationServiceUUIDString copy]]]];
}

- (void)discoverGameTileCharacteristics
{
    NSLog(@"Attempting to discover characteristics for GameTile with name: '%@'", [connectedGameTile name]);
    [connectedGameTile discoverCharacteristics:
     [NSArray arrayWithObjects: [CBUUID UUIDWithString:[kGameTileDisplayStringCharacteristicUUIDString copy]],
      [CBUUID UUIDWithString:[kGameTileImageTargetIDCharacteristicUUIDString copy]],
      nil]
                                    forService:gameTileConfigurationService];
}

- (void)handleInvalidPeripheral
{
    NSLog(@"Handling Invalid peripheral with name: '%@'", [connectedGameTile name]);
    [discoveredInvalidPeripheralsArray  addObject:connectedGameTile];
    [discoveredGameTilePeripheralsArray removeObjectAtIndex:IDThatWasChosenToConnectTo];
    [discoveredGameTileNamesArray       removeObjectAtIndex:IDThatWasChosenToConnectTo];
    if ([connectedGameTile state] != CBPeripheralStateDisconnected)
    {
        [centralManager cancelPeripheralConnection:connectedGameTile];
        state = kDisconnectingFromGameTile;
    }
    else
    {
        state = kReadyToScanForGameTiles;
        connectedGameTile = nil;
    }
    [self notifyDelegateWithError:ARMErrorWithCode(kConnectedPeripheralIsNotAGameTileNotificationErrorCode)];
}

#pragma mark - CBManagerDelegate
/****************************************************************************/
/*						CBManager Delagate methods							*/
/****************************************************************************/

- (void) centralManagerDidUpdateState:(CBCentralManager *)central // move this method up higher for progressive reading
{
	NSLog(@"Central manager updated its state to: %d", [central state]);
    switch ([centralManager state]) {
		case CBCentralManagerStatePoweredOff:
			if (state == kNotInitialized || state == kInitializing || state == kReadyToScanForGameTiles)
            {
                state = kWaitingForBluetoothToBeEnabled;
                
                [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothPoweredOffNotificationErrorCode)];
            }
            // TODO manage my data structures here
            
			[self notifyDelegateWithError:nil];
			
			break;
			
		case CBCentralManagerStateUnauthorized: //cleanup
			/* Tell user the app is not allowed and cleanup */
            state = kFatalUnauthorized;
            [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothUnauthorizedNotificationErrorCode)];
            // clean some things up if necessary
            //TODO
            break;
            
        case CBCentralManagerStateUnsupported:  //cleanup
			/*hopefully the framework will tell the user */
            state = kFatalUnsupported;
			[self notifyDelegateWithError:ARMErrorWithCode(kBluetoothUnsupportedNotificationErrorCode)];
            break;
			
		case CBCentralManagerStateUnknown: // cleanup
			/* Not sure what to do, lets just wait until something else happens */
            //TODO Figure out what to set the state to and do here
			
            [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothUnknownStateNotificationErrorCode)];
            break;
			
		case CBCentralManagerStatePoweredOn:
            state = kReadyToScanForGameTiles;
            
            // Retrieve available devices without scanning
            // we're not going to bother implementing saved devices
            [centralManager retrieveConnectedPeripheralsWithServices:
             [NSArray arrayWithObject:[CBUUID UUIDWithString:[kGameTileConfigurationServiceUUIDString copy]]]];
            
            [self notifyDelegateWithError:nil];
			
            break;
			
		case CBCentralManagerStateResetting:
            state = kResettingBecauseOfSystemReset;
            [self notifyDelegateWithError:ARMErrorWithCode(kBluetoothResettingNotificationErrorCode)];
            // TODO: Manage internal data structures
			break;
	}
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!discoveredGameTilePeripheralsArray)
    {
        discoveredGameTilePeripheralsArray = [NSMutableArray new];
    }
    if (!discoveredGameTileNamesArray)
    {
        discoveredGameTileNamesArray = [NSMutableArray new];
    }
    
    if (![discoveredGameTilePeripheralsArray containsObject:peripheral])
    {
        // check the allow duplicates option
        NSString *peripheralName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        if (!peripheralName)
        {
            peripheralName = @"Unknown";
        }
        NSLog(@"Peripheral with name %@ found", peripheralName);
        [discoveredGameTilePeripheralsArray addObject:peripheral];
        [discoveredGameTileNamesArray       addObject:peripheralName];
        [self notifyDelegateWithError:nil];
    }
}


#pragma mark Connectivity
//----------------------Connect/Disconnect--------------------------------//

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"Peripheral with Name: %@ Connected", [peripheral name]);
    
	[peripheral setDelegate:self];
	connectedGameTile = peripheral;
    connectedGameTileNameString = [peripheral name];
    state = kDiscoveringGameTileAttributes;
    gameTileConfigurationService = nil;
    gameTileDisplayStringCharacteristic = nil;
    gameTileImageTargetIDCharacteristic = nil;
    numberOfReadAttempts = 0;
    numberOfWriteAttempts = 0;
    
    numberOfAttributeDiscoveryAttempts = 1;
    [self discoverGameTileServices];
    [self notifyDelegateWithError:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnecting from peripheral with name: '%@'", [peripheral name]);
    // conectionstate management
    if (peripheral != connectedGameTile)
    {
        NSLog(@"Error disconnected peripheral is not the peripheral this app is managing!");
        // don't change state because I should still be disconnecting my peripheral
        return;
    }
    else if (state != kDisconnectingFromGameTile && error)
    {
        switch ([error code])
        {
            case CBErrorConnectionTimeout:
            case CBErrorPeripheralDisconnected: // the peripheral disconnected us, lets try to reconnect
                NSLog(@"Peripheral disconnected or timed out, trying to connect again.");
                
                if (numberOfConnectionAttempts > kMaximumNumberOfConnectionAttempts)
                {
                    [self notifyDelegateWithError:ARMErrorWithCode(kReconnectionLimitExceededNotificationErrorCode)];
                    connectedGameTile = nil;
                    state = kScanningForGameTiles;
                    return;
                }
                
                [centralManager connectPeripheral:connectedGameTile options:nil];
                state = kConnectingToGameTile;
                numberOfConnectionAttempts++;
                return;
                break;
                
            default:
                [self notifyDelegateWithError:error];
                return;
                break;
        }
        
    }
    
    gameTileConfigurationService = nil;
    gameTileDisplayStringCharacteristic = nil;
    gameTileImageTargetIDCharacteristic = nil;
    numberOfConnectionAttempts = 0;
    connectedGameTile = nil;
    state = kReadyToScanForGameTiles;
    [self notifyDelegateWithError:nil]; // ... maybe I want to change this to a completion handler
 }

#pragma mark - CBPeripheralDelegate - Discovery
/****************************************************************************/
/*					CBPeripheral Delagate methods							*/
/****************************************************************************/
//----------------------Discovery Functions---------------------------------//

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *) error
{
    NSLog(@"Discovered services for peripheral with name: '%@'", [peripheral name]);
    // check if I canceled the connection and if it is the right peripheral
    if (!connectedGameTile)
    {
        return;
    }
    else if (peripheral != connectedGameTile)
	{
		NSLog(@"Wrong peripheral sent to this app:%@ ignoring.\n", peripheral.name);
		return;
	}
	else if (error)
	{
		[self notifyDelegateWithError:error];
		return;
	}
	
	NSArray *discoveredServices;
	//NSArray *uuids = [NSArray arrayWithObjects:tileDisplayStringUUID, nil]; // semantically name this variable
	
	discoveredServices = [peripheral services];
	if (!discoveredServices || [discoveredServices count] == 0) { // make this a better checking statement
		NSLog(@"Peripheral is not a GameTile!");
        [self handleInvalidPeripheral];
		return;
	}
	
    CBUUID *gameTileConfigurationServiceCBUUID = [CBUUID UUIDWithString:[kGameTileConfigurationServiceUUIDString copy]];
	for (CBService *service in discoveredServices)
	{
		NSLog(@"Service found with UUID %@", service.UUID);
		
		if ([[service UUID] isEqual:gameTileConfigurationServiceCBUUID])
		{
			gameTileConfigurationService = service;
            
			break;
		}
	}
	
	if (!gameTileConfigurationService) {
        [self handleInvalidPeripheral];
		return;
	}
    
	[self discoverGameTileCharacteristics];
}


- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
			  error:(NSError *)error
{
    NSLog(@"Discovered characteristics for peripheral with name: '%@'", [peripheral name]);
	NSArray *discoveredCharacteristics = [service characteristics];
	
	if (!connectedGameTile)
    {
        return;
    }
    else if (peripheral != connectedGameTile)
	{
		NSLog(@"Wrong peripheral sent to this app:%@\n", peripheral.name);
		return;
	}
	else if (service != gameTileConfigurationService)
	{
		NSLog(@"Wrong service reporting to this peripheral: %@\n", service.UUID);
		return;
	}
	else if (error)
	{
        switch ([error code])
        {
            case CBErrorInvalidParameters:
                [self handleInvalidPeripheral];
                return;
                break;
        }
		[self notifyDelegateWithError:error]; // we fell through
		return;
	}
    else if
    (!discoveredCharacteristics || [discoveredCharacteristics count] == 0)
    {
        [self handleInvalidPeripheral];
    }
	
    CBUUID *gameTileDisplayStringCBUUID = [CBUUID UUIDWithString:[kGameTileDisplayStringCharacteristicUUIDString copy]];
    CBUUID *gameTileImageTargetIDCBUUID = [CBUUID UUIDWithString:[kGameTileImageTargetIDCharacteristicUUIDString copy]];
    
	// Find the characteristic to set the display of the tile
    for (CBCharacteristic *characteristic in discoveredCharacteristics) {
		if ([[characteristic UUID] isEqual:gameTileDisplayStringCBUUID])
		{
			gameTileDisplayStringCharacteristic = characteristic;
		}
        else if ([[characteristic UUID] isEqual:gameTileImageTargetIDCBUUID])
        {
            gameTileImageTargetIDCharacteristic = characteristic;
        }
        
        if (gameTileDisplayStringCharacteristic && gameTileImageTargetIDCharacteristic)
        {
            break;
        }
	}
	if (!gameTileDisplayStringCharacteristic || !gameTileImageTargetIDCharacteristic)
    {
        [self handleInvalidPeripheral];
        return;
	}
    else
    {
        state = kReadyToExchangeDataWithGameTile;
        [self notifyDelegateWithError:nil];
    }
	
}


#pragma mark Characteristics
//------------------Characteristic Read/Write------------------------------//
- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (connectedGameTile == nil || state == kDisconnectingFromGameTile)
    {
        NSLog(@"Received peripheral write message when connectedGameTile is nil or we are disconnecting from the game tile");
        return;
    }
    else if (peripheral != connectedGameTile)
    {
        NSLog(@"Received peripheral write message for unknown peripheral with name %@", [peripheral name]);
        return;
    }
    else if (error)
    {
		NSLog(@"Error writing value to characteristic: '%@', retrying...", [error localizedDescription]);

        // figure out what to do with the state
        //TODO
        if (numberOfWriteAttempts < kMaximumNumberOfWriteAttempts)
        {
            numberOfWriteAttempts++;
            [connectedGameTile writeValue:[[[ARMPlayerInfo sharedInstance] playerDisplayName] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:gameTileDisplayStringCharacteristic type:CBCharacteristicWriteWithResponse];
        }
        else
        {
            [self disconnectFromGameTile];
            [self notifyDelegateWithError:ARMErrorWithCode(kDataAttemptLimitExceededNotificationErrorCode)];
        }
        
        return;
	}
    
    displayStringHasBeenWritenToGameTile = YES;
    NSLog(@"Successfully wrote User Display String to the GameTile");
    [self completeDataExchange];
}


- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
			  error:(NSError *)error
{
    //update connectionstatus
    //update delegate
	if (connectedGameTile == nil || state == kDisconnectingFromGameTile)
    {
        NSLog(@"Received peripheral read message when connectedGameTile is nil or we are disconnecting from the game tile");
        return;
    }
    else if (peripheral != connectedGameTile)
    {
        NSLog(@"Received peripheral read message for unknown peripheral with name %@", [peripheral name]);
        return;
    }
    else if (error)
    {
       if ([[error domain] isEqualToString:CBATTErrorDomain] && [error code] == CBATTErrorReadNotPermitted)
        {
            [self notifyDelegateWithError:ARMErrorWithCode(kConnectedPeripheralIsNotAGameTileNotificationErrorCode)];
            return;
        }
		NSLog(@"Error reading value from characteristic: '%@', retrying", [error localizedDescription]);
        
        // figure out what to do with the state
        //TODO
        if (numberOfReadAttempts < kMaximumNumberOfReadAttempts)
        {
            numberOfReadAttempts++;
            [connectedGameTile readValueForCharacteristic:gameTileImageTargetIDCharacteristic];
        }
        else
        {
            [self disconnectFromGameTile];
            [self notifyDelegateWithError:ARMErrorWithCode(kDataAttemptLimitExceededNotificationErrorCode)];
        }
        return;
	}

    
	valueStringReadFromImageTargetIDCharacteristic = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]; //Endinaness warning!!!
    NSLog(@"Successfully read the string '%@' from the GameTile!", valueStringReadFromImageTargetIDCharacteristic);
    [self completeDataExchange];
}

- (void)completeDataExchange
{
    if (displayStringHasBeenWritenToGameTile && valueStringReadFromImageTargetIDCharacteristic)
    {
        state = kCompletedExchangingDataWithGameTile;
        [[ARMPlayerInfo sharedInstance] bluetoothDidConnectToGameTileWithName:connectedGameTileNameString imageTargetID:valueStringReadFromImageTargetIDCharacteristic];
        [self notifyDelegateWithError:nil];
    }
}

@end
