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

static NSString * const kANCSServiceUUIDString = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0";
static NSString * const kANCSNotificationSourceUUIDString = @"9FBF120D-6301-42D9-8C58-25E699A21DBD";
static NSString * const kANCSControlPointUUIDString = @"69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9";
static NSString * const kANCSDataSourceUUIDString = @"22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB";

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

@property (nonatomic, strong) ANCSTransaction *currentTransaction;
@property (nonatomic, strong) dispatch_semaphore_t transactionSemaphore;
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
		
		_transactionSemaphore = dispatch_semaphore_create(0);
		_transactionQueue = dispatch_queue_create("com.jamiepinkham.ancs_transaction_queue", NULL);
		

		
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
	ANCSNotification *localNote = [self.notifications objectForKey:@([notification eventId])];
	if(localNote)
	{
		ANCSTransaction *transaction = [[ANCSNotificationDetailTransaction alloc] initWithNotification:localNote detailsMask:mask];
		CBPeripheral *peripheral = self.ncsToPeripheral[notificationCenter];
		[self executeTransaction:transaction onPeripheral:peripheral completionBlock:^{
			ANCSNotificationDetails *details = [self.currentTransaction result];
			self.currentTransaction = nil;
			dispatch_async(self.callbackQueue, ^{
				[self.delegate controller:self didUpdateNotificationDetails:details notificationCenter:notificationCenter];
				
			});
		}];
		
	}
}

- (void)getApplicationNameForIdentifier:(NSString *)identifier onNotificationCenter:(ANCSNotificationCenter *)notificationCenter
{
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
		/*
		 ANCSAppNameTransaction *transaction = [[ANCSAppNameTransaction alloc] initWithAppIdentifier:identifier];
		CBPeripheral *peripheral = self.ncsToPeripheral[notificationCenter];
		[self executeTransaction:transaction onPeripheral:peripheral completionBlock:^{
			NSString *appName = [transaction result];
			self.appIdentifiers[identifier] = appName;
			dispatch_async(self.callbackQueue, ^{
				[self.delegate controller:self didRetrieveAppDisplayName:appName forIdentifier:identifier];
			});
		}];
		 */
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
	[self.centralManager retrieveConnectedPeripherals];
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
	NSLog(@"peripherals = %@", peripherals);
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

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	for(CBService *service in peripheral.services)
	{
		if([service.UUID isEqual:self.serviceUUID])
		{
			[peripheral discoverCharacteristics:@[self.notificationSourceUUID, self.controlPointUUID, self.dataSourceUUID] forService:service];
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	if([service.UUID isEqual:self.serviceUUID])
	{
		for(CBCharacteristic *aChar in service.characteristics)
		{
			if([aChar.UUID isEqual:self.notificationSourceUUID])
			{
				self.notificationSourceCharacterstic = aChar;
				[peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			else if ([aChar.UUID isEqual:self.controlPointUUID])
			{
				self.controlPointCharacteristic = aChar;
			}
			else if([aChar.UUID isEqual:self.dataSourceUUID])
			{
				self.dataSourceCharacteristic = aChar;
				[peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if([characteristic.UUID isEqual:self.notificationSourceUUID])
	{
		NSLog(@"notification source characteristic is notifying = %@", characteristic.isNotifying ? @"YES" : @"NO");
	}
	if([characteristic.UUID isEqual:self.dataSourceUUID])
	{
		NSLog(@"data source characteristic is notifying = %@", characteristic.isNotifying ? @"YES" : @"NO");
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if([characteristic.UUID isEqual:self.notificationSourceUUID])
	{
		ANCSNotification *notification = [[ANCSNotification alloc] initWithData:characteristic.value];
		
		if(![self.notifications objectForKey:@([notification eventId])] && (notification.notificationType != ANCSEventNotificationTypeRemoved))
		{
			[self.notifications setObject:notification forKey:@(notification.eventId)];
		}
		else if([self.notifications objectForKey:@([notification eventId])] && (notification.notificationType == ANCSEventNotificationTypeRemoved))
		{
			[self.notifications removeObjectForKey:@([notification eventId])];
		}
		dispatch_async(self.callbackQueue, ^{
			ANCSNotificationCenter *center = self.peripheralsToNcs[CFBridgingRelease(CFUUIDCreateString(NULL, peripheral.UUID))];
			[self.delegate controller:self receivedNotification:notification notificationCenter:center];
		});
	}
	if([characteristic.UUID isEqual:self.dataSourceUUID])
	{
		[self.currentTransaction appendData:characteristic.value];
		NSLog(@"appended data = %@", characteristic.value);
		if([self.currentTransaction isComplete])
		{
			dispatch_semaphore_signal(self.transactionSemaphore);
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	NSLog(@"wrote to characteristic = %@, error = %@", characteristic, error);
}

- (void)executeTransaction:(ANCSTransaction *)transaction onPeripheral:(CBPeripheral *)peripheral completionBlock:(void(^)(void))completionBlock
{
	dispatch_async(self.transactionQueue, ^{
		self.currentTransaction = transaction;
		NSData *packet = [transaction buildCommandData];
		[peripheral writeValue:packet forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
		dispatch_semaphore_wait(self.transactionSemaphore, DISPATCH_TIME_FOREVER);
		completionBlock();
	});
}


@end
