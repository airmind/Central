package org.airmind.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;

import java.util.UUID;

/**
 * Called from Qt-C++
 */
public class LinkManager {
    private static BluetoothAdapter adapter = null;
    private static BluetoothManager bluetoothManager = null;
    private static BluetoothLeService bluetoothLeService = null;

    public static void setAdapter(BluetoothAdapter adapter) {
        LinkManager.adapter = adapter;
    }

    /**
     * called when app starts up and auto-connect BLE device/service/characteristic which has
     * ever been connnected before
     */

    public static void setBluetoothManager(BluetoothManager bluetoothManager) {
        LinkManager.bluetoothManager = bluetoothManager;
    }

    public static void setBluetoothLeService(BluetoothLeService bluetoothLeService) {
        LinkManager.bluetoothLeService = bluetoothLeService;
    }

    public static void connect(String deviceAddress, String serviceUUID, String characteristicUUID) {
        UUID service = UUID.fromString(serviceUUID);
        UUID characteristic = UUID.fromString(characteristicUUID);
        if (bluetoothLeService != null){
            bluetoothLeService.connect(deviceAddress);
        }
        System.out.println("auto connect to device-address:" + deviceAddress + ", service-UUID:"
                + serviceUUID + ", characteristic-UUID:" + characteristicUUID);
    }
}
