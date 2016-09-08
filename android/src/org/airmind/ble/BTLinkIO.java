package org.airmind.ble;

/**
 * Created by caprin on 16-9-7.
 */
public class BTLinkIO {
    public static void write(String deviceAddress, String serviceUUID, String characteristicUUID,
                             byte[] data) {
        System.out.println("write to deviceAddress:" + deviceAddress + ", service-UUID:" +
                serviceUUID + ", characteristic-uuid:" + characteristicUUID +
                ", with value:" + (data != null ? new String(data) : "null"));
    }

    public static void read(String deviceAddress, String serviceUUID, String characteristicUUID,
                            byte[] data) {
        System.out.println("read from deviceAddress:" + deviceAddress + ", service-UUID:" +
                serviceUUID + ", characteristic-uuid:" + characteristicUUID +
                ", with value:" + (data != null ? new String(data) : "null"));
    }


}
