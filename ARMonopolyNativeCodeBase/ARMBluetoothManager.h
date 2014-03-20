//
//  LeDiscovery.h
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

extern const NSString *ARMBluetoothManagerErrorDomain;

typedef enum ARMBluetoothManagerErrorCode : NSInteger {
    kBluetoothPoweredOffNotificationErrorCode = 1,              // Bluetooth is disabled
    kBluetoothPoweredOffWhenResumingNotificationErrorCode,      // Messge to startBluetooth was received after initialization, but bluetooth is powered off
    kBluetoothUnauthorizedNotificationErrorCode,                // User has not permitted BTLE access
    kBluetoothUnsupportedNotificationErrorCode,                 // Non BTLE device
    kBluetoothUnknownStateNotificationErrorCode,                // BT is in unknown state
    kBluetoothResettingNotificationErrorCode,                   // BT is resetting for unknown reasons
    kConnectedPeripheralIsNotAGameTileNotificationErrorCode,
    kReconnectionLimitExceededNotificationErrorCode,
    kDataAttemptLimitExceededNotificationErrorCode,
    kFatalErrorStateNotificationErrorCode,
    
    kUnableToScanForGameTilesErrorCode,             // message to scan received when the CBCentral manager hasn't turned on
    kInvalidGameTileIDErrorCode,                    // An incorrect game tile ID was sent to connect to
    kNotReadyToConnectToGameTileErrorCode,          // returned when we are in the incorrect state for connecting to a game tile
    kAlreadyConnectedToGameTileErrorCode,
    kNotReadyToExchangeDataErrorCode
} ARMBluetoothManagerErrorCode;

typedef enum BluetoothManagerState : NSInteger {
    kFatalUnrecoverable,
    kNotInitialized,
    kInitializing,
    kWaitingForBluetoothToBeEnabled,
    kReadyToScanForGameTiles,
    kResettingBecauseOfSystemReset,
    kFatalUnauthorized,
    kFatalUnsupported,
    kScanningForGameTiles,
    kConnectingToGameTile,
    kDisconnectingFromGameTile,
    kReadyToExchangeDataWithGameTile,
    kExchangingDataWithGameTile,
    kCompletedExchangingDataWithGameTile,
    kDiscoveringGameTileAttributes,
    kConnectedToUnknownPeripheral
    
} BluetoothManagerState;

typedef NSInteger ARMGameTileIDType;

#pragma mark - UIProtocols
/****************************************************************************/
/*							UI protocols									*/
/****************************************************************************/

@protocol ARMBluetoothManagerDelegate <NSObject>

- (void)bluetoothManagerDidRefreshWithError:(NSError *)error;

@end


#pragma mark - Main Class
/****************************************************************************/
/*							Discovery class									*/
/****************************************************************************/
@interface ARMBluetoothManager : NSObject

+ (id) sharedInstance;

- (void)startBluetooth;

- (void)finishTasksWithoutDelegateAndPreserveState;

@property (readonly) BluetoothManagerState state;
@property (readonly) NSString *connectedGameTileNameString;
@property (readonly) NSMutableArray *discoveredGameTileNamesArray;

@property (nonatomic, assign)id<ARMBluetoothManagerDelegate> delegate; // 2: Come up with a better name

- (NSError *)scanForGameTiles;

- (NSError *)connectToGameTileWithID:(ARMGameTileIDType)gameTileID;
- (void)disconnectFromGameTile;

- (NSError *)exchangeDataWithConnectedGameTile;

- (NSString *)getNameOfConnectedGameTile;

- (void)recoverFromError:(NSError *)error;

 
@end
