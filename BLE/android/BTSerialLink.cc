//
//  BTSerialLink.cpp
//  QGroundControl
//
//  Created by ning roland on 8/15/16.
//
//

#include <stdio.h>
#include "BTSerialLink.h"
#include <QtAndroidExtras/QAndroidJniObject>
#include <QtAndroidExtras/QAndroidJniEnvironment>
/****************************
 BLEHelper class implementation
 **/
BLEHelper::BLEHelper(){
}

BLEHelper::~BLEHelper() {
}

void BLEHelper::setCallbackDelegate(void* delegate) {
    Q_UNUSED(delegate);

//    ble_wrapper->setCallbackDelegate(delegate);
}


void BLEHelper::discover(void*) {
}

void BLEHelper::discoverServices(void*){
}

void BLEHelper::discoverCharacteristics(void*){
}

void BLEHelper::stopScanning(){
}

//====BTSerialConfig
BTSerialConfiguration::BTSerialConfiguration(const QString& name) :
    LinkConfiguration(name), connstage(BLE_LINK_CONNECTED_CHARACTERISTIC)
{
}

BTSerialConfiguration::BTSerialConfiguration(BTSerialConfiguration* source) :
    LinkConfiguration(source), connstage(BLE_LINK_CONNECTED_CHARACTERISTIC)
{
   identifier = source->getBLEPeripheralIdentifier();
   pname = source->getBLEPeripheralName();
   serviceID = source->getBLEPeripheralServiceID();
   characteristicID = source->getBLEPeripheralCharacteristicID();
}

BTSerialConfiguration:: ~BTSerialConfiguration() {

}

void BTSerialConfiguration::configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid, BLE_LINK_CONNECT_STAGE stage) {

    identifier = linkid;
    pname = linkname;
    serviceID = sid;
    characteristicID = cid;
    connstage = stage;
}


void BTSerialConfiguration::copyFrom(LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    BTSerialConfiguration* ssource = dynamic_cast<BTSerialConfiguration*>(source);
    Q_ASSERT(ssource != NULL);
    identifier = ssource->getBLEPeripheralIdentifier();
    pname = ssource->getBLEPeripheralName();
    serviceID = ssource->getBLEPeripheralServiceID();
    characteristicID = ssource->getBLEPeripheralCharacteristicID();
}


//do not support setting qml
QString BTSerialConfiguration::settingsURL() {
    return "";
}

void BTSerialConfiguration::saveSettings(QSettings& settings, const QString& root)
{
    settings.beginGroup(root);
    settings.setValue("deviceAddress",           identifier);
    settings.setValue("deviceName",       pname);
    settings.setValue("serviceUUI",    serviceID);
    settings.setValue("characteristicUUID",       characteristicID);
    settings.endGroup();
}

void BTSerialConfiguration::loadSettings(QSettings& settings, const QString& root)
{
    settings.beginGroup(root);
    if(settings.contains("deviceAddress"))       identifier           = settings.value("deviceAddress").toString();
    if(settings.contains("deviceName"))          pname       = settings.value("deviceName").toString();
    if(settings.contains("serviceUUI"))          serviceID    = settings.value("serviceUUI").toString();
    if(settings.contains("characteristicUUID"))  characteristicID       = settings.value("characteristicUUID").toString();
    settings.endGroup();
}

void BTSerialConfiguration::updateSettings()
{
//    if(_link) {
//        BTSerialLink* serialLink = dynamic_cast<BTSerialLink*>(_link);
//        if(BTSerialLink) {
//            BTSerialLink->_resetConfiguration();
//        }
//    }
}

QString BTSerialConfiguration::getBLEPeripheralIdentifier() {
    return identifier;
}

QString BTSerialConfiguration::getBLEPeripheralName() {
    return pname;
}

QString BTSerialConfiguration::getBLEPeripheralServiceID() {
    return serviceID;
}

QString BTSerialConfiguration::getBLEPeripheralCharacteristicID() {
    return characteristicID;
}

BLE_LINK_CONNECT_STAGE BTSerialConfiguration::getBLELinkConnectStage() {
    return connstage;
}



/******************************************
 BTSerialLink class;

 */
extern void cleanJavaException(void);
BTSerialLink::BTSerialLink(BTSerialConfiguration *config)
: _mavlinkChannelSet(false)
, _linkstatus(BLE_LINK_NOT_CONNECTED)
{
    _config = config;
    Q_ASSERT(_config != NULL);

    qDebug() << "Bluetooth serial comm Created " << _config->name();
}

BTSerialLink::BTSerialLink(BTSerialConfiguration* config, MAVLinkProtocol* handler)
:mavhandler(handler)
,_mavlinkChannelSet(false)
, _linkstatus(BLE_LINK_NOT_CONNECTED)

{
    _config = config;
    Q_ASSERT(_config != NULL);
    Q_ASSERT(mavhandler != NULL);

    qDebug() << "Bluetooth serial comm Created " << _config->name();
}

BTSerialLink::~BTSerialLink()
{
    _disconnect();
}

void BTSerialLink::setLinkConnectedStatus(BLE_LINK_STATUS status) {
    _linkstatus = status;
}


void BTSerialLink::setMAVLinkProtocolHandler(MAVLinkProtocol* protocolhandler) {
    mavhandler = protocolhandler;
}


void BTSerialLink::didReadBytes(const char* data, qint64 size) {
    qDebug() << "BTSerialLink::didReadBytes: " << data;
    QByteArray baData(data,size);
    mavhandler->receiveBytes(this, baData);
}

void BTSerialLink::didConnect() {
    mavhandler->linkConnected(this);
}

void BTSerialLink::didDisconnect() {
    mavhandler->linkDisconnected(this);
}

void BTSerialLink::run()
{
}

#ifdef BTSERIALLINK_READWRITE_DEBUG
void BTSerialLink::_writeDebugBytes(const char *data, qint16 size)
{
    //[btcwrapper->btc_objc ]
    QString bytes;
    QString ascii;
    for (int i=0; i<size; i++)
    {
        unsigned char v = data[i];
        bytes.append(QString().sprintf("%02x ", v));
        if (data[i] > 31 && data[i] < 127)
        {
            ascii.append(data[i]);
        }
        else
        {
            ascii.append(219);
        }
    }
    qDebug() << "Sent" << size << "bytes to" << _config->address().toString() << ":" << _config->port() << "data:";
    qDebug() << bytes;
    qDebug() << "ASCII:" << ascii;
}
#endif

void BTSerialLink::writeBytes(const char* data, qint64 size)
{
    if( data == NULL ||
        size <= 0 ||
        _config->getBLEPeripheralIdentifier().isEmpty() ||
        _config->getBLEPeripheralServiceID().isEmpty() ||
        _config->getBLEPeripheralCharacteristicID().isEmpty()) {
        return;
    }

    QAndroidJniObject deviceAddress = QAndroidJniObject::fromString(_config->getBLEPeripheralIdentifier());
    QAndroidJniObject serviceUUI = QAndroidJniObject::fromString(_config->getBLEPeripheralServiceID());
    QAndroidJniObject characteristicUUID = QAndroidJniObject::fromString(_config->getBLEPeripheralCharacteristicID());

    QAndroidJniEnvironment env;
    jbyteArray ba = env->NewByteArray(size);
    if(ba != NULL) {
        env->SetByteArrayRegion(ba, 0, size, (jbyte *)data);
    }

    QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/BTLinkIO", "write", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;[B)V",
                                               deviceAddress.object<jstring>(),
                                               serviceUUI.object<jstring>(),
                                               characteristicUUID.object<jstring>(),
                                               ba
                                               );
    cleanJavaException();
}


void BTSerialLink::writeMAVDataBytes(const char* data, qint64 size) {

}


void BTSerialLink::writeBytes(QString characteristic, const char* data, qint64 size) {

}

void BTSerialLink::writeBytesNeedsAck(QString characteristic, const char* data, qint64 size) {

}

void BTSerialLink::writeBytesNeedsAck(const char* data, qint64 size) {

}

/**
 * @brief Read a number of bytes from the interface.
 *
 * @param data Pointer to the data byte array to write the bytes to
 * @param maxLength The maximum number of bytes to write
 **/


void BTSerialLink::readBytes()
{
}


void BTSerialLink::readMAVDataBytes() {

}

void BTSerialLink::readBytes(QString characteristic) {

}

/**
 * @brief Disconnect the connection.
 *
 * @return True if connection has been disconnected, false if connection couldn't be disconnected.
 **/
bool BTSerialLink::_disconnect(void)
{
    return true;
}

/**
 * @brief Connect the connection.
 *
 * @return True if connection has been established, false if connection couldn't be established.
 **/
bool BTSerialLink::_connect()
{
    if(_config->getBLEPeripheralIdentifier().isEmpty()) return false;

    QAndroidJniObject deviceAddress = QAndroidJniObject::fromString(_config->getBLEPeripheralIdentifier());
    QAndroidJniObject serviceUUI = QAndroidJniObject::fromString(_config->getBLEPeripheralServiceID());
    QAndroidJniObject characteristicUUID = QAndroidJniObject::fromString(_config->getBLEPeripheralCharacteristicID());

    QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager",
                                               "connect",
                                               "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
                                               deviceAddress.object<jstring>(),
                                               serviceUUI.object<jstring>(),
                                               characteristicUUID.object<jstring>()
                                               );
    cleanJavaException();
    return true;
}

bool BTSerialLink::_hardwareConnect()
{
    //QString* identifier = _config->getBLEPeripheralIdentifier();
//    return btlwrapper->_hardwareConnect();
}

void BTSerialLink::setCallbackDelegate(void* delegate) {
    //btlwrapper->setCallbackDelegate(delegate);
}


void BTSerialLink::_socketError(QAbstractSocket::SocketError socketError)
{
    Q_UNUSED(socketError);
    //emit communicationError(tr("Link Error"), QString("Error on link %1. Error on socket: %2.").arg(getName()).arg(_socket->errorString()));
}

/**
 * @brief Check if connection is active.
 *
 * @return True if link is connected, false otherwise.
 **/
bool BTSerialLink::isConnected() const
{

//    if (_linkstatus == BLE_LINK_NOT_CONNECTED) {
    if(_config->getBLELinkConnectStage() == BLE_LINK_NOT_CONNECTED) {
        return false;
    }
    return true;
}

QString BTSerialLink::getName() const
{
    return _config->name();
}

qint64 BTSerialLink::getConnectionSpeed() const
{
    return 54000000; // 54 Mbit
}

qint64 BTSerialLink::getCurrentInDataRate() const
{
    return 0;
}

qint64 BTSerialLink::getCurrentOutDataRate() const
{
    return 0;
}



void BTSerialLink::_restartConnection()
{
    if(this->isConnected())
    {
        _disconnect();
        _connect();
    }
}
