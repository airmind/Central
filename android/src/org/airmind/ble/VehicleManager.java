package org.airmind.ble;

/**
 * Created by migu on 17/2/18.
 */

public class VehicleManager {
    private static final String TAG = "VehicleManager";


    /**
     * Currently only support PX4, to set SYS_AUTOSTART parameter (i.e. to define the auto-start script used to bootstrap the system).
     * Note: changing this value requires a restart.
     *
     * @param airFrameType to indicate auto-start script.
     */
    public static native void setAirFrameType(int airFrameType);


    /**
     * Currently only support PX4, to return SYS_AUTOSTART parameter value
     * @return SYS_AUTOSTART parameter value, -1 returned means invalid AirFrameType due to non-PX4 or no-active-vehicle
     */
    public static native int getAirFrameType();
}
