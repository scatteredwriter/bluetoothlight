//
//  ViewController.m
//  BluetoothLight
//
//  Created by rod on 12/28/18.
//  Copyright © 2018 RodChong. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>


@property (nonatomic, strong) UILabel *currentIndex;
@property (nonatomic, strong) UIButton *upButton;
@property (nonatomic, strong) UIButton *downButton;

@property (nonatomic, strong) CBCentralManager *bluetoothManager;
@property (nonatomic, strong) CBPeripheral *bluetoothPeripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;

@end

@implementation ViewController {
    NSString *_name;
    NSString *_service_uuid;
    NSString *_char_uuid;
    int _index;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.bluetoothManager = nil;
    self.bluetoothPeripheral = nil;
    self.characteristic = nil;
    _name = @"BT05";
    _service_uuid = @"FFE0";
    _char_uuid = @"FFE1";
    _index = 10;
    [self p_initCurrentIndex];
    [self p_initUpButton];
    [self p_initDownButton];
    [self p_initBluetooth];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)p_initCurrentIndex {
    self.currentIndex = [[UILabel alloc] init];
    self.currentIndex.text = @"010";
    self.currentIndex.font = [UIFont systemFontOfSize:200];
    self.currentIndex.textColor = [UIColor blueColor];
    self.currentIndex.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.currentIndex];
}

- (void)p_initUpButton {
    self.upButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.upButton setTitle:@"增加亮度" forState:UIControlStateNormal];
    [self.upButton setTitle:@"增加亮度" forState:UIControlStateHighlighted];
    self.upButton.titleLabel.font = [UIFont systemFontOfSize:25];
    [self.upButton addTarget:self action:@selector(p_up) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.upButton];
}

- (void)p_initDownButton {
    self.downButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downButton setTitle:@"减少亮度" forState:UIControlStateNormal];
    [self.downButton setTitle:@"减少亮度" forState:UIControlStateHighlighted];
    self.downButton.titleLabel.font = [UIFont systemFontOfSize:25];
    [self.downButton addTarget:self action:@selector(p_down) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.downButton];
}

- (void)p_initBluetooth {
    self.bluetoothManager = [[CBCentralManager alloc] init];
    self.bluetoothManager.delegate = self;
}

- (void)p_up {
    if(_index == 100) {
        return;
    }
    _index += 10;
    char buf[4];
    buf[0] = '0' + _index / 100;
    buf[1] = '0' + _index % 100 / 10;
    buf[2] = '0' + _index % 10;
    buf[3] = '\0';
    NSLog(@"即将发送的指令为: %s",buf);
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:buf length:3] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
    [self p_showIndex:buf];
}

- (void)p_down {
    if(_index == 0) {
        return;
    }
    _index -= 10;
    char buf[4];
    buf[0] = '0' + _index / 100;
    buf[1] = '0' + _index % 100 / 10;
    buf[2] = '0' + _index % 10;
    buf[3] = '\0';
    NSLog(@"即将发送的指令为: %s",buf);
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:buf length:3] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
    [self p_showIndex:buf];
}

- (void)p_showIndex:(const char *)index {
    self.currentIndex.text = [NSString stringWithUTF8String:index];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGSize currentIndexSize = CGSizeMake(600, 200);
    CGSize upButtonSize = CGSizeMake(150, 50);
    CGSize downButtonSize = CGSizeMake(150, 50);
    
    self.currentIndex.frame = CGRectMake((CGRectGetWidth(self.view.frame) - currentIndexSize.width) / 2, 50, currentIndexSize.width, currentIndexSize.height);
    self.upButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - upButtonSize.width) / 2, (CGRectGetMaxY(self.currentIndex.frame) + 100), upButtonSize.width, upButtonSize.height);
    self.downButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - downButtonSize.width) / 2, CGRectGetMaxY(self.upButton.frame) + 100, downButtonSize.width, downButtonSize.height);
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch(central.state) {
        case CBManagerStatePoweredOn://蓝牙开启状态
        {
            NSLog(@"蓝牙开启，开始扫描设备");
            [self.bluetoothManager scanForPeripheralsWithServices:nil options:nil];
        };
        break;
        default:
        break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Name:%@",peripheral.name);
    if([peripheral.name isEqualToString:_name]) {
        peripheral.delegate=self;
        [self.bluetoothManager connectPeripheral:peripheral options:nil];
        self.bluetoothPeripheral = peripheral;
        [self.bluetoothManager stopScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"蓝牙断开连接");
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"%s, line = %d, %@=连接失败",__FUNCTION__, __LINE__, peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"丢失连接");
}


#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    NSLog(@"开始发现服务...");
    NSArray *services = peripheral.services;
    for(CBService *service in services) {
        NSLog(@"service uuid: %@",service.UUID.UUIDString);
        if([service.UUID.UUIDString isEqualToString:_service_uuid]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    NSArray *characteristics = service.characteristics;
    for(CBCharacteristic* characteristic in characteristics) {
        NSLog(@"char uuid: %@",characteristic.UUID.UUIDString);
        if([characteristic.UUID.UUIDString isEqualToString:_char_uuid]) {
            self.characteristic = characteristic;
        }
    }
}
@end
