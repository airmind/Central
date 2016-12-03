package org.airmind.controller;

/**
 * Created by KiBa on 2016/11/25.
 */

public interface IParametersController {

    /**
     * This method will be called when refreshing parameters after the connection established.
     * @param progress the current progress
     */
    void onParametersProgressChanged(float progress);

    /**
     * see MAV_PARAM_TYPE at https://pixhawk.ethz.ch/mavlink/
     * @param vehicleId
     * @param componentId
     * @param mavType
     * @param parameterName
     * @param parameterValue
     * @param parameterIndex
     * @param parameterCount
     */
    void onParametersUpdated(
            int vehicleId,
            int componentId,
            int mavType,
            String parameterName,
            float parameterValue,
            int parameterIndex,
            int parameterCount);
}
