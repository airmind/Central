package org.airmind.ble;

import java.util.Arrays;

/**
 * Created by migu on 2017/9/2.
 */

public class ReliableWriter {
    public final static int CHUNKSIZE = 20;
    private byte[][] chunks;
    private int chunkCount = 0;
    private int chunkIndex;

    public int getChunkCount() {
        return chunkCount;
    }

    public byte[][] getChunks() {
        return chunks;
    }

    public int getChunkIndex() {
        return chunkIndex;
    }

//    enum Reliable_Write_State {
//        RW_STATE_UNINIT,
//        RW_STATE_SENDING,
//        RW_STATE_SENT
//    }
//
//    public Reliable_Write_State getState() {
//        return state;
//    }

//    Reliable_Write_State state = Reliable_Write_State.RW_STATE_UNINIT;

//    byte[] data;
//    int lengthSent;
//    int totalLength;
//    int offset;
//    public byte[] bytes = null;


//    public ReliableWriter() {
//        data = null;
//        lengthSent = 0;
//        totalLength = 0;
//        offset = 0;
//    }

    public ReliableWriter(byte[] data) {
//        if(data != null) {
//            this.data = data;
//            totalLength = this.data.length;
//        }
//        lengthSent = 0;
//        offset = 0;


        chunkIndex = 0;
        chunkCount = (int) Math.ceil( data.length / (double)CHUNKSIZE);
        chunks = new byte[chunkCount][CHUNKSIZE];
        Integer start = 0;
        for(int i = 0; i < chunks.length; i++) {
            int end = start+CHUNKSIZE;
            if(end>data.length){end = data.length;}
            chunks[i] = Arrays.copyOfRange(data,start, end);
            start += CHUNKSIZE;
        }
    }

//    public byte[] getSendData() {
//        if(data == null) return null;
//
//        int segmentEndByteIndex = offset + CHUNKSIZE - 1;
//        int endByteIndex = totalLength - 1;
//        if(offset == endByteIndex) { //write out final byte
//            if(state == Reliable_Write_State.RW_STATE_SENDING) {
//                bytes = Arrays.copyOfRange(data, offset, offset + 1);
//                state = Reliable_Write_State.RW_STATE_SENT;
//            } else if(state == Reliable_Write_State.RW_STATE_SENT) {
//                bytes = null;
//            }
//        } else {
//            if (segmentEndByteIndex <= endByteIndex) {
//                bytes = Arrays.copyOfRange(data, offset, offset + CHUNKSIZE);
//                offset += CHUNKSIZE;
//                state = Reliable_Write_State.RW_STATE_SENDING;
//            } else {
//                if(state == Reliable_Write_State.RW_STATE_SENDING) {
//                    bytes = Arrays.copyOfRange(data, offset, totalLength);
//                    offset += (totalLength - 1 - offset + 1);
//                    state = Reliable_Write_State.RW_STATE_SENT;
//                } else {
//                    bytes = null;
//                }
//            }
//        }
//
//        return bytes;
//    }

    public byte[] getChunk() {
        if(chunkCount != 0 && chunkIndex >= chunkCount) {
            return null;
        } else {
            return chunks[chunkIndex++];
        }
    }

    public void destroy() {
        for(int i = 0; i< chunkCount; i++) {
            chunks[i] = null;
        }
    }
}
