package org.airmind.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.os.Build;
import java.util.UUID;
import android.util.Log;
import android.bluetooth.BluetoothGattService;
/**
 * Created by caprin on 16-9-7.
 */
 public class BTLinkIO {
     public static String TAG = "BTLinkIO";
     private static BluetoothLeService bluetoothLeService;

    public static void setPeerMavLinkWriteCharacteristic(BluetoothGattCharacteristic peerMavLinkWriteCharacteristic) {
        BTLinkIO.peerMavLinkWriteCharacteristic = peerMavLinkWriteCharacteristic;
    }

    private static BluetoothGattCharacteristic peerMavLinkWriteCharacteristic;

     public static void setBluetoothLeService(BluetoothLeService bluetoothLeService) {
         BTLinkIO.bluetoothLeService = bluetoothLeService;
     }

    private static BluetoothGattCharacteristic findChar(String deviceAddress, String serviceUUID, String characteristicUUID) {
        if(deviceAddress == null || serviceUUID == null || characteristicUUID == null) return null;

        BluetoothGattCharacteristic c = null;
        if(bluetoothLeService != null && peerMavLinkWriteCharacteristic != null) {

            BluetoothGattService service = peerMavLinkWriteCharacteristic.getService();
            if(service != null) {
                String dUUID = bluetoothLeService.getBluetoothDeviceAddress().toLowerCase();
                String sUUID = service.getUuid().toString().toLowerCase();
                String cUUID = peerMavLinkWriteCharacteristic.getUuid().toString().toLowerCase();
                if(dUUID != null && sUUID != null && cUUID != null) {
                    if( dUUID.equals(deviceAddress.toLowerCase()) && sUUID.equals(serviceUUID.toLowerCase()) && cUUID.equals(characteristicUUID.toLowerCase())) {
                       c = peerMavLinkWriteCharacteristic;
                    }
                }
            }

        }
        return c;
    }
     @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
     public static void write(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] data) {
         Log.d(TAG, "write to deviceAddress:" + deviceAddress + ", service-UUID:" +
                 serviceUUID + ", characteristic-uuid:" + characteristicUUID +
                 ", with value:" + (data != null ? new String(data) : "null"));
         BluetoothGattCharacteristic characteristic = findChar(deviceAddress, serviceUUID, characteristicUUID);
         if(bluetoothLeService != null &&  data != null && characteristic != null
                 /* && deviceAddress != null && serviceUUID != null && characteristicUUID != null*/ ) {
             bluetoothLeService.writeCharacteristic(peerMavLinkWriteCharacteristic, data);
         }
     }

     @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
     public static void read(String deviceAddress, String serviceUUID, BluetoothGattCharacteristic characteristicUUID, byte[] data) {
         System.out.println("read from deviceAddress:" + deviceAddress + ", service-UUID:" +
                 serviceUUID + ", characteristic-uuid:" + characteristicUUID.toString() +
                 ", with value:" + (data != null ? new String(data) : "null"));
         UUID service = UUID.fromString(serviceUUID);
         bluetoothLeService.readCharacteristic(characteristicUUID);
         data = characteristicUUID.getValue();
     }
 }

