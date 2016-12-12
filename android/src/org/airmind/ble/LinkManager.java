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
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.os.Build;

import java.util.UUID;
import android.util.Log;

public class LinkManager {
    private static BluetoothAdapter bluetoothadapter = null;
    private static BluetoothManager bluetoothManager = null;
    private static BluetoothLeService bluetoothLeService = null;
    private static final String TAG = "LinkManager";
    public static void setAdapter(BluetoothAdapter adapter) {
        LinkManager.bluetoothadapter = adapter;
    }

    /**
     * called when app starts up and auto-connect BLE device/service/characteristic which has
     * ever been connnected before.
    */

    public static void setBluetoothManager(BluetoothManager bluetoothManager) {
        LinkManager.bluetoothManager = bluetoothManager;
    }

    public static void setBluetoothLeService(BluetoothLeService bluetoothLeService) {
        LinkManager.bluetoothLeService = bluetoothLeService;
    }

    /**
     * Called from QT to connect to specified BLE-device.
     * @param deviceAddress BLE device-UUID
     * @param serviceUUID   BLE service-UUID
     * @param characteristicUUID BLE charateristic-UUID
     */
    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    public static void connect(String deviceAddress, String serviceUUID, String characteristicUUID) {
        UUID service = UUID.fromString(serviceUUID);
        UUID characteristic = UUID.fromString(characteristicUUID);
        Log.d(TAG,"auto connect to device-address:" + deviceAddress + ", service-UUID:" + serviceUUID + ", characteristic-UUID:" + characteristicUUID);
        if (bluetoothLeService != null){
            bluetoothLeService.connect(deviceAddress);
        }
    }

    /**
     *Called from QT to discover BLE devices.
     */
    public static void discover() {
        Log.d(TAG, "discover is called");
    }

    /**
     * Called from QT to stop BLE device scanning.
     */
    public static void stopScanning() {
        Log.d(TAG, "stopScanning is called");
    }

    /**
     * After called {@link LinkManagerNative#tcpConnect(String, int)}, to report the connection is connected if success.
     * @param host
     * @param port
     */
    public static void tcpConnected(String host, int port) {
        Log.d(TAG, "[tcpConnected] host:" + host + ", port:" + port);
        new Thread() {
            public void run() {
                try{
                    Thread.sleep(2000);
                } catch(InterruptedException v){
                    System.out.println(v);
                }

                ParameterManager.refreshAllParameters1();
            }
        }.start();
    }
}
