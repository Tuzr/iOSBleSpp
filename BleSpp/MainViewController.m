//
//  MainViewController.m
//  BleSpp
//
//  Created by Jonathan on 2017/1/17.
//
//

#import "MainViewController.h"

#define CSC_SERVICE @"1816"
#define CSC_MEASUREMENT @"2A5B"

@interface BleSppCellData : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSString *text;
@property (nonatomic) NSNumber* rssi;
@end

@implementation BleSppCellData

@end

@implementation MainViewController

-(id)init
{
    self = [super init];
    if(self) {
        _tv = [[UITableView alloc] initWithFrame:CGRectZero];
        _tv.dataSource = self;
        _tv.delegate = self;
        
        _cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        _cellDataArray = [NSMutableArray array];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadData];
}

-(void)reloadData
{
    [_tv reloadData];
}

-(void)loadView
{
    [super loadView];
    
    self.view = _tv;
    self.title = @"BLE SPP";
}

#pragma mark - Custom
-(void)startScan
{
    //Cycling Speed and Cadence
    NSArray *uuidArray= [NSArray arrayWithObjects:[CBUUID UUIDWithString:CSC_SERVICE], nil];
    
    
    [_cm scanForPeripheralsWithServices:uuidArray options:nil];
    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(scanTimeout:) userInfo:nil repeats:NO];
}

-(void)scanTimeout:(NSTimer*)timer
{
    if (_cm !=NULL){
        [_cm stopScan];
    }else{
        NSLog(@"_cm is Null!");
    }
    NSLog(@"scanStop");
}

-(void)connect:(CBPeripheral*)peripheral
{
    if (peripheral.state == CBPeripheralStateDisconnected) {
        [_cm connectPeripheral:peripheral options:nil];
        _connectedPeripheral = peripheral;
    }
}

-(CBService *)getServiceFromUUID:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral {
    
    for (CBService* s in peripheral.services){
        if ([s.UUID isEqual:UUID]) {
            return s;
        }
    }
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *)getCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    
    for (CBCharacteristic* c in service.characteristics){
        if ([c.UUID isEqual:UUID]) {
            return c;
        }
    }
    return nil; //Characteristic not found on this service
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _cellDataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"cell"];
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    BleSppCellData *cellData = [_cellDataArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = cellData.text;
    
    cell.detailTextLabel.text = [cellData.rssi stringValue];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BleSppCellData *cellData = [_cellDataArray objectAtIndex:indexPath.row];

    //[self connect:cellData.peripheral];
    
    Byte byte[] = {0x16,0x08,0x00,0x1E,0x08};
    NSData *txData = [[NSData alloc] initWithBytes:byte length:5];
    
    CBPeripheral *peripheral = cellData.peripheral;
    
    CBService *cscService = [self getServiceFromUUID:[CBUUID UUIDWithString:CSC_SERVICE] peripheral:peripheral];
    
    CBCharacteristic *txCharacteristc = [self getCharacteristicFromUUID:[CBUUID UUIDWithString:CSC_MEASUREMENT] service:cscService];
    
    if(txCharacteristc != nil) {
        [peripheral writeValue:txData forCharacteristic:txCharacteristc type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)centralManager
{
    NSMutableString* nsmstring = [NSMutableString stringWithString:@"UpdateState:"];
    
    BOOL isWork = NO;
    
    switch (centralManager.state) {
        case CBManagerStateUnknown:
            [nsmstring appendString:@"Unknown\n"];
            break;
        case CBManagerStateUnsupported:
            [nsmstring appendString:@"Unsupported\n"];
            break;
        case CBManagerStateUnauthorized:
            [nsmstring appendString:@"Unauthorized\n"];
            break;
        case CBManagerStateResetting:
            [nsmstring appendString:@"Resetting\n"];
            break;
        case CBManagerStatePoweredOff:
            [nsmstring appendString:@"PoweredOff\n"];
            
            /*
            if (connectedPeripheral != nil) {
                [_cm cancelPeripheralConnection:connectedPeripheral];
            }
            */
            break;
        case CBManagerStatePoweredOn:
        {
            [nsmstring appendString:@"PoweredOn\n"];
            isWork = YES;
            [self startScan];
            break;
        }
        default:
            [nsmstring appendString:@"none\n"];
            break;
    }
    NSLog(@"%@",nsmstring);
    //[delegate didUpdateState:isWork message:nsmstring getStatus:cManager.state];
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"\n"];
    [nsmstring appendString:@"Peripheral Info:"];
    [nsmstring appendFormat:@"NAME: %@\n",peripheral.name];
    [nsmstring appendFormat:@"RSSI: %@\n",RSSI];
    
    /*
     if (peripheral.isConnected){
     [nsmstring appendString:@"isConnected: connected"];
     }else{
     [nsmstring appendString:@"isConnected: disconnected"];
     }
     */
    
    //NSLog(@"adverisement:%@",advertisementData);
    [nsmstring appendFormat:@"adverisement:%@",advertisementData];
    [nsmstring appendString:@"didDiscoverPeripheral\n"];
    NSLog(@"%@",nsmstring);
    
    BleSppCellData *cellData = [[BleSppCellData alloc]init];
    cellData.peripheral = peripheral;
    cellData.text = peripheral.name;
    cellData.rssi = RSSI;
    
    [_cellDataArray addObject:cellData];
    [self reloadData];
    
    [self connect:cellData.peripheral];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connect To Peripheral with name: %@\n", peripheral.name);
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil]; //一定要執行"discoverService"功能去尋找可用的Service
}

#pragma mark - CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSLog(@"didDiscoverServices:\n");
  
    if (!error) {
        NSLog(@"====%@====\n",peripheral.name);
        NSLog(@"=========== %d of service ===========\n",peripheral.services.count);
        
        for (CBService *p in peripheral.services){
            NSLog(@"Service found with UUID: %@\n", p.UUID.UUIDString);
            
            if([p.UUID isEqual:[CBUUID UUIDWithString:CSC_SERVICE]]) {
                [peripheral discoverCharacteristics:nil forService:p];
            }
        }
    }
    else {
        NSLog(@"Service discovery was fail %@", error);
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
    
    NSLog(@"=========== Service UUID %@ ===========\n", service.UUID);
    if (!error) {
        NSLog(@"=========== %d Characteristics of service ",service.characteristics.count);
        
        for(CBCharacteristic *characteristic in service.characteristics) {
            NSLog(@"%@ \n",characteristic.UUID);
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CSC_MEASUREMENT]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                NSLog(@"registered notification %@",CSC_MEASUREMENT);
            }
        }
    }else{
        NSLog(@"Characteristic discorvery unsuccessfull !\n");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CSC_MEASUREMENT]]) {
        NSData *rxData = [characteristic value];
        NSUInteger length = rxData.length;
        
        uint8_t *bytes = (uint8_t *)[rxData bytes];
        
        NSMutableString *result = [NSMutableString new];
        
        for(int i=0; i< length; i++) {
            [result appendFormat:@"0x%02X,", bytes[i]];
        }
        
        NSLog(@"Receive Hex: %@", [NSString stringWithString:result]);
    }
}
@end
