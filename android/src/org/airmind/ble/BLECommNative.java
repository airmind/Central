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
    private static Context ctx;
    public static BluetoothAdapter mBluetoothAdapter;
    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    public static void setContxt(Context ctx) {
        BLECommNative.ctx = ctx;
        final BluetoothManager bluetoothManager = (BluetoothManager) ctx.getSystemService(Context.BLUETOOTH_SERVICE);
        mBluetoothAdapter = bluetoothManager.getAdapter();
    }

    private static native void startScan2C();
    public static void startScan() {
        //mBluetoothAdapter.startLeScan(mLeScanCallback);
    }
}
