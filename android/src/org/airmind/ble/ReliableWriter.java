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

    public int getChunkIndexSending() {
        return chunkIndexSending;
    }

    private int chunkIndexSending = 0;

    public int getChunkCount() {
        return chunkCount;
    }

    public byte[][] getChunks() {
        return chunks;
    }

    public int getChunkIndex() {
        return chunkIndex;
    }


    public ReliableWriter(byte[] data) {
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

    public byte[] getChunk() {
        if(chunkCount != 0 && chunkIndex >= chunkCount) {
            return null;
        } else {
            chunkIndexSending = chunkIndex;
            return chunks[chunkIndex++];
        }
    }

    public byte[] getChunk(int index) {
        if( index < 0 || index >= chunkCount ) return null;
        return chunks[index];
    }

    public void destroy() {
        for(int i = 0; i< chunkCount; i++) {
            chunks[i] = null;
        }
    }
}
