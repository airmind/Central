package org.airmind.ble;
<<<<<<< HEAD

import android.content.Intent;

/**
 * Called from Qt-C++
 */
public class BLEComm {
    private static BluetoothLeService mBluetoothService;
    /**
     * called when app starts up and auto-connect BLE device/service/characteristic which has ever been connnected before
     */
    public static void connect(String device, String service, String characteristic) {
        System.out.println("auto connect to device:" + device + ", service:" + service + ", characteristic:" + characteristic);

        connectToDeice(device);

        connectToSevice(service);

        conncetToCharacteristic(characteristic);

    }

    // connect to device
    private static void connectToDeice(String device) {
        mBluetoothService.connect(device);
    }

    // conncet to service
    private static void connectToSevice(String service) {
        //TODO
    }

    // connect to characteristic
    private static void conncetToCharacteristic(String characteristic) {
        //TODO
=======
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
>>>>>>> mindskin-gumingpo
    }
}
