/****************************************************************************
**
** Copyright (C) 2011-2012 Denis Shienkov <denis.shienkov@gmail.com>
** Copyright (C) 2011 Sergey Belyashov <Sergey.Belyashov@gmail.com>
** Copyright (C) 2012 Laszlo Papp <lpapp@kde.org>
** Copyright (C) 2012 Andre Hartmann <aha_1980@gmx.de>
** Contact: http://www.qt.io/licensing/
**
** This file is part of the QtSerialPort module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL21$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 or version 3 as published by the Free
** Software Foundation and appearing in the file LICENSE.LGPLv21 and
** LICENSE.LGPLv3 included in the packaging of this file. Please review the
** following information to ensure the GNU Lesser General Public License
** requirements will be met: https://www.gnu.org/licenses/lgpl.html and
** http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** As a special exception, The Qt Company gives you certain additional
** rights. These rights are described in The Qt Company LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** $QT_END_LICENSE$
**
****************************************************************************/
#include <errno.h>
#include <stdio.h>
#include <QtCore/qdebug.h>
#include <android/log.h>
#include "qble.h"
#include "BTSerialLink.h"
#include "QGCApplication.h"
QT_BEGIN_NAMESPACE

static const char kJTag[] {"QBLE"};

static void jniConnect(JNIEnv *env, jobject thizA, jstring jdevice, jstring jservice, jstring jcharateristic)
{
    Q_UNUSED(thizA);
    const char* device = env->GetStringUTFChars(jdevice, NULL);
    const char* service = env->GetStringUTFChars(jservice, NULL);
    const char* characteristic = env->GetStringUTFChars(jcharateristic, NULL);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnect is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);

    BTSerialConfiguration* btconfig = new BTSerialConfiguration(QString::fromUtf8(device));
    QString sid = QString::fromUtf8(service);
    QString cid = QString::fromUtf8(characteristic);
    QString deviceAddress = QString::fromUtf8(device);
    btconfig->configBLESerialLink(deviceAddress, deviceAddress, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnect->configBLESerialLink is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);

    //create a physical link and connect;
    if(qgcApp() == NULL) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnect->qgcApp() is null is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);
    }
    qgcApp()->toolbox()->linkManager()->createConnectedBLELink(btconfig);

    if(device) env->ReleaseStringUTFChars(jdevice, device);
    if(service) env->ReleaseStringUTFChars(jservice, service);
    if(characteristic) env->ReleaseStringUTFChars(jcharateristic, characteristic);
}
/*
static void jniConnected(JNIEnv *env, jobject thizA, jstring jdevice, jstring jservice, jstring jcharateristic)
{
    Q_UNUSED(thizA);
    const char* device = env->GetStringUTFChars(jdevice, NULL);
    const char* service = env->GetStringUTFChars(jservice, NULL);
    const char* characteristic = env->GetStringUTFChars(jcharateristic, NULL);

    QString did = QString::fromUtf8(device);
    QString sid = QString::fromUtf8(service);
    QString cid = QString::fromUtf8(characteristic);
//    QString sid = QString::fromUtf8(MAV_TRANSFER_SERVICE_UUID);
//    QString cid = QString::fromUtf8(MAV_TRANSFER_CHARACTERISTIC_UUID);
    BTSerialConfiguration* btconfig = new BTSerialConfiguration(did);
    btconfig->configBLESerialLink(did, did, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);
    BTSerialLink* bleLink = qgcApp()->toolbox()->linkManager()->getBLELinkByConfiguration(btconfig);
    if(bleLink != NULL) {
//        bleLink->setActive(true);
    }
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnected is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);
    if(device) env->ReleaseStringUTFChars(jdevice, device);
    if(service) env->ReleaseStringUTFChars(jservice, service);
    if(characteristic) env->ReleaseStringUTFChars(jcharateristic, characteristic);
}
*/

static void jniDataArrived(JNIEnv *env, jobject thizA, jstring jdevice, jstring jservice, jstring jcharateristic, jbyteArray data)
{
    Q_UNUSED(thizA);
    const char* device = env->GetStringUTFChars(jdevice, NULL);
    const char* service = env->GetStringUTFChars(jservice, NULL);
    const char* characteristic = env->GetStringUTFChars(jcharateristic, NULL);

    QString did = QString::fromUtf8(device);
    QString sid = QString::fromUtf8(service);
    QString cid = QString::fromUtf8(characteristic);
    BTSerialConfiguration* btconfig = new BTSerialConfiguration(did);
    btconfig->configBLESerialLink(did, did, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);
    BTSerialLink* bleLink = qgcApp()->toolbox()->linkManager()->getBLELinkByConfiguration(btconfig);
    if(bleLink != NULL) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "jniDataArrived is called, device:%s, service:%s, characteristic:%s, found the link", device, service, characteristic);
        int len = env->GetArrayLength (data);
        char* buf = new char[len];
        env->GetByteArrayRegion (data, 0, len, reinterpret_cast<jbyte*>(buf));

        bleLink->didReadBytes(buf,len);
    }
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniDataArrived is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);
    if(device) env->ReleaseStringUTFChars(jdevice, device);
    if(service) env->ReleaseStringUTFChars(jservice, service);
    if(characteristic) env->ReleaseStringUTFChars(jcharateristic, characteristic);
}

static void jniDiscover(JNIEnv *env, jobject thizA)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniDiscover is called");
    qgcApp()->toolbox()->linkManager()->discoverBTLinks(0);
}

static void jniDidDiscover(JNIEnv *env, jobject thizA, jstring inRangeFileName, jstring outRangeFileName)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniDidDiscover is called");
    const char* inFName = env->GetStringUTFChars(inRangeFileName, NULL);
    const char* outFName = env->GetStringUTFChars(outRangeFileName, NULL);

    QString inF = QString::fromUtf8(inFName);
    QString outF = QString::fromUtf8(outFName);

    QFile inRangeFile(inF);
    bool validInRangeFile = false;
    QString line;
    if(inRangeFile.exists()) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniDidDiscover] to handle inRangeFile:%s",inFName);
        if(inRangeFile.size() > 0) {
            if(inRangeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                validInRangeFile = true;
                QTextStream in(&inRangeFile);
                while(!in.atEnd()) {
                    line =in.readLine();
                    __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniDidDiscover.inRange] %s",line.toLatin1().data());
                }
                inRangeFile.close();
            }

        }
    }

    QFile outRangeFile(outF);
    bool validOutRangeFile = false;
    if(outRangeFile.exists()) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniDidDiscover] to handle outRangeFile:%s",outFName);
        if(outRangeFile.size() > 0) {
            if(outRangeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                validOutRangeFile = true;
                QTextStream out(&outRangeFile);
                while(!out.atEnd()) {
                    line = out.readLine();
                    __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniDidDiscover.outRange] %s",line.toLatin1().data());
                }
                outRangeFile.close();
            }
        }
    }

    if(!validInRangeFile && !validOutRangeFile) {
        goto done;
    }

    qgcApp()->toolbox()->linkManager()->didDiscoverBLELinks(0,0);

done:
    if(inFName) env->ReleaseStringUTFChars(inRangeFileName, inFName);
    if(outFName) env->ReleaseStringUTFChars(outRangeFileName, outFName);
}

static void jniTcpConnect(JNIEnv *env, jobject thizA, jstring host, jint port)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniTcpConnect is called");

    static int tcpLinkIndex = 0;
    const char* chost = env->GetStringUTFChars(host, NULL);
    QString sHost = QString::fromUtf8(chost);
    QString linkConfigName = QString::asprintf("%s-%s-%d","tcp",chost, tcpLinkIndex++);
    LinkConfiguration* linkConfig = qgcApp()->toolbox()->linkManager()->createConfiguration(LinkConfiguration::TypeTcp,linkConfigName);
    TCPConfiguration* tcpConfig = qobject_cast<TCPConfiguration*>(linkConfig);
    tcpConfig->setHost(sHost);
    tcpConfig->setPort((quint16)port);
    qgcApp()->toolbox()->linkManager()->endCreateConfiguration(linkConfig);
    bool ret = QMetaObject::invokeMethod(qgcApp()->toolbox()->linkManager(),"createConnectedLink",Qt::AutoConnection, Q_ARG(LinkConfiguration*, linkConfig));
    if(!ret) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniTcpConnect] failed to call LinkManager.createConnectedLink()");
    }
    if(chost) env->ReleaseStringUTFChars(host, chost);
}

static void jniShutdown(JNIEnv *env, jobject thizA)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniShutdown is called");

    bool ret = QMetaObject::invokeMethod(qgcApp()->toolbox()->linkManager(),"shutdown",Qt::AutoConnection);
    if(!ret) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniShutdown] failed to call LinkManager.createConnectedLink()");
    }
}

static void jniStopScanning(JNIEnv *env, jobject thizA)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniStopScanning is called");
    qgcApp()->toolbox()->linkManager()->stopScanning();
}

static void jniRefreshAllParameters(JNIEnv *env, jobject thizA)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniRefreshAllParameters is called");

    Vehicle*  _vehicle = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle();
    if (_vehicle) {
         AutoPilotPlugin* _autopilot = _vehicle->autopilotPlugin();
        _autopilot->refreshAllParameters();
    }
}

/*
 static void jniWrite(JNIEnv *env, jobject thizA, jstring jdevice, jstring jservice, jstring jcharateristic, jbyteArray data)
{
    Q_UNUSED(thizA);
    const char* device = env->GetStringUTFChars(jdevice, NULL);
    const char* service = env->GetStringUTFChars(jservice, NULL);
    const char* characteristic = env->GetStringUTFChars(jcharateristic, NULL);

    QString did = QString::fromUtf8(device);
    QString sid = QString::fromUtf8(service);
    QString cid = QString::fromUtf8(characteristic);
//    QString sid = QString::fromUtf8(MAV_TRANSFER_SERVICE_UUID);
//    QString cid = QString::fromUtf8(MAV_TRANSFER_CHARACTERISTIC_UUID);
    BTSerialConfiguration* btconfig = new BTSerialConfiguration(did);
    btconfig->configBLESerialLink(did, did, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);
    BTSerialLink* bleLink = qgcApp()->toolbox()->linkManager()->getBLELinkByConfiguration(btconfig);
    if(bleLink != NULL) {
        int len = env->GetArrayLength (data);
        char* buf = new char[len];
        env->GetByteArrayRegion (data, 0, len, reinterpret_cast<jbyte*>(buf));
        bleLink->writeBytes(buf,len);
    }
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnect is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);
    if(device) env->ReleaseStringUTFChars(jdevice, device);
    if(service) env->ReleaseStringUTFChars(jservice, service);
    if(characteristic) env->ReleaseStringUTFChars(jcharateristic, characteristic);
}
static void jniRead(JNIEnv *env, jobject thizA, jstring jdevice, jstring jservice, jstring jcharateristic, jbyteArray data)
{
    Q_UNUSED(thizA);
    const char* device = env->GetStringUTFChars(jdevice, NULL);
    const char* service = env->GetStringUTFChars(jservice, NULL);
    const char* characteristic = env->GetStringUTFChars(jcharateristic, NULL);

    QString did = QString::fromUtf8(device);
    QString sid = QString::fromUtf8(service);
    QString cid = QString::fromUtf8(characteristic);
    BTSerialConfiguration* btconfig = new BTSerialConfiguration(did);
    btconfig->configBLESerialLink(did, did, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);
    BTSerialLink* bleLink = qgcApp()->toolbox()->linkManager()->getBLELinkByConfiguration(btconfig);
    if(bleLink != NULL) {
        int len = env->GetArrayLength (data);
        char* buf = new char[len];
        env->GetByteArrayRegion (data, 0, len, reinterpret_cast<jbyte*>(buf));
        bleLink->didReadBytes(buf,len);
    }

    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnect is called, device:%s, service:%s, characteristic:%s", device, service, characteristic);
    if(device) env->ReleaseStringUTFChars(jdevice, device);
    if(service) env->ReleaseStringUTFChars(jservice, service);
    if(characteristic) env->ReleaseStringUTFChars(jcharateristic, characteristic);
}
*/

static void jniSetAirframeType(JNIEnv *env, jobject thizA, jint airFrameType)
{
    Q_UNUSED(env);
    Q_UNUSED(thizA);
    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniSetAirframeType is called");
    Vehicle*  _vehicle = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle();
    if (_vehicle) {
         if(_vehicle->px4Firmware()) {
             __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniSetAirframeType] to set PX4's AirFrameType(Auto-Start script) to %d", airFrameType);
         } else {
             if(_vehicle->apmFirmware()) {
                 __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniSetAirframeType] do not support APM currently");
             }
         }
    } else {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "[jniSetAirframeType] no active-vehicle");
    }
}
/*!
    Constructs a new serial port object with the given \a parent.
*/
QBLE::QBLE(QObject *parent) : QIODevice(parent)
{}


/*!
    Closes the serial port, if necessary, and then destroys object.
*/
QBLE::~QBLE()
{
}
void QBLE::setNativeMethods(const char* classname, JNINativeMethod javaMethods[], int methodCount)
{
    if(classname == NULL || classname[0] == '\0' || javaMethods == NULL || methodCount == 0) {
        __android_log_print(ANDROID_LOG_INFO, kJTag, "invalid input parameters");
        return;
    }

    __android_log_print(ANDROID_LOG_INFO, kJTag, "Registering Native Functions for class:%s",classname);

    QAndroidJniEnvironment jniEnv;
    if (jniEnv->ExceptionCheck()) {
        jniEnv->ExceptionDescribe();
        jniEnv->ExceptionClear();
    }

    jclass objectClass = jniEnv->FindClass(classname);
    if(!objectClass) {
        __android_log_print(ANDROID_LOG_ERROR, kJTag, "Couldn't find class: %s", classname);
        return;
    }
    jint val = jniEnv->RegisterNatives(objectClass, javaMethods, methodCount);

    __android_log_print(ANDROID_LOG_INFO, kJTag, "Native Functions Registered for class:%s", classname);

    if (jniEnv->ExceptionCheck()) {
        jniEnv->ExceptionDescribe();
        jniEnv->ExceptionClear();
    }

    if (val < 0) {
        __android_log_print(ANDROID_LOG_ERROR, kJTag, "Error registering methods for class:%s", classname);
    }
}
void QBLE::setNativeMethods(void)
{
    __android_log_print(ANDROID_LOG_INFO, kJTag, "Registering Native Functions");

    //  REGISTER THE C++ FUNCTION WITH JNI
    JNINativeMethod linkManagerNativeMethods[] {
        {"discover","()V",reinterpret_cast<void *>(jniDiscover)},
        {"didDiscover","(Ljava/lang/String;Ljava/lang/String;)V",reinterpret_cast<void *>(jniDidDiscover)},
        {"stopScanning","()V",reinterpret_cast<void *>(jniStopScanning)},
        {"connect", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",reinterpret_cast<void *>(jniConnect)},
        {"tcpConnect", "(Ljava/lang/String;I)V",reinterpret_cast<void *>(jniTcpConnect)},
        {"shutdown","()V",reinterpret_cast<void *>(jniShutdown)},
    };
    setNativeMethods("org/airmind/ble/LinkManagerNative",linkManagerNativeMethods, sizeof(linkManagerNativeMethods)/sizeof(linkManagerNativeMethods[0]));

    JNINativeMethod btLinkIONativeMethods[] {
        {"dataArrived", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;[B)V",reinterpret_cast<void *>(jniDataArrived)}
    };
    setNativeMethods("org/airmind/ble/BTLinkIONative",btLinkIONativeMethods, sizeof(btLinkIONativeMethods)/sizeof(btLinkIONativeMethods[0]));

    JNINativeMethod parametersNativeMethods[] {
        {"refreshAllParameters", "()V",reinterpret_cast<void *>(jniRefreshAllParameters)}
    };
    setNativeMethods("org/airmind/ble/ParameterManager",parametersNativeMethods, sizeof(parametersNativeMethods)/sizeof(parametersNativeMethods[0]));

    JNINativeMethod vehicleManagerNativeMethods[] {
        {"setAirFrameType", "(I)V",reinterpret_cast<void *>(jniSetAirframeType)}
    };
    setNativeMethods("org/airmind/ble/VehicleManager",vehicleManagerNativeMethods, sizeof(vehicleManagerNativeMethods)/sizeof(vehicleManagerNativeMethods[0]));
}

QT_END_NAMESPACE
