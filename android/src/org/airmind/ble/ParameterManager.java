package org.airmind.ble;
import android.util.Log;
public class ParameterManager {
    private static final String TAG = "ParameterManager";
    /**
    * refresh all parameters
    */
    public static native void refreshAllParameters();


    public static void parameterListProgress(float progress) {
        Log.d(TAG,"[parameterListProgress] progress:" + progress);
    }

    //see MAV_PARAM_TYPE at https://pixhawk.ethz.ch/mavlink/
    public static void parameterUpdate(int vehicleId, int componentId, int mavType, String parameterName, float parameterValue, int parameterIndex, int parameterCount) {
        Log.d(TAG,"[parameterUpdate] [vehicleId:" + vehicleId + ", componentId:" + componentId + "] [parameterCount:" + parameterCount + ", parameterIndex" + parameterIndex + "] " + parameterName + "=" + parameterValue + " [type:" + mavType + "]");
    }
}

