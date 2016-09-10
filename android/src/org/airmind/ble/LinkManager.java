package org.airmind.ble;

import android.bluetooth.BluetoothAdapter;

import java.util.UUID;

/**
 * Called from Qt-C++
 */
public class LinkManager {
    /**
     * called when app starts up and auto-connect BLE device/service/characteristic which has
     * ever been connnected before
     */
    static BluetoothAdapter mAdapter;
    static BluetoothLeService mBluetoothLeService;
    public static void connect(String deviceAddress, String serviceUUID, String characteristicUUID) {
        UUID service = UUID.fromString(serviceUUID);
        UUID characteristic = UUID.fromString(characteristicUUID);
        mBluetoothLeService.connect(deviceAddress);
        System.out.println("auto connect to device-address:" + deviceAddress + ", service-UUID:"
                + serviceUUID + ", characteristic-UUID:" + characteristicUUID);
    }
}
