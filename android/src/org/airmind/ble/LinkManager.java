package org.airmind.ble;

/**
 * Called from Qt-C++
 */
public class LinkManager {
    /**
     * called when app starts up and auto-connect BLE device/service/characteristic which has
     * ever been connnected before
     */
    public static void connect(String deviceAddress, String serviceUUID, String
            characteristicUUID) {
        System.out.println("auto connect to device-address:" + deviceAddress + ", service-UUID:"
                + serviceUUID + ", characteristic-UUID:" + characteristicUUID);
    }

    public static void conneted(String deviceAddress, String serviceUUID, String
            characteristicUUID) {
        System.out.println("connected to device-adress" + deviceAddress + ", service-UUID:" +
                serviceUUID + ", characteristic-UUID: " + characteristicUUID);
    }

}
