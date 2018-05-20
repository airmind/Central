//
//  BLE_definitions.h
//  MindSkin
//
//  Created by ning roland on 12/18/17.
//
//

#ifndef BLE_definitions_h
#define BLE_definitions_h

#define DRONETAG_TRIG_RANGE -35   //in dB of RSSI;
#define DRONETAG_DISCONNECT_WARNING_RANGE -50
#define DRONETAG_DISCONNECT_RANGE -65


typedef enum  {
    BLE_LINK_NOT_CONNECTED,
    BLE_LINK_HARDWARE_CONNECTED,
    BLE_LINK_ENDPOINT_CONNECTED   //fully connected to service and characteristic;
    
}BLE_LINK_STATUS;


typedef enum  {
    BLE_LINK_QUALITY_INRANGE,
    BLE_LINK_QUALITY_ALERT,
    BLE_LINK_QUALITY_OUTOFRANGE   //fully connected to service and characteristic;
    
}BLE_LINK_QUALITY;


// To which stage should the connection goes
typedef enum {
    BLE_LINK_CONNECT_PERIPHERAL,
    BLE_LINK_CONNECT_SERVICE,
    BLE_LINK_CONNECT_CHARACTERISTIC
    
}BLE_LINK_CONNECT_STAGE ;

#ifdef __ios__
#define MAV_TRANSFER_SERVICE_UUID           @"6A400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define MAV_TRANSFER_CHARACTERISTIC_UUID    @"6A400002-B5A3-F393-E0A9-E50E24DCCA9E"
#endif

#ifdef __android__
#define MAV_TRANSFER_SERVICE_UUID           "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define MAV_TRANSFER_CHARACTERISTIC_UUID    "08590F7E-DB05-467E-8757-72F6FAEB13D4"
#endif

#define LP_RSSI_WINDOW_LENGTH 10

typedef enum {
    BLE_Peripheral_HARDWARE_NOTCONNECTED,
    BLE_Peripheral_HARDWARE_CONNECTING,
    BLE_Peripheral_HARDWARE_CONNECTED
    
}BLE_Peripheral_HARDWARECONNECT_STATUS;


#endif /* BLE_definitions_h */
