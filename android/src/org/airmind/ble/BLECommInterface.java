package org.airmind.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;

/**
 * Created by caprin on 16-8-23.
 */
public interface BLECommInterface {

    boolean startScan2C(BluetoothAdapter.LeScanCallback callback);

    void stopScan2C(BluetoothAdapter.LeScanCallback callback);

    void connect();

    BluetoothDevice getRemoteDevice(String address);
}
