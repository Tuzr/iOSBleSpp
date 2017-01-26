//
//  MainViewController.h
//  BleSpp
//
//  Created by Jonathan on 2017/1/17.
//
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MainViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    UITableView *_tv;
    NSMutableArray *_cellDataArray;
    CBCentralManager *_cm;
    
    CBPeripheral *_connectedPeripheral;
}
@end

