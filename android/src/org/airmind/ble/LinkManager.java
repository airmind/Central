package org.airmind.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothAdapter.LeScanCallback;
import android.bluetooth.BluetoothClass;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.os.Build;

import java.util.UUID;
import android.util.Log;
/**
 * Called from Qt-C++
 */
public class LinkManager {
    private static BluetoothAdapter bluetoothadapter = null;
    private static BluetoothManager bluetoothManager = null;
    private static BluetoothLeService bluetoothLeService = null;
    private static final String TAG = "LinkManager";
    public static void setAdapter(BluetoothAdapter adapter) {
        LinkManager.bluetoothadapter = adapter;
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

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    public static void connect(String deviceAddress, String serviceUUID, String characteristicUUID) {
        UUID service = UUID.fromString(serviceUUID);
        UUID characteristic = UUID.fromString(characteristicUUID);
        Log.d(TAG,"auto connect to device-address:" + deviceAddress + ", service-UUID:" + serviceUUID + ", characteristic-UUID:" + characteristicUUID);
        if (bluetoothLeService != null){
            bluetoothLeService.connect(deviceAddress);
        }
    }
}
