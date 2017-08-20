package org.airmind.ble;
/**
 * Created by caprin on 16-8-16.
 */

import android.annotation.TargetApi;
import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import java.util.List;
import java.util.UUID;

import java.util.Arrays;

import com.MAVLink.MAVLinkPacket;
import com.MAVLink.common.msg_encapsulated_data;

import com.MAVLink.common.msg_ping;
import com.MAVLink.common.msg_heartbeat;
import com.MAVLink.enums.MAV_AUTOPILOT;
import com.MAVLink.enums.MAV_MODE;
import com.MAVLink.enums.MAV_STATE;
import com.MAVLink.enums.MAV_TYPE;
import com.MAVLink.Parser;

/**
 * Service for managing connection and data communication with a GATT server hosted on a
 * given Bluetooth LE device.
 */
@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
public class BluetoothLeService extends Service {

    Parser mavParser;
    //For reliable write
    private static boolean longAttributeWrite = false;
    private static int packetSize = 0;
    private static int packetInteration = 0;
    private static byte[][] packets;
    private int seq = 0;
    //
    public boolean doThroughputTest = false;
    public boolean loopTPTest = true;
    public boolean notificationReceived = false;

    public static int MAVLINK_ATT_MTU = 23;
    private final static String TAG = BluetoothLeService.class.getSimpleName();

    private BluetoothManager mBluetoothManager;
    private BluetoothAdapter mBluetoothAdapter;

    public String getBluetoothDeviceAddress() {
        return mBluetoothDeviceAddress;
    }

    private String mBluetoothDeviceAddress;
    private BluetoothGatt mBluetoothGatt;
    private int mConnectionState = STATE_DISCONNECTED;
    private BluetoothGattCharacteristic peerMavLinkWriteCharacteristic;

    private static final int STATE_DISCONNECTED = 0;
    private static final int STATE_CONNECTING = 1;
    private static final int STATE_CONNECTED = 2;

    public final static String ACTION_GATT_CONNECTED =
            "com.example.bluetooth.le.ACTION_GATT_CONNECTED";
    public final static String ACTION_GATT_DISCONNECTED =
            "com.example.bluetooth.le.ACTION_GATT_DISCONNECTED";
    public final static String ACTION_GATT_SERVICES_DISCOVERED =
            "com.example.bluetooth.le.ACTION_GATT_SERVICES_DISCOVERED";
    public final static String ACTION_DATA_READ =
            "com.example.bluetooth.le.ACTION_DATA_READ";
    public final static String ACTION_DATA_NOTIFIED =
            "com.example.bluetooth.le.ACTION_DATA_NOTIFIED";
    public final static String EXTRA_DATA =
            "com.example.bluetooth.le.EXTRA_DATA";
    public final static String EXTRA_TP =
            "com.example.bluetooth.le.TP_DATA";

    public final static String EXTRA_DATA_BYTEARRAY = "com.example.bluetooth.le.EXTRA_DATA_BYTEARRAY";

    public final static UUID UUID_HEART_RATE_MEASUREMENT =
            UUID.fromString(SampleGattAttributes.HEART_RATE_MEASUREMENT);

    private long startTime;
    private long endTime;
    private long sendBytes;
    private long receivedBytes;
    public long startTPTestTime = 0;
    public long endTPTestTime = 0;
    public void startTPTest() {
        startTPTestTime = System.currentTimeMillis();
    }

    public void endTPTest() {
        endTPTestTime = System.currentTimeMillis();
    }

    public long getTPTestTime() {
        return endTPTestTime - startTPTestTime;
    }
    public void begin() {
        startTime = System.currentTimeMillis();
        endTime = startTime;
        sendBytes = receivedBytes = 0;
        startTPTestTime = 0;
        endTPTestTime = 0;
    }

    public long getBLERunTime() {
        endTime = System.currentTimeMillis();
        return endTime - startTime;
    }

    public void incTxBytes(long bytes) {
        sendBytes+=bytes;
    }
    public void incRxBytes(long bytes) {
        receivedBytes+=bytes;
    }

    public long getTxBytes() {
        return sendBytes;
    }

    public long getRxBytes() {
        return receivedBytes;
    }
    public BluetoothLeService() {
        super();
        mavParser = new Parser();
    }
    // Implements callback methods for GATT events that the app cares about.  For example,
    // connection change and services discovered.
    private final BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            String deviceAddress = gatt.getDevice().getAddress();
            String deviceName = gatt.getDevice().getName();
            Log.i(TAG, "[onConnectionStateChange] Peripheral：" + deviceAddress + "（"  + deviceName +"）,status:" + status + ", newState:" + newState);
            String intentAction;
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.i(TAG, "[onConnectionStateChange] Peripheral：" + deviceAddress + "（"  + deviceName +"）is connected");
                intentAction = ACTION_GATT_CONNECTED;
                mConnectionState = STATE_CONNECTED;
                linkStateChanged(intentAction);
//                Log.i(TAG, "Connected to GATT server. To reqeustMTU:" + MAVLINK_ATT_MTU);
                // Attempts to discover services after successful connection.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    mBluetoothGatt.requestMtu(MAVLINK_ATT_MTU);
                } else {
                    boolean result = mBluetoothGatt.discoverServices();
                    Log.i(TAG, "Attempting to start service discovery:" + result);
                    begin();
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                intentAction = ACTION_GATT_DISCONNECTED;
                mConnectionState = STATE_DISCONNECTED;
                Log.i(TAG, "[onConnectionStateChange] Peripheral：" + deviceAddress + "（"  + deviceName +"）is disconnected");
                linkStateChanged(intentAction);
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                linkStateChanged(ACTION_GATT_SERVICES_DISCOVERED);
            } else {
                if(status == 129 && gatt != null) {
                    disconnect();
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    connect(gatt.getDevice().getAddress());
                }
            }
        }

        /**
         * Callback reporting the result of a characteristic read operation.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#readCharacteristic}
         * @param characteristic Characteristic that was read from the associated
         *                       remote device.
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the read operation
         *               was completed successfully.
         */
        @Override
        public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG,"onCharacteristicRead() for characteristic-uuid:"+characteristic.getUuid().toString());
                if(!doThroughputTest) {
                    if(characteristic != null) {
                        byte[] bytes = characteristic.getValue();
                        if(bytes != null && bytes.length > 0) {
                            MAVLinkPacket mavLinkPacket = null;
                            for (byte oct : bytes) {
                                mavLinkPacket = mavParser.mavlink_parse_char(0xFF &  oct);
                            }
                            if (mavLinkPacket != null) {
                                Log.d(TAG, "onCharacteristicRead() encounter one mavLink msg, msgId:" + mavLinkPacket.msgid);
                                dataReceived(ACTION_DATA_READ, characteristic, mavLinkPacket.encodePacket());
                            }
                        }
                    }
                }
            }
        }

        /**
         * Callback triggered as a result of a remote characteristic notification.
         *
         * @param gatt GATT client the characteristic is associated with
         * @param characteristic Characteristic that has been updated as a result
         *                       of a remote notification event.
         */
        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            Log.d(TAG,"onCharacteristicChanged() for characteristic-uuid:"+characteristic.getUuid().toString());
            if(characteristic != null) {
                byte[] bytes = characteristic.getValue();
                if(bytes != null && bytes.length > 0) {
                    incRxBytes(bytes.length);

                    MAVLinkPacket mavLinkPacket = null;
                    for(byte oct : bytes) {
                        mavLinkPacket = mavParser.mavlink_parse_char(0xFF & oct);
                    }
                    if(mavLinkPacket != null) {
                        Log.d(TAG,"onCharacteristicChanged() encounter one mavLink msg, msgId:" + mavLinkPacket.msgid);
                        dataReceived(ACTION_DATA_NOTIFIED, characteristic, mavLinkPacket.encodePacket());
                    }
                }
            }
        }

        /**
         * Callback indicating the result of a characteristic write operation.
         *
         * <p>If this callback is invoked while a reliable write transaction is
         * in progress, the value of the characteristic represents the value
         * reported by the remote device. An application should compare this
         * value to the desired value to be written. If the values don't match,
         * the application must abort the reliable write transaction.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#writeCharacteristic}
         * @param characteristic Characteristic that was written to the associated
         *                       remote device.
         * @param status The result of the write operation
         *               {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         */
        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
                if(status == BluetoothGatt.GATT_SUCCESS) {
                    byte[] bytes = characteristic.getValue();
                    StringBuilder stringBuilder = new StringBuilder();
                    for (byte byteChar : bytes)
                        stringBuilder.append(String.format("%02X ", byteChar));
                    Log.d(TAG, "onCharacteristicWrite() for characteristic-uuid:" + characteristic.getUuid().toString() + ",data:" + stringBuilder.toString() + ",bytes.length:" + bytes.length +
                            ", status:" + (status == BluetoothGatt.GATT_SUCCESS ? "Succeed" : "Failed") + " (" + status + ")");
                    if (bytes != null && bytes.length > 0) {
                        incTxBytes(bytes.length);
                    }

//                    doTPTest();

                    if(longAttributeWrite) {
//                        Log.d(TAG,"onCharacteristicWrite() for long characteristic to execute reliable write");
                        if(packetInteration < packetSize) {
                            Log.d(TAG,"long characteristic queued packet:" + packetInteration);
                            packetInteration++;
                            characteristic.setValue(packets[packetInteration]);
                            mBluetoothGatt.writeCharacteristic(characteristic);
                        } else {
                            Log.d(TAG,"to execute write long characteristic");
                            mBluetoothGatt.executeReliableWrite();
                            longAttributeWrite = false;
                            packetInteration = 0;
                            packetSize = 0;
                            packets = null;
                        }
                    }
                } else {
                    Log.d(TAG,"onCharacteristicWrite() for long characteristic failed with " + status);
                    if(longAttributeWrite) {
                        Log.d(TAG,"onCharacteristicWrite() for long characteristic failed with " + status + ", to abort the write-trascation");
                        mBluetoothGatt.abortReliableWrite();
                        longAttributeWrite = false;
                    }
                }
        }

        /**
         * Callback invoked when a reliable write transaction has been completed.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#executeReliableWrite}
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the reliable write
         *               transaction was executed successfully
         */
        public void onReliableWriteCompleted(BluetoothGatt gatt, int status) {
            Log.d(TAG,"onReliableWriteCompleted() status:" + status);
        }
        /**
         * Callback reporting the result of a descriptor read operation.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#readDescriptor}
         * @param descriptor Descriptor that was read from the associated
         *                   remote device.
         * @param status {@link BluetoothGatt#GATT_SUCCESS} if the read operation
         *               was completed successfully
         */
        @Override
        public void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            Log.d(TAG,"onDescriptorRead()=> device:" + gatt.getDevice().getAddress() + ", descriptor:" + descriptor.toString() + ", status:" + status);
        }

        /**
         * Callback indicating the result of a descriptor write operation.
         *
         * @param gatt GATT client invoked {@link BluetoothGatt#writeDescriptor}
         * @param descriptor Descriptor that was writte to the associated
         *                   remote device.
         * @param status The result of the write operation
         *               {@link BluetoothGatt#GATT_SUCCESS} if the operation succeeds.
         */
        @Override
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            Log.d(TAG,"onDescriptorWrite()=> device:" + gatt.getDevice().getAddress() + ", descriptor:" + descriptor.toString() + ", status:" + status);
        }

        @Override
        public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
            Log.d(TAG,"onReadRemoteRssi()=> device:" + gatt.getDevice().getAddress() + ", rssi:" + rssi + ", status:" + status);
        }

        @Override
        public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                Log.d(TAG, "onMtuChanged()=> device:" + gatt.getDevice().getAddress() + ", mtu:" + mtu + ", status:" + status);
                boolean result = mBluetoothGatt.discoverServices();
                Log.i(TAG, "Attempting to start service discovery:" + result);
                begin();
            }
        }
    };

    private void linkStateChanged(final String action) {
        final Intent intent = new Intent(action);
        sendBroadcast(intent);
    }

    private void dataReceived(final String action, final BluetoothGattCharacteristic characteristic, byte[] data) {

        final Intent intent = new Intent(action);

        // This is special handling for the Heart Rate Measurement profile.  Data parsing is
        // carried out as per profile specifications:
        // http://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_measurement.xml
        if (UUID_HEART_RATE_MEASUREMENT.equals(characteristic.getUuid())) {
            int flag = characteristic.getProperties();
            int format = -1;
            if ((flag & 0x01) != 0) {
                format = BluetoothGattCharacteristic.FORMAT_UINT16;
                Log.d(TAG, "Heart rate format UINT16.");
            } else {
                format = BluetoothGattCharacteristic.FORMAT_UINT8;
                Log.d(TAG, "Heart rate format UINT8.");
            }
            final int heartRate = characteristic.getIntValue(format, 1);
            Log.d(TAG, String.format("Received heart rate: %d", heartRate));
            intent.putExtra(EXTRA_DATA, String.valueOf(heartRate));
        }  if(SampleGattAttributes.MAV_TRANSFER_CHARACTERISTIC_UUID.toLowerCase().equals(characteristic.getUuid().toString().toLowerCase())) {
            if(action.equals(ACTION_DATA_NOTIFIED)) {
                if(!notificationReceived) {
                    endTPTest();
                    notificationReceived = true;
                }
            }
//            final byte[] data = characteristic.getValue();
            if (data != null && data.length > 0) {
                intent.putExtra(EXTRA_DATA_BYTEARRAY, data);
                BTLinkIONative.dataArrived(mBluetoothDeviceAddress,SampleGattAttributes.MAV_TRANSFER_SERVICE_UUID.toLowerCase(),SampleGattAttributes.MAV_TRANSFER_CHARACTERISTIC_UUID.toLowerCase(),data);
                if(loopTPTest) {
                    doTPTest();
                }
                final StringBuilder stringBuilder = new StringBuilder(data.length);
                long timeElapsed = getBLERunTime();
                long txBits = getTxBytes() * 8;
                long rxBits = getRxBytes() * 8;
                long totalBits = txBits + rxBits;
                float seconds = timeElapsed/1000;
                float throuput = (long)((float)(txBits + rxBits)/seconds);
                float txThrouput = (long)((float)txBits/seconds);
                float rxThrouput = (long)((float) rxBits/seconds);
                stringBuilder.append(throuput + "=" + "Tx:" + txThrouput + " + " + "Rx:" + rxThrouput + " (bit/s)");
                intent.putExtra(EXTRA_TP, stringBuilder.toString());
                StringBuilder dataBuilder = new StringBuilder();
                dataBuilder.append("[Length:" + data.length + "]\n");
                for (byte byteChar : data)
                    dataBuilder.append(String.format("%02X ", byteChar));
                intent.putExtra(EXTRA_DATA, /*new String(data) + "\n" +*/ dataBuilder.toString());

                Log.d(TAG,"get Mavlink notification-value:" + dataBuilder.toString());
            } else {
                Log.d(TAG,"get Mavlink notification-value:");
            }
        } else {
            // For all other profiles, writes the data formatted in HEX.
//            final byte[] data = characteristic.getValue();
            intent.putExtra(EXTRA_DATA_BYTEARRAY, data);
            if (data != null && data.length > 0) {
                final StringBuilder stringBuilder = new StringBuilder(data.length);
                for (byte byteChar : data)
                    stringBuilder.append(String.format("%02X ", byteChar));
                intent.putExtra(EXTRA_DATA, new String(data) + "\n" + stringBuilder.toString());
            }
        }
        sendBroadcast(intent);
    }

    public class LocalBinder extends Binder {
        BluetoothLeService getService() {
            return BluetoothLeService.this;
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    @Override
    public boolean onUnbind(Intent intent) {
        // After using a given device, you should make sure that BluetoothGatt.close() is called
        // such that resources are cleaned up properly.  In this particular example, close() is
        // invoked when the UI is disconnected from the Service.
        close();
        return super.onUnbind(intent);
    }

    private final IBinder mBinder = new LocalBinder();

    /**
     * Initializes a reference to the local Bluetooth adapter.
     *
     * @return Return true if the initialization is successful.
     */
    public boolean initialize() {
        // For API level 18 and above, get a reference to BluetoothAdapter through
        // BluetoothManager.
        if (mBluetoothManager == null) {
            mBluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
            if (mBluetoothManager == null) {
                Log.e(TAG, "Unable to initialize BluetoothManager.");
                return false;
            }
        }

        mBluetoothAdapter = mBluetoothManager.getAdapter();
        if (mBluetoothAdapter == null) {
            Log.e(TAG, "Unable to obtain a BluetoothAdapter.");
            return false;
        }

        return true;
    }

    /**
     * Connects to the GATT server hosted on the Bluetooth LE device.
     *
     * @param address The device address of the destination device.
     * @return Return true if the connection is initiated successfully. The connection result
     * is reported asynchronously through the
     * {@code BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)}
     * callback.
     */
    public boolean connect(final String address) {
        if (mBluetoothAdapter == null || address == null) {
            Log.w(TAG, "BluetoothAdapter not initialized or unspecified address.");
            return false;
        }

        // Previously connected device.  Try to reconnect.
        if (mBluetoothDeviceAddress != null && address.equals(mBluetoothDeviceAddress)
                && mBluetoothGatt != null) {
            Log.d(TAG, "Trying to use an existing mBluetoothGatt for connection.");
            if (mBluetoothGatt.connect()) {
                mConnectionState = STATE_CONNECTING;
                return true;
            } else {
                return false;
            }
        }

        final BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(address);
        if (device == null) {
            Log.w(TAG, "Device not found.  Unable to connect.");
            return false;
        }
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        mBluetoothGatt = device.connectGatt(this, false, mGattCallback);
        Log.d(TAG, "Trying to create a new connection.");
        mBluetoothDeviceAddress = address;
        mConnectionState = STATE_CONNECTING;
        return true;
    }

    /**
     * Disconnects an existing connection or cancel a pending connection. The disconnection result
     * is reported asynchronously through the
     * {@code BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)}
     * callback.
     */
    public void disconnect() {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            Log.w(TAG, "BluetoothAdapter not initialized");
            return;
        }
        mBluetoothGatt.disconnect();
    }

    /**
     * After using a given BLE device, the app must call this method to ensure resources are
     * released properly.
     */
    public void close() {
        if (mBluetoothGatt == null) {
            return;
        }
        mBluetoothGatt.close();
        mBluetoothGatt = null;
    }

    /**
     * Request a read on a given {@code BluetoothGattCharacteristic}. The read result is reported
     * asynchronously through the {@code BluetoothGattCallback#onCharacteristicRead(android.bluetooth.BluetoothGatt, android.bluetooth.BluetoothGattCharacteristic, int)}
     * callback.
     *
     * @param characteristic The characteristic to read from.
     */
    public void readCharacteristic(BluetoothGattCharacteristic characteristic) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            Log.w(TAG, "BluetoothAdapter not initialized");
            return;
        }
        mBluetoothGatt.readCharacteristic(characteristic);
    }

    /**
     * Request a write on a given {@code BluetoothGattCharacteristic}. The write result is reported
     * asynchronously through the {@code BluetoothGattCallback#onCharacteristicRead(android.bluetooth.BluetoothGatt, android.bluetooth.BluetoothGattCharacteristic, int)}
     * callback.
     *
     * @param characteristic The characteristic to write on.
     */
    public void writeCharacteristic(final BluetoothGattCharacteristic characteristic, final byte[] value) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            Log.w(TAG, "[writeCharacteristic] BluetoothAdapter not initialized");
            return;
        }

        if(characteristic == null) {
            Log.w(TAG, "[writeCharacteristic] characteristic is null");
            return;
        }

        if(value == null) {
            Log.w(TAG, "[writeCharacteristic] value is null");
            return;
        }

        new Thread() {
            public void run() {
                characteristic.setValue(value);
//                Log.d(TAG, "[writeCharacteristic] try to set writeType to " + BluetoothGattCharacteristic.WRITE_TYPE_SIGNED);
//                characteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_SIGNED);
                mBluetoothGatt.writeCharacteristic(characteristic);
            }
        }.start();

    }

    public void writeLongAttribute(byte [] data, BluetoothGattCharacteristic characteristicData){
        if(longAttributeWrite == true) {
            Log.w(TAG, "[writeLongAttribute] ignore in that there is pending reliable write");
            return;
        }

        longAttributeWrite = true;
        int chunksize = 20; //20 byte chunk
        packetSize = (int) Math.ceil( data.length / (double)chunksize);

        //this is use as header, so peripheral device know ho much packet will be received.
//        characteristicData.setValue(/*packetSize.toString().getBytes()*/String.valueOf(packetSize).getBytes());
//        mBluetoothGatt.writeCharacteristic(characteristicData);
//        mBluetoothGatt.executeReliableWrite();

        packets = new byte[packetSize][chunksize];
        packetInteration =0;
        Integer start = 0;
        for(int i = 0; i < packets.length; i++) {
            int end = start+chunksize;
            if(end>data.length){end = data.length;}
            packets[i] = Arrays.copyOfRange(data,start, end);
            start += chunksize;
        }
        mBluetoothGatt.beginReliableWrite();
        Log.w(TAG, "[writeLongAttribute] to write first packet");
        characteristicData.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        characteristicData.setValue(packets[0]);
        mBluetoothGatt.writeCharacteristic(characteristicData);
    }
    /**
     * Enables or disables notification on a give characteristic.
     *
     * @param characteristic Characteristic to act on.
     * @param enabled        If true, enable notification.  False otherwise.
     */
    public void setCharacteristicNotification(BluetoothGattCharacteristic characteristic, boolean enabled) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            Log.w(TAG, "BluetoothAdapter not initialized");
            return;
        }
        mBluetoothGatt.setCharacteristicNotification(characteristic, enabled);

        // This is specific to Heart Rate Measurement.
        if ( UUID_HEART_RATE_MEASUREMENT.equals(characteristic.getUuid()) ||
             SampleGattAttributes.MAV_TRANSFER_CHARACTERISTIC_UUID.toLowerCase().equals(characteristic.getUuid().toString().toLowerCase())) {
            BluetoothGattDescriptor descriptor = characteristic.getDescriptor( UUID.fromString(SampleGattAttributes.CLIENT_CHARACTERISTIC_CONFIG));
            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
            mBluetoothGatt.writeDescriptor(descriptor);
        }
    }

    /**
     * Retrieves a list of supported GATT services on the connected device. This should be
     * invoked only after {@code BluetoothGatt#discoverServices()} completes successfully.
     *
     * @return A {@code List} of supported services.
     */
    public List<BluetoothGattService> getSupportedGattServices() {
        if (mBluetoothGatt == null) return null;

        return mBluetoothGatt.getServices();
    }

    //part to do throughput test
    public void setPeerMavLinkWriteCharacteristic(BluetoothGattCharacteristic peerMavLinkWriteCharacteristic) {
        this.peerMavLinkWriteCharacteristic = peerMavLinkWriteCharacteristic;
    }

    public void doTPTest() {
        if(!doThroughputTest) return;

        notificationReceived = false;
        byte[] bytes = BluetoothLeService.this.generateTestHeartBeatPacket();
        final StringBuilder stringBuilder = new StringBuilder(bytes.length);
        for (byte byteChar : bytes)
            stringBuilder.append(String.format("%02X ", byteChar));

        Log.d(TAG, "[doTPTest] to write:" + stringBuilder.toString() + "[" + bytes.length + "]");
        BluetoothLeService.this.writeCharacteristic(BluetoothLeService.this.peerMavLinkWriteCharacteristic, bytes);
    }

    public byte[] generateLogMavlinkPacket() {
        return new msg_encapsulated_data().pack().encodePacket();
    }

    public byte[] generateTestPacket_ping() {
        return new msg_ping().pack().encodePacket();
    }

    public byte[] generateTestHeartBeatPacket() {
        msg_heartbeat hb = new msg_heartbeat();
        hb.type = MAV_TYPE.MAV_TYPE_GCS;
        hb.autopilot = MAV_AUTOPILOT.MAV_AUTOPILOT_INVALID;
        hb.base_mode = MAV_MODE.MAV_MODE_MANUAL_ARMED;
        hb.custom_mode = 0;
        hb.system_status = MAV_STATE.MAV_STATE_ACTIVE;
        return hb.pack().encodePacket();
    }
}

