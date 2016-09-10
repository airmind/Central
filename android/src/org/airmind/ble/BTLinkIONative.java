package org.airmind.ble;

/**
 * Created by caprin on 16-9-7.
 */
public class BTLinkIONative {
    public static native void write(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] data);

    public static native void read(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] data);
}
