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
#include <QtAndroidExtras/QtAndroidExtras>
#include <QtAndroidExtras/QAndroidJniObject>
#include "qble.h"
#include "BTSerialLink.h"
#include "QGCApplication.h"
QT_BEGIN_NAMESPACE

static const char kJniClassName[] {"org/airmind/ble/BLECommNative"};
static const char kJTag[] {"QBLE"};

static void jniConnect(JNIEnv *env, jobject thizA, jstring jdevice, jstring jservice, jstring jcharateristic)
{
    const char* device = env->GetStringUTFChars(jdevice, NULL);
    const char* service = env->GetStringUTFChars(jservice, NULL);
    const char* characteristic = env->GetStringUTFChars(jcharateristic, NULL);

    BTSerialConfiguration* btconfig = new BTSerialConfiguration(QString::fromUtf8(device));
    QString sid = QString::fromUtf8(MAV_TRANSFER_SERVICE_UUID);
    QString cid = QString::fromUtf8(MAV_TRANSFER_CHARACTERISTIC_UUID);
    QString deviceAddress = QString::fromUtf8(device);
    btconfig->configBLESerialLink(deviceAddress, deviceAddress, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);

    //create a physical link and connect;
    BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->createConnectedBLELink(btconfig);

    __android_log_print(ANDROID_LOG_INFO, kJTag, "jniConnect is called, device:%s, service:%s, characteristic:%s", device);
    if(device) env->ReleaseStringUTFChars(jdevice, device);
    if(service) env->ReleaseStringUTFChars(jservice, service);
    if(characteristic) env->ReleaseStringUTFChars(jcharateristic, characteristic);
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

void QBLE::setNativeMethods(void)
{
    __android_log_print(ANDROID_LOG_INFO, kJTag, "Registering Native Functions");

    //  REGISTER THE C++ FUNCTION WITH JNI
    JNINativeMethod javaMethods[] {
        {"connect", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",reinterpret_cast<void *>(jniConnect)}
    };

    QAndroidJniEnvironment jniEnv;
    if (jniEnv->ExceptionCheck()) {
        jniEnv->ExceptionDescribe();
        jniEnv->ExceptionClear();
    }

    jclass objectClass = jniEnv->FindClass(kJniClassName);
    if(!objectClass) {
        __android_log_print(ANDROID_LOG_ERROR, kJTag, "Couldn't find class: %s", kJniClassName);
        return;
    }

    jint val = jniEnv->RegisterNatives(objectClass, javaMethods, sizeof(javaMethods) / sizeof(javaMethods[0]));

    __android_log_print(ANDROID_LOG_INFO, kJTag, "Native Functions Registered");

    if (jniEnv->ExceptionCheck()) {
        jniEnv->ExceptionDescribe();
        jniEnv->ExceptionClear();
    }

    if (val < 0) {
        __android_log_print(ANDROID_LOG_ERROR, kJTag, "Error registering methods");
    }
}

QT_END_NAMESPACE
