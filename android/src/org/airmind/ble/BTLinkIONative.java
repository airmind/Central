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

public class BTLinkIONative {

    /**
     * Called when data comes from connected BLE-device
     * @param deviceAddress BLE device-UUID
     * @param serviceUUID   BLE service-UUID
     * @param characteristicUUID BLE characeristic-UUID
     * @param dataA data received from BLE-device
     */
    public static native void dataArrived(String deviceAddress, String serviceUUID, String characteristicUUID, byte[] dataA);
}
