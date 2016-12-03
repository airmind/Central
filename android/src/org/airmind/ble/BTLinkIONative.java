package org.airmind.ble;

/**
 * Created by caprin on 16-9-7.
 */
public class BTLinkIONative {
    //After got the data from peer-BLE, notify qt-c++ side of the data-arrival
    public static native void dataArrived(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] dataA);
}
