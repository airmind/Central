/**
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * @author caprin
 * @author MINGPO GU
 * Created: Sep 7, 2016
 */
package org.airmind.ble;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.os.Build;
import java.util.UUID;
import android.util.Log;
import android.bluetooth.BluetoothGattService;

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

    /**
     *  To write data to specified BLE device/service/characteristic-UUID.
     * @param deviceAddress BLE device-UUID
     * @param serviceUUID   BLE service-UUID
     * @param characteristicUUID BLE chracteristic-UUID
     * @param data data to be write to connected BLE device
     */
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
 }

