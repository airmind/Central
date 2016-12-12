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
 *  @author MINGPO GU
  * Created: Aug 20, 2016
  */

package org.airmind.ble;

public class LinkManagerNative {
    /**
     * To discover Bluetooth Lower Energy (BLE) device
    */
    public static native void discover();

    /**
     * To notify discovery result
     * @param inRangeFileName full file name containing devices which meet the RSSI threshold
     * @param outRangeFileName full file name containing devices which does not meet the RSSI threshold
     */
    public static native void didDiscover(String inRangeFileName, String outRangeFileName);

    /**
     * To stop BLE scanning
     */
    public static native void stopScanning();

    /**
     * To connect BLE device specified via device parameter
     * @param device BLE device-UUID
     * @param service BLE service-UUID
     * @param characteristic BLE characteristic-UUID
     */
    public static native void connect(String device, String service, String characteristic);

    /**
     * To tcp-connect specified host/port
     * @param host hostname or ip-address to be tcp-connected
     * @param port port number to be tcp-connected
     */
    public static native void tcpConnect(String host, int port);

    /**
     * On app exit, to close links matained by LinkManager
     */
    public static native void shutdown();
}
