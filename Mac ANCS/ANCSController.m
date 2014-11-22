//
//  JPANCSController.m
//  Mac ANCS
//
//  Created by Jamie Pinkham on 9/20/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSController.h"
#import "ANCSNotificationCenter.h"
#import "ANCSNotification.h"
#import "ANCSNotificationDetails.h"
#import "ANCSNotificationDetailTransaction.h"
#import "ANCSAppNameTransaction.h"

static NSString * const kANCSServiceUUIDString = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0"; // ANCS服务
static NSString * const kANCSNotificationSourceUUIDString = @"9FBF120D-6301-42D9-8C58-25E699A21DBD"; // 通知源
static NSString * const kANCSControlPointUUIDString = @"69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9"; // 控制入口
static NSString * const kANCSDataSourceUUIDString = @"22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB"; // 数据源

@interface ANCSController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) dispatch_queue_t bluetoothQueue;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *notificationSourceUUID;
@property (nonatomic, strong) CBUUID *controlPointUUID;
@property (nonatomic, strong) CBUUID *dataSourceUUID;
@property (nonatomic, strong) NSMutableDictionary *ncsToPeripheral;
@property (nonatomic, strong) NSMutableDictionary *peripheralsToNcs;

@property (nonatomic, strong) CBCharacteristic *notificationSourceCharacterstic;
@property (nonatomic, strong) CBCharacteristic *controlPointCharacteristic;
@property (nonatomic, strong) CBCharacteristic *dataSourceCharacteristic;

@property (nonatomic, strong) NSMutableDictionary *notifications;

@property (nonatomic, strong) NSMutableDictionary *appIdentifiers;

@property (nonatomic, strong) NSMutableArray* txns;
@property (nonatomic, strong) dispatch_queue_t transactionQueue;

@end

@implementation ANCSController

- (instancetype)initWithDelegate:(id<ANCSControllerDelegate>)delegate queue:(dispatch_queue_t)queue
{
	self = [super init];
	if (self)
	{
		if(queue == NULL)
		{
			queue = dispatch_get_main_queue();
		}
		_delegate = delegate;
		_callbackQueue = queue;
		_serviceUUID = [CBUUID UUIDWithString:kANCSServiceUUIDString];
		_notificationSourceUUID = [CBUUID UUIDWithString:kANCSNotificationSourceUUIDString];
		_controlPointUUID = [CBUUID UUIDWithString:kANCSControlPointUUIDString];
		_dataSourceUUID = [CBUUID UUIDWithString:kANCSDataSourceUUIDString];
		_ncsToPeripheral = [NSMutableDictionary new];
		_peripheralsToNcs = [NSMutableDictionary new];
		_notifications = [NSMutableDictionary new];
        _txns = [NSMutableArray new];
		
		_transactionQueue = dispatch_queue_create("com.jamiepinkham.ancs_transaction_queue", DISPATCH_QUEUE_SERIAL);
		
	}
	return self;
}

- (void)scanForNotificationCenters
{
	self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.bluetoothQueue];
}

- (void)stopScanning
{
	_scanning = NO;
	[self.centralManager stopScan];
}


- (void)connectToNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
	CBPeripheral *peripheral = [self.ncsToPeripheral objectForKey:notificationCenter];
	[self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)getAttributesForNotification:(ANCSNotification *)notification detailsMask:(ANCSNotificationDetailsTypeMask)mask notificationCenter:(ANCSNotificationCenter *)notificationCenter
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	ANCSNotification *localNote = [self.notifications objectForKey:@([notification notificationUid])];
	if(localNote)
	{
		ANCSTransaction *transaction = [[ANCSNotificationDetailTransaction alloc] initWithNotification:localNote detailsMask:mask];
		transaction.completionBlock = ^(id result, NSError *error){
			if(result)
			{
				dispatch_async(self.callbackQueue, ^{
					[self.delegate controller:self didUpdateNotificationDetails:result notificationCenter:notificationCenter];
					
				});
			}
			else
			{
				NSLog(@"retrive notification error = %@", error);
			}
		};
		[self executeTransaction:transaction onNotificationCenter:notificationCenter];
		
	}
}

- (void)getApplicationNameForIdentifier:(NSString *)identifier onNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	if(identifier == nil)
	{
		return;
	}
	if ([self.appIdentifiers objectForKey:identifier])
	{
		dispatch_async(self.callbackQueue, ^{
			NSString *displayName = [self.appIdentifiers objectForKey:identifier];
			[self.delegate controller:self didRetrieveAppDisplayName:displayName forIdentifier:identifier];
		});
	}
	else
	{
		//currently broken, see: https://devforums.apple.com/message/876984#876984
		 ANCSAppNameTransaction *transaction = [[ANCSAppNameTransaction alloc] initWithAppIdentifier:identifier];
		transaction.completionBlock = ^(id result, NSError *error){
			if(result)
			{
                NSLog(@"retrive app name identifier = %@ result = %@", identifier, result);
				self.appIdentifiers[identifier] = result;
				dispatch_async(self.callbackQueue, ^{
					[self.delegate controller:self didRetrieveAppDisplayName:result forIdentifier:identifier];
				});
			}
			else
			{
				NSLog(@"retrive app name identifier = %@ error = %@", identifier, error);
			}
			
		};

		[self executeTransaction:transaction onNotificationCenter:notificationCenter];
	}
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	
	if(central.state == CBCentralManagerStateUnauthorized || central.state == CBCentralManagerStateUnsupported)
	{
//		[self handleFailToScan:nil];
	}
	
	if(central.state != CBCentralManagerStatePoweredOn)
	{
		return;
	}
	
	[self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
	dispatch_async(self.callbackQueue, ^{
		[self.delegate controllerStartedScanningForNotificationCenters:self];
	});
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	NSString *name = [peripheral name];
	ANCSNotificationCenter *center = [[ANCSNotificationCenter alloc] init];
	[center setUUID:peripheral.UUID];
	[center setName:name];
	[self.ncsToPeripheral setObject:peripheral forKey:center];
	[self.peripheralsToNcs setObject:center forKey:CFBridgingRelease(CFUUIDCreateString(NULL, peripheral.UUID))];
	
	dispatch_async(self.callbackQueue, ^{
		[self.delegate controller:self foundNotificationCenter:center];
	});
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	[peripheral setDelegate:self];
	[peripheral discoverServices:@[self.serviceUUID]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	NSInteger idx = [[self.ncsToPeripheral allKeys] indexOfObject:peripheral];
	if(idx != NSNotFound)
	{
		dispatch_async(self.callbackQueue, ^{
			ANCSNotificationCenter *noteCenter = [self.ncsToPeripheral allKeys][idx];
			[self.delegate controller:self disconnectedFromNotificationCenter:noteCenter];
		});
	}
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	NSInteger idx = [[self.ncsToPeripheral allKeys] indexOfObject:peripheral];
	if(idx != NSNotFound)
	{
		dispatch_async(self.callbackQueue, ^{
			ANCSNotificationCenter *noteCenter = [self.ncsToPeripheral allKeys][idx];
			[self.delegate controller:self disconnectedFromNotificationCenter:noteCenter];
		});
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
	for(CBService *service in peripheral.services) {
		if ([self.serviceUUID isEqual:service.UUID]) {
			[peripheral discoverCharacteristics:@[self.notificationSourceUUID, self.controlPointUUID, self.dataSourceUUID] forService:service];
        }
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	if([service.UUID isEqual:self.serviceUUID]) // 确实是ANCS服务
	{
		for(CBCharacteristic *aChar in service.characteristics)
		{
			if ([self.notificationSourceUUID isEqual:aChar.UUID]) // 通知源
			{
                self.notificationSourceCharacterstic = aChar;
            }
            else if ([self.controlPointUUID isEqual:aChar.UUID]) // 操作
            {
				self.controlPointCharacteristic = aChar;
			}
			else if([self.dataSourceUUID isEqual:aChar.UUID]) // 数据源
			{
				self.dataSourceCharacteristic = aChar;
			}
		}
        [peripheral setNotifyValue:YES forCharacteristic:self.dataSourceCharacteristic];
        [peripheral setNotifyValue:YES forCharacteristic:self.notificationSourceCharacterstic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if([characteristic.UUID isEqual:self.notificationSourceUUID])
	{
//		NSLog(@"notification source characteristic is notifying = %@, %@", characteristic.isNotifying ? @"YES" : @"NO", error);
	}
	else if([characteristic.UUID isEqual:self.dataSourceUUID])
	{
//		NSLog(@"data source characteristic is notifying = %@, %@", characteristic.isNotifying ? @"YES" : @"NO", error);
	}
	
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([characteristic.UUID isEqual:self.notificationSourceUUID]) { // 通知源发来的消息
		ANCSNotification *notification = [[ANCSNotification alloc] initWithData:characteristic.value];
		
		if(![self.notifications objectForKey:@([notification notificationUid])] && (notification.notificationType != ANCSEventNotificationTypeRemoved))
		{
			[self.notifications setObject:notification forKey:@(notification.notificationUid)];
		}
		else if([self.notifications objectForKey:@([notification notificationUid])] && (notification.notificationType == ANCSEventNotificationTypeRemoved))
		{
			[self.notifications removeObjectForKey:@([notification notificationUid])];
		}
		dispatch_async(self.callbackQueue, ^{
			ANCSNotificationCenter *center = self.peripheralsToNcs[CFBridgingRelease(CFUUIDCreateString(NULL, peripheral.UUID))];
			[self.delegate controller:self receivedNotification:notification notificationCenter:center];
		});
    } else if([characteristic.UUID isEqual:self.dataSourceUUID]) { // 数据源发来的消息
//        NSLog(@"dataSource.value %lu %@", characteristic.value.length, characteristic.value);
        ANCSTransaction* txn = _txns.firstObject;
//        NSLog(@"txn %@", txn.class);
        if (!txn) return;
		[txn appendData:characteristic.value];
		if([txn isComplete]) {
//            NSLog(@"dataSource.value %lu %@", txn.accumulatedData.length, txn.accumulatedData);
            [_txns removeObjectAtIndex:0];
            dispatch_async(self.callbackQueue, ^{
                txn.completionBlock(txn.result, txn.error);
            });
		}
	}
}


- (void)executeTransaction:(ANCSTransaction *)transaction onNotificationCenter:(ANCSNotificationCenter *)notificationCenter;
{
	dispatch_async(self.transactionQueue, ^{
		CBPeripheral *peripheral = self.ncsToPeripheral[notificationCenter];
        [_txns addObject:transaction];
		NSData *packet = [transaction buildCommandData];
		[peripheral writeValue:packet forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
	});
}


@end
