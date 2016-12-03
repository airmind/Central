package org.airmind.ble;

/**
 * Created by caprin on 16-8-20.
 */
public class LinkManagerNative {
    //notify to discovery BLE device
    public static native void discover();

    //notify the discovery result
    public static native void didDiscover(String inRangeFileName, String outRangeFileName);

    public static native void stopScanning();

    //notify qt-linkmanager to connect the specified device
    public static native void connect(String device, String service, String characteristic); // -> BTSerialLink

    /**
    * connect to uav via tcp socket
    */
    public static native void tcpConnect(String host, int port);
}
