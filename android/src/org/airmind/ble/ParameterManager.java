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
 * Created: Dec 3, 2016
 */

package org.airmind.ble;
import android.util.Log;

import org.airmind.controller.IParametersController;

public class ParameterManager{


    private static IParametersController controller;

    private static final String TAG = "ParameterManager";

    /**
    * refresh/get all parameters from UAV
    */
    private static native void refreshAllParameters();

    public static void refreshAllParameters1(){
        if(controller != null){
            refreshAllParameters();
        }else{
            throw new NullPointerException("ParametersController is NULL in ParameterManager.");
        }
    }

    public static void setController(IParametersController controller) {
        ParameterManager.controller = controller;
    }

    /**
     * Report the progress of refreshing parameters
     * @param progress [0,1]
     */
    public static void parameterListProgress(float progress) {
        Log.d(TAG,"[parameterListProgress] progress:" + progress);
        if(controller != null){
            controller.onParametersProgressChanged(progress);
        }else{
            throw new NullPointerException("ParametersController is NULL in ParameterManager.");
        }
    }

    /**
     * After called refreshAllParameters(), Report paramter values one by one
     * @param vehicleId aircraft's system-id
     * @param componentId see MAV_COMPONENT at {@link http://mavlink.org/messages/common}
     * @param mavType see MAV_PARAM_TYPE at {@link http://mavlink.org/messages/common}
     *        <p>
     *        <ul>
     *                <li>1 MAV_PARAM_TYPE_UINT8</li>
     *                <li>2 MAV_PARAM_TYPE_INT8</li>
     *                <li>3 MAV_PARAM_TYPE_UINT16</li>
     *                <li>4 MAV_PARAM_TYPE_INT16</li>
     *                <li>5 MAV_PARAM_TYPE_UINT32</li>
     *                <li>6 MAV_PARAM_TYPE_INT32</li>
     *                <li>7 MAV_PARAM_TYPE_UINT64</li>
     *                <li>8 MAV_PARAM_TYPE_INT64</li>
     *                <li>9 MAV_PARAM_TYPE_REAL32</li>
     *                <li>10 MAV_PARAM_TYPE_REAL64</li>
     *        </ul>
     * @param parameterName
     * @param parameterValue
     * @param parameterIndex
     * @param parameterCount
     */
    public static void parameterUpdate(int vehicleId, int componentId, int mavType, String parameterName, float parameterValue, int parameterIndex, int parameterCount) {
        Log.d(TAG,"[parameterUpdate] [vehicleId:" + vehicleId + ", componentId:" + componentId + "] [parameterCount:" + parameterCount + ", parameterIndex" + parameterIndex + "] " + parameterName + "=" + parameterValue + " [type:" + mavType + "]");
        if(controller != null){
            controller.onParametersUpdated(vehicleId, componentId, mavType, parameterName, parameterValue, parameterIndex, parameterCount);
        }else{
            throw new NullPointerException("ParametersController is NULL in ParameterManager.");
        }
    }
}

