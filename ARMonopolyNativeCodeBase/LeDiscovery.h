//
//  LeDiscovery.h
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#pragma mark - Bluetooth Constants
extern NSString *const kTileConfigurationServiceUUIDString;
extern NSString *const kTileDisplayStringCharacteristicUUIDString;

#pragma mark - UIProtocols
/****************************************************************************/
/*							UI protocols									*/
/****************************************************************************/

@protocol LeDiscoveryDelegate <NSObject>
-(void) discoveryDidRefresh;
-(void)	discoveryStatePoweredOff;
@end

#pragma mark - Main Class
/****************************************************************************/
/*							Discovery class									*/
/****************************************************************************/
@interface LeDiscovery : NSObject

+ (id) sharedInstance;				// Class method to create an app-wide object for management
- (void) deleteSharedInstance;		// class mehtod to destroy the instance because we are done with it.

/****************************************************************************/
/*								UI controls									*/
/****************************************************************************/

@property (nonatomic, assign)id<LeDiscoveryDelegate> discoveryDelegate;
@property (nonatomic, assign)id<CBPeripheralDelegate> peripheralDelegate;

/****************************************************************************/
/*							Main Actions									*/
/****************************************************************************/

- (void) startScanningForUUIDString:(NSString *)uuidString;
- (void) stopScanning;

- (void) connectPeripheral:(CBPeripheral *)peripheral;
- (void) disconnectPeripheral;

- (void) readStringFromPeripheral;
- (void) writeStringToPeripheral:(NSString *)stringToWrite;

- (BOOL) isBluetoothOn;

/****************************************************************************/
/*							Access to the devices							*/
/****************************************************************************/
@property (retain, nonatomic) NSMutableArray	*foundPeripherals;
@property (retain, nonatomic) NSMutableArray	*connectedServices;
@property (retain, nonatomic) CBPeripheral 		*currentlyConnectedDevice;
@property (retain, nonatomic) NSString 			*stringReadFromPeripheral;

@end
