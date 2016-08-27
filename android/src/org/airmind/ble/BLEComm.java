package org.airmind.ble;
/**
*
* Called from Qt-C++
*/
public class BLECommon {
    /**
    * called when app starts up and auto-connect BLE device/service/characteristic which has ever been connnected before
    */
    public static void connect(String device, String service, String characteristic) {
        System.out.println("auto connect to device:" + device + ", service:" + service + ", characteristic:" + characteristic);
    }
}
