package org.airmind.ble;

/*
 * Copyright (C) 2013 The Android Open Source Project
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
 */


import java.util.HashMap;

/**
 * This class includes a small subset of standard GATT attributes for demonstration purposes.
 */
public class SampleGattAttributes {
    private static HashMap<String, String> attributes = new HashMap();
    public static String HEART_RATE_MEASUREMENT = "00002a37-0000-1000-8000-00805f9b34fb";
    public static String BODY_SENSOR_LOCATION = "00002a38-0000-1000-8000-00805f9b34fb"; //by myself
    public static String HEART_RATE_CONTROL_POINT = "00002a39-0000-1000-8000-00805f9b34fb"; //by myself
    //    public static String BATTERY_LEVEL = "00002A19-0000-1000-8000-00805f9b34fb"; //by myself
    public static String CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb";
    public static String MAV_TRANSFER_SERVICE_UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961";
    public static String MAV_TRANSFER_CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4";
    static {
        // Sample Services.
        attributes.put("0000180d-0000-1000-8000-00805f9b34fb".toUpperCase(), "Heart Rate Service");
//        attributes.put("0000180a-0000-1000-8000-00805f9b34fb".toUpperCase(), "Device Information Service");
        attributes.put("0000180f-0000-1000-8000-00805f9b34fb".toUpperCase(), "Battery Service");// by myself
        attributes.put("E20A39F4-73F5-4BC4-A12F-17D1AD07A961".toUpperCase(), "Transfer Service"); // by myself
        // Sample Characteristics.
        attributes.put(HEART_RATE_MEASUREMENT.toUpperCase(), "Heart Rate Measurement");
        attributes.put(BODY_SENSOR_LOCATION.toUpperCase(), "Body Sensor Location");  //by myself
        attributes.put(HEART_RATE_CONTROL_POINT.toUpperCase(), "Heart Rate Control");  //by myself
        attributes.put("00002A19-0000-1000-8000-00805f9b34fb".toUpperCase(), "Battery Level");  //by myself
        attributes.put("08590F7E-DB05-467E-8757-72F6FAEB13D4".toUpperCase(), "Transfer Characteristic"); // by myself
        attributes.put("00002a29-0000-1000-8000-00805f9b34fb".toUpperCase(), "Manufacturer Name String");
        attributes.put(MAV_TRANSFER_SERVICE_UUID.toUpperCase(),"BLE-Write-Service");
        attributes.put(MAV_TRANSFER_CHARACTERISTIC_UUID.toUpperCase(),"BLE-Write-Characteristic");
    }

    public static String lookup(String uuid, String defaultName) {
        String name = attributes.get(uuid.toUpperCase());
        return name == null ? defaultName : name;
    }
}
