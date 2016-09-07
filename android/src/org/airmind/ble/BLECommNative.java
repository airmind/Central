package org.airmind.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Build;

/**
 * Created by caprin on 16-8-20.
 */
public class BLECommNative {
    //notify qt-linkmanager to connect the specified device
    public static native void connect(String device, String service, String characteristic);

    //notify qt that the device has been connected
    public static native void connected(String device, String service, String characteristic);

    //After got the data from peer-BLE, notify qt-c++ side of the data-arrival
    public static native void dataArrived(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] dataA);
}
