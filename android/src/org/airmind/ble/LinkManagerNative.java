package org.airmind.ble;

/**
 * Created by caprin on 16-8-20.
 */
public class LinkManagerNative {
    //notify to discovery BLE device
    public static native void discover();
    //notify the discovery result
    public static native void didDiscover();
    public static native void stopScanning();
    //notify qt-linkmanager to connect the specified device
    public static native void connect(String device, String service, String characteristic); // -> BTSerialLink

    //notify qt that the device has been connected
    public static native void connected(String device, String service, String characteristic);

    //After got the data from peer-BLE, notify qt-c++ side of the data-arrival
    public static native void dataArrived(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] dataA);
}
