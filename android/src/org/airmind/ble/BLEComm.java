package org.airmind.ble;

import android.content.Intent;

/**
 * Called from Qt-C++
 */
public class BLEComm {
    /**
     * called when app starts up and auto-connect BLE device/service/characteristic which has ever been connnected before
     */
    public static void connect(String device, String service, String characteristic) {
        System.out.println("auto connect to device:" + device + ", service:" + service + ", characteristic:" + characteristic);

        // connect to device
        connectToDeice(device);

        connectSevice(service);

        conncetToCharacteristic(characteristic);

    }

    // connect to device
    private static void connectToDeice(String device) {

    }

    // conncet to service
    private static void connectSevice(String service) {

    }

    // connect to characteristic
    private static void conncetToCharacteristic(String characteristic) {
        
    }
}
