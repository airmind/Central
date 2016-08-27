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
    public static native void connected(String device, String service, String characteristic);
}
