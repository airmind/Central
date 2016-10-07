package org.airmind.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.os.Build;
import java.util.UUID;

/**
 * Created by caprin on 16-9-7.
 */
 public class BTLinkIO {
     private static BluetoothLeService bluetoothLeService;
     private static BluetoothGatt bluetoothGatt;

     public static void setBluetoothLeService(BluetoothLeService bluetoothLeService) {
         BTLinkIO.bluetoothLeService = bluetoothLeService;
     }

     @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
     public static void write(String deviceAddress, String serviceUUID, BluetoothGattCharacteristic characteristicUUID, byte[] data) {
         System.out.println("write to deviceAddress:" + deviceAddress + ", service-UUID:" +
                 serviceUUID + ", characteristic-uuid:" + characteristicUUID +
                 ", with value:" + (data != null ? new String(data) : "null"));
//         BluetoothGattDescriptor descriptor = characteristicUUID.getDescriptor(
//                 UUID.fromString(SampleGattAttributes.CLIENT_CHARACTERISTIC_CONFIG));
//         descriptor.setValue(data);
//         bluetoothGatt.writeDescriptor(descriptor);
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

