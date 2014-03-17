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

typedef enum ARMBluetoothManagerErrorCode {
    kBluetoothPoweredOffErrorCode = 1,
    kBluetoothPoweredOffWhenResumingErrorCode,
    kBluetoothUnauthorizedErrorCode,
    kBluetoothUnsupportedErrorCode,
    kBluetoothUnknownStateErrorCode,
    kBluetoothResettingErrorCode
} ARMBluetoothManagerErrorCode;

typedef enum BluetoothManagerState {
    kNotInitialized,
    kInitializing,
    kWaitingForBluetoothToBeEnabled,
    kReadyToScan,
    kResettingBecauseOfSystemReset,
    kFatalUnauthorized,
    kFatalUnsupported
} BluetoothManagerState;

typedef NSInteger ARMGameTileID;

#pragma mark - UIProtocols
/****************************************************************************/
/*							UI protocols									*/
/****************************************************************************/

@protocol ARMBluetoothManagerDelegate <NSObject>

-(void) bluetoothManagerDidRefreshWithError:(NSError *)error;

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
@property (nonatomic, assign)id<ARMBluetoothManagerDelegate> delegate; // 2: Come up with a better name

- (void)scanForGameTiles;

- (void)connectToGameTileWithID:(ARMGameTileID)gameTileID;
- (void)disconnectFromGameTile;

- (void)getDataFromConnectedGameTile;

 
@end
