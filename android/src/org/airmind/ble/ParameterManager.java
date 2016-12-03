package org.airmind.ble;
import android.util.Log;

import org.airmind.controller.IParametersController;

public class ParameterManager{


    private static IParametersController controller;

    private static final String TAG = "ParameterManager";
    /**
    * refresh all parameters
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

    public static void parameterListProgress(float progress) {
        Log.d(TAG,"[parameterListProgress] progress:" + progress);
        if(controller != null){
            controller.onParametersProgressChanged(progress);
        }else{
            throw new NullPointerException("ParametersController is NULL in ParameterManager.");
        }
    }

    //see MAV_PARAM_TYPE at https://pixhawk.ethz.ch/mavlink/
    public static void parameterUpdate(int vehicleId, int componentId, int mavType, String parameterName, float parameterValue, int parameterIndex, int parameterCount) {
        Log.d(TAG,"[parameterUpdate] [vehicleId:" + vehicleId + ", componentId:" + componentId + "] [parameterCount:" + parameterCount + ", parameterIndex" + parameterIndex + "] " + parameterName + "=" + parameterValue + " [type:" + mavType + "]");
        if(controller != null){
            controller.onParametersUpdated(vehicleId, componentId, mavType, parameterName, parameterValue, parameterIndex, parameterCount);
        }else{
            throw new NullPointerException("ParametersController is NULL in ParameterManager.");
        }
    }
}

