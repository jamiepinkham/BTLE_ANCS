//
//  ANCSViewController.m
//  ANCS iOS
//
//  Created by Jamie Pinkham on 9/23/13.
//  Copyright (c) 2013 Jamie Pinkham. All rights reserved.
//

#import "ANCSViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define DUMMY_SERVICE_UUID_STRING @"C00ED14C-1166-415E-9075-51989B9A6EC6"

@interface ANCSViewController () <CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@end

@implementation ANCSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startBroadcasting:(id)sender
{
	self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:NULL];
}

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
	// Opt out from any other state
	if(peripheral.state == CBPeripheralManagerStateUnsupported || peripheral.state == CBPeripheralManagerStateUnauthorized)
	{
		return;
	}
	
	if(peripheral.state == CBPeripheralManagerStateResetting)
	{
		NSLog(@"resetting");
	}
	
	if (peripheral.state != CBPeripheralManagerStatePoweredOn)
	{
        return;
    }
    
	CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:DUMMY_SERVICE_UUID_STRING] primary:YES];
	[self.peripheralManager addService:service];
	[self.peripheralManager startAdvertising:nil];
}

@end
