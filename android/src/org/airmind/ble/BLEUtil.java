package org.airmind.ble;

import android.bluetooth.BluetoothGattCharacteristic;
import android.util.Log;

/**
 * Created by migu on 2017/9/3.
 */

public class BLEUtil {
    private final static String TAG = BLEUtil.class.getSimpleName();
    public static String getString(byte[] data) {
        if(data == null || data.length == 0) return "";

        StringBuilder stringBuilder = new StringBuilder(data.length);
        for (byte byteChar : data) {
            stringBuilder.append(String.format("%02X ", byteChar));
        }
        return stringBuilder.toString();
    }

    public static void sendData(BluetoothLeService bluetoothLeService, BluetoothGattCharacteristic peerMavLinkWriteCharacteristic, byte[] data) {
        if(data.length > ReliableWriter.CHUNKSIZE)  {
            bluetoothLeService.SMALLPACKET = false;
        } else {
            bluetoothLeService.SMALLPACKET = true;
        }
        if(bluetoothLeService.SMALLPACKET == false) {
            bluetoothLeService.rw = new ReliableWriter(data);
        } else {
            bluetoothLeService.rw = null;
        }

        Log.d(BTLinkIO.TAG, "[sendData] to write:" + getString(data) + "[" + data.length + "]");
        if(bluetoothLeService.rw != null) {
            byte[] bytesToBeSent = null;
            boolean ret = false;
            if(bluetoothLeService.REALIABLE_WRITE) {
                bluetoothLeService.mBluetoothGatt.beginReliableWrite();
            }
            bytesToBeSent = bluetoothLeService.rw.getChunk();
            if(bytesToBeSent != null) {
                ret = bluetoothLeService.writeCharacteristic(peerMavLinkWriteCharacteristic, bytesToBeSent);
                Log.d(TAG, "[" + System.currentTimeMillis() + "] to write chunk [" + 1 + "]\"" + getString(bytesToBeSent) + "\", length:" + bytesToBeSent.length + ", result:" + ret);
            } else {
                Log.e(TAG, "get null chunk");
            }
        } else {
            bluetoothLeService.writeCharacteristic(peerMavLinkWriteCharacteristic, data);
        }
    }

    public static boolean isBytesMatch(byte[] bytes1, byte[] bytes2) {
        if(bytes1 == null || bytes2 == null || bytes1.length != bytes2.length) return false;
        boolean same = true;
        for(int i = 0; i < bytes1.length; i++) {
            if(bytes1[i] != bytes2[i]) {
                same = false;
                break;
            }
        }
        return same;
    }
}
