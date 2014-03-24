//
//  ViewController.m
//  FirstBluetooth
//
//  Created by Samuel Howes on 1/24/14.
//  Copyright (c) 2014 Samuel Howes. All rights reserved.
//

#import "ARMBluetoothViewController.h"
#import "ARMBluetoothManager.h"

const NSInteger kTableViewHeaderActivityIndicatorViewTag = 1020;

@interface ARMBluetoothViewController () <ARMBluetoothManagerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    ARMBluetoothManager *bluetoothManager;
    UIActivityIndicatorView *selectedCellActivityIndicatorView;
    UITableViewCell *selectedTableViewCell;
    NSIndexPath *indexPathOfSelectedCell;
    BOOL readyToConnectToBluetooth;
}

@property (retain, nonatomic) IBOutlet UITableView              *devicesTableView;
@property (weak, nonatomic)   IBOutlet UIActivityIndicatorView  *bluetoothActivitySpinner;

@end

@implementation ARMBluetoothViewController

@synthesize bluetoothActivitySpinner;
@synthesize devicesTableView;


#pragma mark - View lifecycle
/****************************************************************************/
/*								View Lifecycle                              */
/****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshControlDidActivate:) forControlEvents:UIControlEventValueChanged];
    [devicesTableView setDataSource:self];
	[devicesTableView reloadData];          //change
    
    bluetoothManager = [ARMBluetoothManager sharedInstance];
	[bluetoothManager setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (![[ARMPlayerInfo sharedInstance] isReadyToConnectToGameTile])
    {
        [[[UIAlertView alloc] initWithTitle:@"Configuration Error"
                                   message:@"You must customize your profile before you can connect to a GameTile"
                                  delegate:nil
                         cancelButtonTitle:@"I will go do that!"
                         otherButtonTitles:nil] show];
        readyToConnectToBluetooth = NO;
    }
    else
    {
        readyToConnectToBluetooth = YES;
        [bluetoothManager startBluetooth];
    }
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[ARMPlayerInfo sharedInstance] gameTileName])
    {
        return @"Your GameTile";
    }
    else if (!readyToConnectToBluetooth)
    {
        return @"Not ready for Bluetooth";
    }
	else if (!bluetoothManager)
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
                
            case kReadyToScanForGameTiles:
                return @"Ready to scan for devices";
                break;
                
            case kCompletedExchangingDataWithGameTile:
            case kConnectedToUnknownPeripheral:
            case kDisconnectingFromGameTile:
            case kDiscoveringGameTileAttributes:
            case kExchangingDataWithGameTile:
            case kReadyToExchangeDataWithGameTile:
            case kConnectingToGameTile:
            case kScanningForGameTiles:

                return @"Game Tiles";
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

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    CGFloat width = CGRectGetWidth(tableView.bounds);
    CGFloat height = 55;
    
    UITableViewHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"headerIndicatorView"];
    if (sectionHeaderView == nil) {
        sectionHeaderView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"headerIndicatorView"];
    }
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 31, width, height)];
    headerLabel.font = [UIFont systemFontOfSize:14];
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    headerLabel.text =  [title uppercaseString];
    NSLog(@"Title: %@", headerLabel.text);
    [headerLabel sizeToFit];
  //  NSLog(@"%f", headerLabel.frame.size.width);
    
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[sectionHeaderView viewWithTag:kTableViewHeaderActivityIndicatorViewTag];
    if (!activityIndicator)
    {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(14+headerLabel.frame.size.width + 8, 30, 21, 21)];
        [activityIndicator setTag:kTableViewHeaderActivityIndicatorViewTag];
        [activityIndicator setHidesWhenStopped:YES];
        [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [sectionHeaderView.contentView addSubview:activityIndicator];
    }
    
   bluetoothActivitySpinner = activityIndicator;
    
    switch ([bluetoothManager state])
    {
        case kScanningForGameTiles:
        case kConnectingToGameTile:
        case kDisconnectingFromGameTile:
        case kExchangingDataWithGameTile:
        case kDiscoveringGameTileAttributes:
            [activityIndicator startAnimating];
            
            break;
        default:
            [activityIndicator stopAnimating];
            break;
    }

    return sectionHeaderView;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if ([[ARMPlayerInfo sharedInstance] gameTileName])
    {
        return @"Pull down to connect to another GameTile";
    }
    else if (!readyToConnectToBluetooth)
    {
        return @"Customize your profile first";
    }
    else
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
            
            case kScanningForGameTiles:
                if ([[bluetoothManager discoveredGameTileNamesArray] count] == 0)
                {
                    return nil;
                }
                else
                {
                    return @"Select a GameTile to connect to";
                }
                break;
                
            case kConnectingToGameTile:
                return @"Attempting to connect...";
                break;
                
            case kExchangingDataWithGameTile:
            case kDiscoveringGameTileAttributes:
                return @"Communicating with tile...";
                break;
            
            case kCompletedExchangingDataWithGameTile:
                return @"Ready to play!";
                
            default:
                return nil;
                break;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
    if ([[ARMPlayerInfo sharedInstance] gameTileName])
    {
        return 1;
    }
    else if (!readyToConnectToBluetooth)
    {
        return 0;
    }
    switch ([bluetoothManager state])
    {
        case kCompletedExchangingDataWithGameTile:
        case kConnectedToUnknownPeripheral:
        case kDisconnectingFromGameTile:
        case kDiscoveringGameTileAttributes:
        case kExchangingDataWithGameTile:
        case kReadyToExchangeDataWithGameTile:
        case kConnectingToGameTile:
        case kScanningForGameTiles:
            if ([[bluetoothManager discoveredGameTileNamesArray] count] == 0)
            {
                return 1;
            }
            else
            {
                return [[bluetoothManager discoveredGameTileNamesArray] count];
            }
            break;

        case kFatalUnauthorized:
        case kFatalUnsupported:
        case kInitializing:
        case kNotInitialized:
        case kReadyToScanForGameTiles:
        case kResettingBecauseOfSystemReset:
        case kWaitingForBluetoothToBeEnabled:
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSAssert(readyToConnectToBluetooth, @"User profile has not been completed");
    static NSString *cellID = @"DeviceList"; // move this to a konstant at the top
    // use bleDelegate connectionState in a switch statemet
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    UILabel *textLabel = cell.textLabel;
    UILabel *detailTextLabel = cell.detailTextLabel;
    
    
    if ([[ARMPlayerInfo sharedInstance] gameTileName])
    {
        [textLabel setText:[[ARMPlayerInfo sharedInstance] gameTileName]];
        [detailTextLabel setText:@"Connected"];
        [cell setUserInteractionEnabled:NO];
        [bluetoothActivitySpinner stopAnimating];
    }
    else if ([[bluetoothManager discoveredGameTileNamesArray] count] == 0)
    {
        [textLabel setText:@"Scanning for GameTiles..."];
        [bluetoothActivitySpinner startAnimating];
        [detailTextLabel setText:nil];
        [cell setUserInteractionEnabled:NO];
    }
    else
    {
        [textLabel setText:(NSString *)[[bluetoothManager discoveredGameTileNamesArray] objectAtIndex:indexPath.row]];
        switch ([bluetoothManager state])
        {
            case kConnectingToGameTile:
            case kDiscoveringGameTileAttributes:
            case kExchangingDataWithGameTile:
                if (indexPath.row == indexPathOfSelectedCell.row)
                {
                    [detailTextLabel setText:nil];
                    [selectedCellActivityIndicatorView startAnimating];
                    [bluetoothActivitySpinner startAnimating];
                    [cell setUserInteractionEnabled:YES];
                    break;
                }
                
            default:
                [detailTextLabel setText:@"Not Connected"];
                [bluetoothActivitySpinner startAnimating];
                [cell setUserInteractionEnabled:YES];
                break;
        }
        
       
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([bluetoothManager state] == kScanningForGameTiles)
    {
        NSError *error =  [bluetoothManager connectToGameTileWithID:indexPath.row];
        if (error)
        {
            if ([error code] == kInvalidGameTileIDErrorCode)
            {
                [[[UIAlertView alloc] initWithTitle:@"How Embarassing..."
                                            message:@"That was an invalid GameTile entry, I'll remove that..."
                                           delegate:nil
                                  cancelButtonTitle:@"I know you'll do better next time..."
                                  otherButtonTitles:nil] show];
            }
            else
            {
                [bluetoothManager recoverFromError:error];
            }
        }
        else
        {
            indexPathOfSelectedCell = indexPath;
            selectedTableViewCell = [tableView cellForRowAtIndexPath:indexPath];
            selectedCellActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            //    selectedCellActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:[[selectedTableViewCell accessoryView] frame]];
       //     [selectedCellActivityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
            [selectedCellActivityIndicatorView setHidesWhenStopped:YES];
            [selectedCellActivityIndicatorView startAnimating];
            [selectedTableViewCell setAccessoryView:selectedCellActivityIndicatorView];
        }
    }
    else if ([bluetoothManager state] == kConnectingToGameTile)
    {
        // do nothing in this case, because we don't want to select multiple game tiles
    }
    [tableView reloadData];
}

- (void)refreshControlDidActivate:(id)sender
{
    NSLog(@"Refreshing");
    if ([[ARMPlayerInfo sharedInstance] gameTileName])
    {
        [[ARMPlayerInfo sharedInstance] setGameTileName:nil];
        // TODO: properly disconnect from the gametile
    }
    [bluetoothActivitySpinner startAnimating];
    NSError *error = [bluetoothManager scanForGameTiles];
    if (error)
    {
        NSLog(@"Error with refresh control: %@", error);
    }
    [(UIRefreshControl *)sender endRefreshing];
}

#pragma mark - LeDiscoveryDelegate
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void)bluetoothManagerDidRefreshWithError:(NSError *)error
{
    if (error)
    {
        if ([[error domain] isEqualToString:[ARMBluetoothManagerErrorDomain copy]])
        {
            NSString *errorString;
            switch ([error code])
            {
                case kBluetoothPoweredOffNotificationErrorCode:
                    // The system will notify the user the first time this error occurs
                    break;
                    
                case kBluetoothPoweredOffWhenResumingNotificationErrorCode:
                    errorString = @"Bluetooth is disabled. Please enable Bluetooth in Settings.\n\nThis app will not function properly with Bluetooth disabled.";
                    break;
                    
                
                case kBluetoothUnauthorizedNotificationErrorCode:
                    errorString = @"This app needs Bluetooth permissions to function properly. Please grant permissions in Settings";
                    break;
                
                case kBluetoothUnsupportedNotificationErrorCode:
                    errorString = @"This device does not support Bluetooth Low Energy.\nThis app will not function properly without Bluetooth Low Energy.";
                    break;
                
                case kBluetoothUnknownStateNotificationErrorCode:
                    errorString = @"An unknown internal error has occured.";
                    break;
                
                case kBluetoothResettingNotificationErrorCode:
                    errorString = @"Please be patient while Bluetooth restarts.";
                    break;
                    
                case kConnectedPeripheralIsNotAGameTileNotificationErrorCode:
                    errorString = @"Oops. This isn't the GameTile you're looking for.";
                    break;
                    
                case kReconnectionLimitExceededNotificationErrorCode:
                case kDataAttemptLimitExceededNotificationErrorCode:
                    errorString = @"An error occured communicating with this GameTile Check that it is functioning and try again.";
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
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"BluetoothError: %@", [error localizedFailureReason]]
                                        message:[error localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            [bluetoothManager recoverFromError:error];
        }
    }
    else
    {
        switch ((BluetoothManagerState)[bluetoothManager state]) {
            case kNotInitialized:
                // TODO: NOt sure what I should do when initializing
                [bluetoothManager startBluetooth];
                break;
                
            case kReadyToScanForGameTiles:
            {
                if (![[ARMPlayerInfo sharedInstance] gameTileName])
                {
                    error = [bluetoothManager scanForGameTiles];
                    if (error)
                    {
                        // Try to recover...
                        NSLog(@"Received error trying to scan for game tiles");
                        [bluetoothManager recoverFromError:error];
                    }
                }
            }
                break;
            
            case kReadyToExchangeDataWithGameTile:
                error = [bluetoothManager exchangeDataWithConnectedGameTile];
                if (error)
                {
                    NSLog(@"Received error calling exchangeDataWithConnectedGameTile, attempting to recover");
                    [bluetoothManager recoverFromError:error];
                    
                }
                // Also, we will reload the table data below
                break;
                
            // SUCCESS!
            case kCompletedExchangingDataWithGameTile:
                [selectedCellActivityIndicatorView stopAnimating];
                selectedCellActivityIndicatorView = nil;
                [[ARMPlayerInfo sharedInstance] setGameTileName:[bluetoothManager getNameOfConnectedGameTile]];
                
                [selectedTableViewCell setAccessoryView:nil];
                [[[UIAlertView alloc] initWithTitle:@"GameTile Ready"
                                            message:@"You are successfully connected.\nYou may proceed to Settings Step 3."
                                           delegate:nil
                                  cancelButtonTitle:@"Awesome!"
                                  otherButtonTitles:nil] show];
                
                [bluetoothManager disconnectFromGameTile];
                break;
                
            case kConnectedToUnknownPeripheral:
                [bluetoothManager recoverFromError:nil];
                break;
                
                // For the below states, only a reload of the table view is needed
            case kScanningForGameTiles:
            case kConnectingToGameTile:
            case kDisconnectingFromGameTile:
            case kDiscoveringGameTileAttributes:
            case kExchangingDataWithGameTile:
            case kFatalUnauthorized:
            case kFatalUnsupported:
            case kInitializing:
            case kResettingBecauseOfSystemReset:
            case kWaitingForBluetoothToBeEnabled:
            default:
                break;
        }
    }
    
	[devicesTableView reloadData];
}


@end

