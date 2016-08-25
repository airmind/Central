//
//  BTSerialLink.cpp
//  QGroundControl
//
//  Created by ning roland on 8/15/16.
//
//

#include <stdio.h>
#include "BTSerialLink.h"

//define JNI call interface for blehelper java impl;
#include "BLEHelper_java.h"

class BLEHelperWrapper {
    BLEHelper_java* bleh_java;
public:
    BLEHelperWrapper();
    ~BLEHelperWrapper();
    
    void setCallbackDelegate(void*);
    void discover(void*);
    void discoverServices(void*);
    void discoverCharacteristics(void*);
    void stopScanning();
};



#ifdef __android__

#endif

/****************************
 BLEHelper class implementation
 **/

BLEHelper::BLEHelper(){
    ble_wrapper = new BLEHelperWrapper();
    
}

BLEHelper::~BLEHelper() {
    if (ble_wrapper != NULL) {
        delete ble_wrapper;
    }
}

void BLEHelper::setCallbackDelegate(void* delegate) {
    
    ble_wrapper->setCallbackDelegate(delegate);
}


void BLEHelper::discover(void*) {
    ble_wrapper->discover(nil);

}

void BLEHelper::discoverServices(void*){
    ble_wrapper->discoverServices(nil);
}

void BLEHelper::discoverCharacteristics(void*){
    ble_wrapper->discoverCharacteristics(nil);
}

void BLEHelper::stopScanning(){
    ble_wrapper->stopScanning();
}


/****************************
 BLEHelperWrapper class implementation
 **/

BLEHelperWrapper::BLEHelperWrapper () {
    //ble_objc = [BLEHelper_objc sharedInstance];
}

BLEHelperWrapper::~BLEHelperWrapper () {
    
}

void BLEHelperWrapper::setCallbackDelegate(void* delegate) {
    //[ble_objc setCallbackDelegate:(__bridge id)delegate];
}


void BLEHelperWrapper::discover(void*) {
    QAndroidJniObject::callStaticMethod<void>( "org/qgroundcontrol/qgchelper/UsbDeviceJNI", "discover", "(Ljava/lang/String;)V", jnameL.object<jstring>());

}

void BLEHelperWrapper::discoverServices(void*) {
    //[ble_objc discoverServices:nil];
    QAndroidJniObject::callStaticMethod<void>( "org/qgroundcontrol/qgchelper/UsbDeviceJNI", "discoverServices", "(Ljava/lang/String;)V", jnameL.object<jstring>());

}

void BLEHelperWrapper::discoverCharacteristics(void*) {
    //[ble_objc discoverCharacteristics:nil];
    QAndroidJniObject::callStaticMethod<void>( "org/qgroundcontrol/qgchelper/UsbDeviceJNI", "discoverCharacteristics", "(Ljava/lang/String;)V", jnameL.object<jstring>());
}

void BLEHelperWrapper::stopScanning() {
    //[ble_objc stopScanning];
    QAndroidJniObject::callStaticMethod<void>( "org/qgroundcontrol/qgchelper/UsbDeviceJNI", "stopScanning", "(Ljava/lang/String;)V", jnameL.object<jstring>());

}

