package org.airmind.ble;
/**
*
* Called from Qt-C++
*/
public class BLEComm {
    /**
    * called when app starts up and auto-connect BLE device/service/characteristic which has ever been connnected before
    */
    public static void connect(String deviceAddress, String serviceUUID, String characteristicUUID) {
        System.out.println("auto connect to device-address:" + deviceAddress + ", service-UUID:" + serviceUUID + ", characteristic-UUID:" + characteristicUUID);
    }

    public static void write(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] data) {
        System.out.println("write to deviceAddress:" + deviceAddress + ", service-UUID:" + serviceUUID + ", characteristic-uuid:" + characteristicUUID +
        ", with value:" + (data != null ? new String(data):"null"));
    }
}
