/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief Brief Description
 *
 *   @author Lorenz Meier <mavteam@student.ethz.ch>
 *
 */

#include <QList>
#include <QApplication>
#include <QDebug>
#include <QSignalSpy>

#ifndef __ios__
#include "QGCSerialPortInfo.h"
#endif

#include "LinkManager.h"
#include "QGCApplication.h"
#include "UDPLink.h"
#include "TCPLink.h"
#ifdef QGC_ENABLE_BLUETOOTH
#include "BluetoothLink.h"
#endif

#ifdef __mindskin__
#include <mindskinlog.h>
#endif

#ifndef __mobile__
    #include "GPSManager.h"
#endif

#ifdef __android__
#include <android/log.h>
static const char kJTag[] {"LinkManager"};
#include <QtAndroidExtras/QAndroidJniObject>
#include <QtAndroidExtras/QAndroidJniEnvironment>
extern void cleanJavaException(void);
#endif
QGC_LOGGING_CATEGORY(LinkManagerLog, "LinkManagerLog")
QGC_LOGGING_CATEGORY(LinkManagerVerboseLog, "LinkManagerVerboseLog")

const char* LinkManager::_settingsGroup =           "LinkManager";
const char* LinkManager::_autoconnectUDPKey =       "AutoconnectUDP";
const char* LinkManager::_autoconnectPixhawkKey =   "AutoconnectPixhawk";
const char* LinkManager::_autoconnect3DRRadioKey =  "Autoconnect3DRRadio";
const char* LinkManager::_autoconnectPX4FlowKey =   "AutoconnectPX4Flow";
const char* LinkManager::_autoconnectRTKGPSKey =    "AutoconnectRTKGPS";
const char* LinkManager::_defaultUPDLinkName =      "Default UDP Link";

const int LinkManager::_autoconnectUpdateTimerMSecs =   1000;
#ifdef Q_OS_WIN
// Have to manually let the bootloader go by on Windows to get a working connect
const int LinkManager::_autoconnectConnectDelayMSecs =  6000;
#else
const int LinkManager::_autoconnectConnectDelayMSecs =  1000;
#endif

LinkManager::LinkManager(QGCApplication* app)
    : QGCTool(app)
    , _configUpdateSuspended(false)
    , _configurationsLoaded(false)
    , _connectionsSuspended(false)
    , _mavlinkChannelsUsedBitMask(1)    // We never use channel 0 to avoid sequence numbering problems
    , _mavlinkProtocol(NULL)
    , _autoconnectUDP(true)
    , _autoconnectPixhawk(true)
    , _autoconnect3DRRadio(true)
    , _autoconnectPX4Flow(true)
    , _autoconnectRTKGPS(true)
{
    qmlRegisterUncreatableType<LinkManager>         ("QGroundControl", 1, 0, "LinkManager",         "Reference only");
    qmlRegisterUncreatableType<LinkConfiguration>   ("QGroundControl", 1, 0, "LinkConfiguration",   "Reference only");
    qmlRegisterUncreatableType<LinkInterface>       ("QGroundControl", 1, 0, "LinkInterface",       "Reference only");

    QSettings settings;

    settings.beginGroup(_settingsGroup);
    _autoconnectUDP =       settings.value(_autoconnectUDPKey, true).toBool();
    _autoconnectPixhawk =   settings.value(_autoconnectPixhawkKey, true).toBool();
    _autoconnect3DRRadio =  settings.value(_autoconnect3DRRadioKey, true).toBool();
    _autoconnectPX4Flow =   settings.value(_autoconnectPX4FlowKey, true).toBool();
    _autoconnectRTKGPS =    settings.value(_autoconnectRTKGPSKey, true).toBool();

#ifndef __ios__
    _activeLinkCheckTimer.setInterval(_activeLinkCheckTimeoutMSecs);
    _activeLinkCheckTimer.setSingleShot(false);
    connect(&_activeLinkCheckTimer, &QTimer::timeout, this, &LinkManager::_activeLinkCheck);
#endif
#ifdef __mindskin__
    udpSocket = new QUdpSocket(this);
    udpSocket->bind(UDP_LISTEN_PORT, QUdpSocket::ShareAddress);
    QString host = udpSocket->localAddress().toString();
    int port = udpSocket->localPort();
    qDebug() << "[LinkManager] bind to udp address:" << host << ", port:" << port;
    connect(udpSocket, SIGNAL(readyRead()), this, SLOT(processPendingDatagrams()));
    #ifdef __android__
    QAndroidJniObject jHost = QAndroidJniObject::fromString(host);
    QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "udpSocketServerBound", "(Ljava/lang/String;I)V", jHost.object<jstring>(), port);
    cleanJavaException();
    #endif
#endif
}

LinkManager::~LinkManager()
{
#if defined(__mindskin__) && defined(__ios__)
    delete blehelper;
#endif
}

#ifdef __mindskin__
void LinkManager::processPendingDatagrams()
{
    static int tcpLinkIndex = 0;
    while (udpSocket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(udpSocket->pendingDatagramSize());
        udpSocket->readDatagram(datagram.data(), datagram.size());
        qDebug() << "[DHCP-message]:" << datagram.data();

        QString msg(datagram.data());
        QString sHost = msg.section(',',0,0);
        QString hwAddr = msg.section(',', 1, 1);
        QString sMsgType = msg.section(',', 2, 2);
        #ifdef __android__
        QAndroidJniObject jHost = QAndroidJniObject::fromString(sHost);
        QAndroidJniObject jHWAddr = QAndroidJniObject::fromString(hwAddr);
        QAndroidJniObject jMsgType = QAndroidJniObject::fromString(sMsgType);
        QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "dhcpv4LeaseNotification", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", jMsgType.object<jstring>(), jHost.object<jstring>(),jHWAddr.object<jstring>());
        cleanJavaException();
        #endif

        if(!sHost.isNull() && !sHost.isEmpty() && (sMsgType.compare("lease4_select") == 0 ||  sMsgType.compare("lease4_renew") == 0)) {
            QString linkConfigName = QString::asprintf("%s-%s-%d","tcp",sHost.data(), tcpLinkIndex++);
            LinkConfiguration* linkConfig = qgcApp()->toolbox()->linkManager()->createConfiguration(LinkConfiguration::TypeTcp,linkConfigName);
            TCPConfiguration* tcpConfig = qobject_cast<TCPConfiguration*>(linkConfig);
            tcpConfig->setHost(sHost);
            tcpConfig->setPort(6789);
            qgcApp()->toolbox()->linkManager()->endCreateConfiguration(linkConfig);
            LinkInterface* linkInterface = qgcApp()->toolbox()->linkManager()->createConnectedLink(linkConfig);
            if(linkInterface == NULL) {
                qDebug() << "[processPendingDatagrams] failed to call LinkManager.createConnectedLink()";
            }
    //        bool ret = QMetaObject::invokeMethod(qgcApp()->toolbox()->linkManager(),"createConnectedLink",Qt::AutoConnection, Q_ARG(LinkConfiguration*, linkConfig));
    //        if(!ret) {
    //            qDebug() << "[processPendingDatagrams] failed to call LinkManager.createConnectedLink()";
    //        }
        }
    }
}
#endif

void LinkManager::setToolbox(QGCToolbox *toolbox)
{
   QGCTool::setToolbox(toolbox);

   _mavlinkProtocol = _toolbox->mavlinkProtocol();

    connect(&_portListTimer, &QTimer::timeout, this, &LinkManager::_updateAutoConnectLinks);
    _portListTimer.start(_autoconnectUpdateTimerMSecs); // timeout must be long enough to get past bootloader on second pass

}

#ifdef __mindskin__
//for BT LE;
bool LinkManager::discoverBTLinks(void* delegate) {
    #ifdef __ios__
        if (blehelper == NULL) {
            //create blehelper object;
            blehelper = new BLEHelper();
        }
        blehelper->discover(delegate);
    #endif
    #ifdef __android__
        Q_UNUSED(delegate);
        QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "discover", "(V)V" );
        cleanJavaException();
    #endif
    return true;
}

bool LinkManager::stopScanning() {
    #ifdef __ios__
        blehelper->stopScanning();
    #endif
    #ifdef __android__
        QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "stopScanning", "(V)V" );
        cleanJavaException();
    #endif
    return true;
}

void LinkManager::setCallbackDelegate(void* delegate) {
    #ifdef __ios__
        if(blehelper==NULL) {
            blehelper = new BLEHelper();
        }
        blehelper->setCallbackDelegate(delegate);
    #endif
    #ifdef __android__
            Q_UNUSED(delegate);
    #endif
}

BTSerialLink* LinkManager::createConnectedBLELink(BTSerialConfiguration* config){
    
    //trycreateblelink; _hardwareconnect, didconnectblehardware, _addlink/connect, didconnectlink;
    BTSerialLink* blelink = new BTSerialLink((BTSerialConfiguration*)config, _mavlinkProtocol);
    
    if(blelink) {
#ifdef __android__
        __android_log_print(ANDROID_LOG_INFO, kJTag, "createConnectedBLELink to add ble-link");
        _addLink(blelink);
        blelink->_connect();
#endif

#ifdef __ios__
        //check if existing link;
        if (_blelinks.contains(blelink)) {
            return blelink;
        }
        
        //check if same config exists; currently only one link to a same characteristic is allowed to prevent interfere with each other.
        bool found = false; //This seems impossible in that same qgc can not connect to same BLE device's character twice
        for (int i=0; i<_blelinks.count(); i++) {
            BTSerialLink* blink = _blelinks.value<BTSerialLink*>(i);
            BTSerialConfiguration* cfg = blink->getLinkConfiguration();
            Q_ASSERT(cfg);
            
            //BTSerialConfiguration* cfg_newlink = blelink->getLinkConfiguration();
            
            if (cfg == config) {
                found = true;
                break;
            }
        }
        
        if (found) {
            //not allowed;
            return NULL;
        }

        
        //check if periheral connected;
        found=false;
        for (int i=0; i<_blelinks.count(); i++) {
            BTSerialLink* blink = _blelinks.value<BTSerialLink*>(i);
            BTSerialConfiguration* cfg = blink->getLinkConfiguration();
            Q_ASSERT(cfg);
            
            BTSerialConfiguration* cfg_newlink = blelink->getLinkConfiguration();
            
            if (cfg->getBLEPeripheralIdentifier() == cfg_newlink->getBLEPeripheralIdentifier()) {
                found = true;
                break;
            }
        }

        
        if (found == true) {
            
            //populate logic link right now.
            blelink->_connect();
        
            return blelink;
        }

        int res = _registerTrialConnect(blelink);
        
        if (res == -3) {
            return blelink;
        }
        else if (res == -2) {
            //try connecting to same characteristic, now allowed;
            return NULL;
        }
        else if (res == -1) {
            //peripheral already in line for connect;
            return blelink;
        }
        else {
            //new link request, do hardware connect first;
            blelink->_hardwareConnect();
            return blelink;
            
        }
#endif
    }
    return blelink;
}

BTSerialLink* LinkManager::createConnectedBLELink(const QString& identifier){
    Q_UNUSED(identifier);
    //BTSerialLink* blelink = new BTSerialLink(identifier);
    //blelink->_connect();
    return NULL;
}

int LinkManager::_registerTrialConnect(BTSerialLink* blelink) {
    

    //check if exists in trial line;
    if (_bletriallinks.contains(blelink)) {
        return -3;
    }
    
    //check if same config exists;
    bool found=false;
    for (int i=0; i<_bletriallinks.count(); i++) {
        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
        Q_ASSERT(cfg);
        
        BTSerialConfiguration* cfg_newlink = blelink->getLinkConfiguration();
        
        if (cfg == cfg_newlink) {
            found = true;
            break;
        }
    }
    if (found) {
        
        //not allowed;
        return -2;
    }

    
    //check if same peripheral on trial;
    found=false;
    for (int i=0; i<_bletriallinks.count(); i++) {
        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
        Q_ASSERT(cfg);
            
        BTSerialConfiguration* cfg_newlink = blelink->getLinkConfiguration();
            
        if (cfg->getBLEPeripheralIdentifier() == cfg_newlink->getBLEPeripheralIdentifier()) {
            found = true;
            break;
        }
    }
    if (found) {
        
        _bletriallinks.append(blelink);
        return -1;
    }
    else {
        _bletriallinks.append(blelink);
        return 0;
    
    }
    
}

bool LinkManager::_removeTrialConnect(BTSerialLink* blelink) {
    int i = _bletriallinks.indexOf(blelink);
    
    if (i != -1) {
        _bletriallinks.removeAt(i);
        return true;
    }
    
    return false;

}


BTSerialLink* LinkManager::getBLELinkByConfiguration(BTSerialConfiguration* cfg) {
    if(_blelinks.count() == 0 || cfg == NULL) {
        return NULL;
    }

    for(int i=0;i<_blelinks.count();i++) {
        BTSerialLink* btLink = _blelinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* btLinkConfig = btLink->getLinkConfiguration();
        if(btLinkConfig->equals(cfg)) {
            return btLink;
        }
    }

    return NULL;
}

bool LinkManager::connectLink(BTSerialLink* link) {
    
}

bool LinkManager::disconnectLink(BTSerialLink* link) {
    if (!link || !_blelinks.contains(link)) {
        return false;
    }
    
    //link->_disconnect();
    BTSerialConfiguration* config = link->getLinkConfiguration();
    QString uuid = config->getBLEPeripheralIdentifier();
    if (config) {
        if (_autoconnectConfigurations.contains(config)) {
            config->setLink(NULL);
        }
    }
    _deleteLink(link);
    if (_autoconnectConfigurations.contains(config)) {
        qCDebug(LinkManagerLog) << "Removing disconnected autoconnect config" << config->name();
        _autoconnectConfigurations.removeOne(config);
        delete config;
    }
    
    //disconnect objc logical link;
    link->_disconnect();
    
    bool found = false;
    //check for peripheral with no logical link and disconnect;
    for (int i=0; i<_blelinks.count(); i++) {
        BTSerialLink* blink = _blelinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
        Q_ASSERT(cfg);
        
        
        if (cfg->getBLEPeripheralIdentifier() == uuid) {
            found = true;
            break;
        }
    }

    if (!found) {
        // disconnect peripheral physically;
        link->_hardwareDisconnect();
    }
    return true;
}

//new signal - have a try;
#if defined(__ios__) || defined(__android__)
void LinkManager::didDiscoverBLELinks(void* inrangelist, void* outrangelist) {
    //inrangelist/outrangelist have platform dependent types so can not use directly in implementation. needs type conversion.
    emit peripheralsDiscovered(inrangelist, outrangelist);
}
#endif

void LinkManager::didConnectBLEHardware(QString peripheralUUID) {
    bool found=false;
    BTSerialLink* blink;
    int i;
    for (i=0; i<_bletriallinks.count(); i++) {
        blink = _bletriallinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
        Q_ASSERT(cfg);
        
        if (cfg->getBLEPeripheralIdentifier() == peripheralUUID) {
            found = true;
            break;
        }
    }
    if (found) {
        //connect to endpoint;
        blink->_connect();
    }
    else {
        return;
    }
    

}


//Do we still follow this try/connect pattern?
void LinkManager::failedConnectBLEHardware(QString peripheralUUID) {
    //remove all pending trial links;
    bool found=false;
    BTSerialLink* blink;
    int i;
    for (i=0; i<_bletriallinks.count(); i++) {
        blink = _bletriallinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
        Q_ASSERT(cfg);
        
        if (cfg->getBLEPeripheralIdentifier() == peripheralUUID) {
            _removeTrialConnect(blink);
            found = true;
            //break;
        }
    }

}

void LinkManager::didConnectBLELink(BTSerialLink* blelink) {
    //set blelink status;
    if ((blelink->getLinkConfiguration())->getBLELinkConnectStage()==BLE_LINK_CONNECT_CHARACTERISTIC) {
        blelink->setLinkConnectedStatus(BLE_LINK_ENDPOINT_CONNECTED);
    } else {
        blelink->setLinkConnectedStatus(BLE_LINK_HARDWARE_CONNECTED);
    }
    //remove trial link;
    _removeTrialConnect(blelink);
    _addLink(blelink);
    
    emit linkConnected(blelink);
    
    BTSerialConfiguration* cfg_curlink = blelink->getLinkConfiguration();

    //find next, and connect all pending links on same peripheral one by one;
    bool found=false;
    BTSerialLink* nextblink;
    int i;
    for (i=0; i<_bletriallinks.count(); i++) {
        nextblink = _bletriallinks.value<BTSerialLink*>(i);
        BTSerialConfiguration* cfg = nextblink->getLinkConfiguration();
        Q_ASSERT(cfg);
        
        if (cfg->getBLEPeripheralIdentifier() == cfg_curlink->getBLEPeripheralIdentifier()) {
            found = true;
            break;
        }
    }
    if (found) {
        //connect to endpoint;
        nextblink->_connect();
    }
    else {
        return;
    }
}

void LinkManager::failedConnectBLELink(BTSerialLink* blelink) {
    //set blelink status;
    if ((blelink->getLinkConfiguration())->getBLELinkConnectStage()==BLE_LINK_CONNECT_CHARACTERISTIC) {
        blelink->setLinkConnectedStatus(BLE_LINK_ENDPOINT_CONNECTED);
    }
    else {
        blelink->setLinkConnectedStatus(BLE_LINK_HARDWARE_CONNECTED);
        
    }
    
    emit linkFailedToConnect(blelink);
    
}


void LinkManager::didDisconnectBLELink(BTSerialLink* blelink) {
    blelink->setLinkConnectedStatus(BLE_LINK_NOT_CONNECTED);
    
    emit linkDisconnected(blelink);
}

#if defined(__ios__)||defined(__android__)
void LinkManager::didUpdateConnectedBLELinkRSSI(QList<QString>* peripheral_link_list) {
    Q_ASSERT(peripheral_link_list);
    
    //check all links for active / inactive according to RSSI;
    for (int i=0; i<peripheral_link_list->count(); i++) {
        QString pname = peripheral_link_list->at(i);
        int rssi = blehelper->currentFilteredPeripheralRSSI(pname);
        BLE_LINK_QUALITY newlq;
        if (rssi >= DRONETAG_DISCONNECT_WARNING_RANGE) {
            newlq = BLE_LINK_QUALITY_INRANGE;
        }
        else if (rssi >= DRONETAG_DISCONNECT_RANGE && rssi < DRONETAG_DISCONNECT_WARNING_RANGE) {
            newlq = BLE_LINK_QUALITY_ALERT;
        }
        else {
            newlq = BLE_LINK_QUALITY_OUTOFRANGE;
        }

        
        BLE_LINK_QUALITY lq = blehelper->currentPeripheralLinkQuality(pname);
        
        switch (newlq) {
            case BLE_LINK_QUALITY_INRANGE:
                
                if (lq == BLE_LINK_QUALITY_OUTOFRANGE) {
                    //signal all links belong to this peripheral going active;
                    for (int j=0; j<_blelinks.count(); j++) {
                        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(j);
                        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
                        Q_ASSERT(cfg);
                        
                        if (cfg->getBLEPeripheralIdentifier() == peripheral_link_list->at(j)) {
                            //emit get into range signal;
                            emit radioLinkGetIntoRange(blink);
                        }
                    }

                }
                break;
            case BLE_LINK_QUALITY_ALERT:
                if (lq == BLE_LINK_QUALITY_OUTOFRANGE) {
                    
                    //signal all links belong to this peripheral going active;
                    for (int j=0; j<_blelinks.count(); j++) {
                        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(j);
                        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
                        Q_ASSERT(cfg);
                        
                        if (cfg->getBLEPeripheralIdentifier() == peripheral_link_list->at(j)) {
                            //emit get into range signal;
                            emit radioLinkGetIntoRange(blink);
                        }
                    }

                }
                break;
            case BLE_LINK_QUALITY_OUTOFRANGE:
                if (lq == BLE_LINK_QUALITY_ALERT || lq == BLE_LINK_QUALITY_INRANGE) {
                    //signal all links belong to this peripheral going inactive;
                    for (int j=0; j<_blelinks.count(); j++) {
                        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(j);
                        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
                        Q_ASSERT(cfg);
                        
                        if (cfg->getBLEPeripheralIdentifier() == peripheral_link_list->at(j)) {
                            ////emit out of range signal;
                            emit radioLinkOutOfRange(blink);
                        }
                    }
                    
                }
                break;
            default:
                break;
        }
        
        //set new link quality;
        blehelper->setPeripheralLinkQuality(pname, newlq);
    }
    
    //done, clear peripheral list;
    peripheral_link_list->clear();
    delete peripheral_link_list;
    
    //emit bleLinkRSSIUpdated (peripheral_link_list);
}
#endif
#endif
LinkInterface* LinkManager::createConnectedLink(LinkConfiguration* config)
{
    Q_ASSERT(config);
    LinkInterface* pLink = NULL;
    switch(config->type()) {
#ifndef __ios__
        case LinkConfiguration::TypeSerial:
        {
            SerialConfiguration* serialConfig = dynamic_cast<SerialConfiguration*>(config);
            if (serialConfig) {
                pLink = new SerialLink(serialConfig);
                if (serialConfig->usbDirect()) {
                    _activeLinkCheckList.append((SerialLink*)pLink);
                    if (!_activeLinkCheckTimer.isActive()) {
                        _activeLinkCheckTimer.start();
                    }
                }
            }
        }
        break;
#endif
        case LinkConfiguration::TypeUdp:
            pLink = new UDPLink(dynamic_cast<UDPConfiguration*>(config));
            break;
        case LinkConfiguration::TypeTcp:
            pLink = new TCPLink(dynamic_cast<TCPConfiguration*>(config));
            break;
#ifdef QGC_ENABLE_BLUETOOTH
        case LinkConfiguration::TypeBluetooth:
            pLink = new BluetoothLink(dynamic_cast<BluetoothConfiguration*>(config));
            break;
#endif
#ifndef __mobile__
        case LinkConfiguration::TypeLogReplay:
            pLink = new LogReplayLink(dynamic_cast<LogReplayLinkConfiguration*>(config));
            break;
#endif
#ifdef QT_DEBUG
        case LinkConfiguration::TypeMock:
            pLink = new MockLink(dynamic_cast<MockConfiguration*>(config));
            break;
#endif
        case LinkConfiguration::TypeLast:
        default:
            break;
    }
    if(pLink) {
        _addLink(pLink);
        connectLink(pLink);
    }
    return pLink;
}

LinkInterface* LinkManager::createConnectedLink(const QString& name)
{
    Q_ASSERT(name.isEmpty() == false);
    for(int i = 0; i < _linkConfigurations.count(); i++) {
        LinkConfiguration* conf = _linkConfigurations.value<LinkConfiguration*>(i);
        if(conf && conf->name() == name)
            return createConnectedLink(conf);
    }
    return NULL;
}

void LinkManager::_addLink(LinkInterface* link)
{
    if (thread() != QThread::currentThread()) {
        qWarning() << "_deleteLink called from incorrect thread";
        return;
    }

    if (!link) {
        return;
    }

    if (!_links.contains(link)) {
        bool channelSet = false;

        // Find a mavlink channel to use for this link
        for (int i=0; i<32; i++) {
            if (!(_mavlinkChannelsUsedBitMask & 1 << i)) {
                mavlink_reset_channel_status(i);
                link->_setMavlinkChannel(i);
                _mavlinkChannelsUsedBitMask |= i << i;
                channelSet = true;
                break;
            }
        }

        if (!channelSet) {
            qWarning() << "Ran out of mavlink channels";
        }

        _links.append(link);
        emit newLink(link);
    }


#ifndef __mindskin__  //?__ios__
    connect(link, &LinkInterface::communicationError,   _app,               &QGCApplication::criticalMessageBoxOnMainThread);
    connect(link, &LinkInterface::bytesReceived,        _mavlinkProtocol,   &MAVLinkProtocol::receiveBytes);
    
    _mavlinkProtocol->resetMetadataForLink(link);
    
    connect(link, &LinkInterface::connected,            this, &LinkManager::_linkConnected);
    connect(link, &LinkInterface::disconnected,         this, &LinkManager::_linkDisconnected);
    
    // This connection is queued since it will cloe the link. So we want the link emitter to return otherwise we would
    // close the link our from under itself.
    connect(link, &LinkInterface::connectionRemoved,    this, &LinkManager::_linkConnectionRemoved, Qt::QueuedConnection);
#else
    
    connect(link, &LinkInterface::communicationError,   _app,               &QGCApplication::criticalMessageBoxOnMainThread);
    connect(link, &LinkInterface::bytesReceived,        _mavlinkProtocol,   static_cast<void (MAVLinkProtocol::*)(LinkInterface*, QByteArray)>(&MAVLinkProtocol::receiveBytes));
   
    _mavlinkProtocol->resetMetadataForLink(link);
    
    connect(link, &LinkInterface::connected,            this, &LinkManager::_linkConnected);
    connect(link, &LinkInterface::disconnected,         this, &LinkManager::_linkDisconnected);
    
    // This connection is queued since it will cloe the link. So we want the link emitter to return otherwise we would
    // close the link our from under itself.
    connect(link, &LinkInterface::connectionRemoved,    this, &LinkManager::_linkConnectionRemoved, Qt::QueuedConnection);

    
#endif
    
}

#ifdef __mindskin__
/*

bool LinkManager::containsLink(BTSerialLink* link) {
    bool found = false;
    foreach (BTSerialLink* blelink, _blelinks) {
        if (blelink == link) {
            found = true;
            break;
        }
    }
    return found;
}
*/

void LinkManager::_deleteLink(BTSerialLink* link) {
    /*
    Q_ASSERT(link);
    
    //_bleLinkListMutex.lock();
    
    // Free up the mavlink channel associated with this link
    _mavlinkChannelsUsedBitMask &= ~(1 << link->getMavlinkChannel());
    
    bool found = false;
    for (int i=0; i<_blelinks.count(); i++) {
        //no data member function as it is not a QSharedPointer object.
        if (_blelinks[i] == link) {
            _blelinks.removeAt(i);
            found = true;
            break;
        }
    }
    Q_UNUSED(found);
    Q_ASSERT(found);
    
    //_bleLinkListMutex.unlock();
    
    // Emit removal of link
    emit linkDeleted(link);
*/
    if (thread() != QThread::currentThread()) {
        qWarning() << "_deleteLink called from incorrect thread";
        return;
    }
    
    if (!link) {
        return;
    }
    
    // Free up the mavlink channel associated with this link
    _mavlinkChannelsUsedBitMask &= ~(1 << link->getMavlinkChannel());
    
    _blelinks.removeOne(link);
    delete link;
    
    // Emit removal of link
    emit linkDeleted(link);

}

void LinkManager::_addLink(BTSerialLink* link) {
    Q_ASSERT(link);
    
   // _bleLinkListMutex.lock();
    
    //if (!containsLink(link)) {
    if (!_blelinks.contains(link)) {
        // Find a mavlink channel to use for this link
        int y=0;
        for (int i=0; i<32; i++) {
            if (!(_mavlinkChannelsUsedBitMask & 1 << i)) {
                mavlink_reset_channel_status(i);
                link->_setMavlinkChannel(i);
                _mavlinkChannelsUsedBitMask |= i << i;
                break;
            }
            y++;
        }
        if (y==31) {
            int x = y;
        }
        link->getMavlinkChannel();
        
        _blelinks.append(link);
        //_bleLinkListMutex.unlock();
        //why we emit a newLink signal here but no receiving slot?
        emit newLink(link);
    } else {
        //_bleLinkListMutex.unlock();
    }
    
    // MainWindow may be around when doing things like running unit tests
    //if (MainWindow::instance()) {
        //connect(link, &BTSerialLink::communicationError, _app, &QGCApplication::criticalMessageBoxOnMainThread);
    //}
    
    ///We do not need signal here, use didConnected call back instead;
    //connect(link, &LinkInterface::bytesReceived,    _mavlinkProtocol, &MAVLinkProtocol::receiveBytes);
    //connect(link, static_cast<void (LinkManager::*)(BTSerialLink*)>(&LinkManager::linkConnected),        _mavlinkProtocol, static_cast<void (MAVLinkProtocol::*)(BTSerialLink*)>(&MAVLinkProtocol::linkConnected));
    //connect(link, &LinkInterface::disconnected,     _mavlinkProtocol, &MAVLinkProtocol::linkDisconnected);
    
    ///Clear bunch of link statistic counters;
    //_mavlinkProtocol->resetMetadataForLink(link);
    
    //connect(link, &BTSerialLink::connected,    this, &LinkManager::_linkConnected);
    //connect(link, &BTSerialLink::disconnected, this, &LinkManager::_linkDisconnected);
    
    ///TODO: need to add bytesReceived callback in BTSerialLink;

}


void LinkManager::_bleLinkConnected(void) {
    
}

void LinkManager::_bleLinkDisconnected(void) {
    
}


#endif

#if defined(_BLE_DEBUG_) && defined(__ios__)
BLEDebugTextView* LinkManager::openDebugView(){
    if (bledebugview==NULL) {
        
    
        bledebugview = new BLEDebugTextView();
    }
    
    return bledebugview;

}
#endif

/*
bool LinkManager::connectAll()
{
    if (_connectionsSuspendedMsg()) {
        return false;
    }

    bool allConnected = true;
//=======
    _mavlinkProtocol->resetMetadataForLink(link);

    connect(link, &LinkInterface::connected,            this, &LinkManager::_linkConnected);
    connect(link, &LinkInterface::disconnected,         this, &LinkManager::_linkDisconnected);
//>>>>>>> upstream/master

    // This connection is queued since it will cloe the link. So we want the link emitter to return otherwise we would
    // close the link our from under itself.
    connect(link, &LinkInterface::connectionRemoved,    this, &LinkManager::_linkConnectionRemoved, Qt::QueuedConnection);
}
*/

void LinkManager::disconnectAll(void)
{
    // Walk list in reverse order to preserve indices during delete
    for (int i=_links.count()-1; i>=0; i--) {
        disconnectLink(_links.value<LinkInterface*>(i));
    }
}

bool LinkManager::connectLink(LinkInterface* link)
{
    Q_ASSERT(link);

    if (_connectionsSuspendedMsg()) {
        return false;
    }

    return link->_connect();
}

void LinkManager::disconnectLink(LinkInterface* link)
{
    if (!link || !_links.contains(link)) {
        return;
    }

    link->_disconnect();
    LinkConfiguration* config = link->getLinkConfiguration();
    if (config) {
        if (_autoconnectConfigurations.contains(config)) {
            config->setLink(NULL);
        }
    }
    _deleteLink(link);
    if (_autoconnectConfigurations.contains(config)) {
        qCDebug(LinkManagerLog) << "Removing disconnected autoconnect config" << config->name();
        _autoconnectConfigurations.removeOne(config);
        delete config;
    }
}

void LinkManager::_deleteLink(LinkInterface* link)
{
    if (thread() != QThread::currentThread()) {
        qWarning() << "_deleteLink called from incorrect thread";
        return;
    }

    if (!link) {
        return;
    }

    // Free up the mavlink channel associated with this link
    _mavlinkChannelsUsedBitMask &= ~(1 << link->getMavlinkChannel());

    _links.removeOne(link);
    delete link;

    // Emit removal of link
    emit linkDeleted(link);
}

/// @brief If all new connections should be suspended a message is displayed to the user and true
///         is returned;
bool LinkManager::_connectionsSuspendedMsg(void)
{
    if (_connectionsSuspended) {
        qgcApp()->showMessage(QString("Connect not allowed: %1").arg(_connectionsSuspendedReason));
        return true;
    } else {
        return false;
    }
}

void LinkManager::setConnectionsSuspended(QString reason)
{
    _connectionsSuspended = true;
    _connectionsSuspendedReason = reason;
    Q_ASSERT(!reason.isEmpty());
}

void LinkManager::_linkConnected(void)
{
    emit linkConnected((LinkInterface*)sender());
    #ifdef __mindskin__
          #ifdef __android__
            /*LinkInterface* link = (LinkInterface*)sender();
            LinkConfiguration* linkCfg = link->getLinkConfiguration();
            if(linkCfg->type() == LinkConfiguration::TypeTcp) {
                TCPConfiguration* tcpLinkCfg = qobject_cast<TCPConfiguration*>(linkCfg);
                QString host = tcpLinkCfg->host();
                int port = tcpLinkCfg->port();
                QAndroidJniObject jHost = QAndroidJniObject::fromString(host);
                QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "tcpConnected", "(Ljava/lang/String;I)V", jHost.object<jstring>(), port);
                cleanJavaException();
            } else {*/
                LinkInterface* link = (LinkInterface*)sender();
                LinkConfiguration* linkCfg = link->getLinkConfiguration();
                MSLog("[_linkConnected] linkType:%d",linkCfg->type());
                if(linkCfg->type() != LinkConfiguration::TypeUdp) {
                    QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "connected", "()V");
                    cleanJavaException();
                }
//            }
          #endif //__android__
    #endif
    qCDebug(LinkManagerLog) << "_linkConnected exit";
}

void LinkManager::_linkDisconnected(void)
{
    emit linkDisconnected((LinkInterface*)sender());
#ifdef __mindskin__
      #ifdef __android__
        LinkInterface *link = (LinkInterface*)sender();
        if(link != NULL) {
            LinkConfiguration *linkConfig = link->getLinkConfiguration();
            if(linkConfig != NULL) {
                if(linkConfig->type() != LinkConfiguration::TypeUdp) {
                    QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "disConnected", "()V");
                    cleanJavaException();
                }
            }
        }
      #endif //__android__
#endif
}

void LinkManager::_linkConnectionRemoved(LinkInterface* link)
{
    // Link has been removed from system, disconnect it automatically
    disconnectLink(link);
}

void LinkManager::suspendConfigurationUpdates(bool suspend)
{
    _configUpdateSuspended = suspend;
}

void LinkManager::saveLinkConfigurationList()
{
    QSettings settings;
    settings.remove(LinkConfiguration::settingsRoot());
    int trueCount = 0;
    for (int i = 0; i < _linkConfigurations.count(); i++) {
        LinkConfiguration* linkConfig = _linkConfigurations.value<LinkConfiguration*>(i);
        if (linkConfig) {
            if(!linkConfig->isDynamic())
            {
                QString root = LinkConfiguration::settingsRoot();
                root += QString("/Link%1").arg(trueCount++);
                settings.setValue(root + "/name", linkConfig->name());
                settings.setValue(root + "/type", linkConfig->type());
                settings.setValue(root + "/auto", linkConfig->isAutoConnect());
                // Have the instance save its own values
                linkConfig->saveSettings(settings, root);
            }
        } else {
            qWarning() << "Internal error for link configuration in LinkManager";
        }
    }
    QString root(LinkConfiguration::settingsRoot());
    settings.setValue(root + "/count", trueCount);
    emit linkConfigurationsChanged();
}

void LinkManager::loadLinkConfigurationList()
{
    bool linksChanged = false;
#ifdef QT_DEBUG
    bool mockPresent  = false;
#endif
    QSettings settings;
    // Is the group even there?
    if(settings.contains(LinkConfiguration::settingsRoot() + "/count")) {
        // Find out how many configurations we have
        int count = settings.value(LinkConfiguration::settingsRoot() + "/count").toInt();
        for(int i = 0; i < count; i++) {
            QString root(LinkConfiguration::settingsRoot());
            root += QString("/Link%1").arg(i);
            if(settings.contains(root + "/type")) {
                int type = settings.value(root + "/type").toInt();
                if((LinkConfiguration::LinkType)type < LinkConfiguration::TypeLast) {
                    if(settings.contains(root + "/name")) {
                        QString name = settings.value(root + "/name").toString();
                        if(!name.isEmpty()) {
                            LinkConfiguration* pLink = NULL;
                            bool autoConnect = settings.value(root + "/auto").toBool();
                            switch((LinkConfiguration::LinkType)type) {
#ifndef __ios__
                                case LinkConfiguration::TypeSerial:
                                    pLink = (LinkConfiguration*)new SerialConfiguration(name);
                                    break;
#endif
                                case LinkConfiguration::TypeUdp:
                                    pLink = (LinkConfiguration*)new UDPConfiguration(name);
                                    break;
                                case LinkConfiguration::TypeTcp:
                                    pLink = (LinkConfiguration*)new TCPConfiguration(name);
                                    break;
#ifdef QGC_ENABLE_BLUETOOTH
                                case LinkConfiguration::TypeBluetooth:
                                    pLink = (LinkConfiguration*)new BluetoothConfiguration(name);
                                    break;
#endif
#ifndef __mobile__
                                case LinkConfiguration::TypeLogReplay:
                                    pLink = (LinkConfiguration*)new LogReplayLinkConfiguration(name);
                                    break;
#endif
#ifdef QT_DEBUG
                                case LinkConfiguration::TypeMock:
                                    pLink = (LinkConfiguration*)new MockConfiguration(name);
                                    mockPresent = true;
                                    break;
#endif
                                default:
                                case LinkConfiguration::TypeLast:
                                    break;
                            }
                            if(pLink) {
                                //-- Have the instance load its own values
                                pLink->setAutoConnect(autoConnect);
                                pLink->loadSettings(settings, root);
                                _linkConfigurations.append(pLink);
                                linksChanged = true;
                            }
                        } else {
                            qWarning() << "Link Configuration" << root << "has an empty name." ;
                        }
                    } else {
                        qWarning() << "Link Configuration" << root << "has no name." ;
                    }
                } else {
                    qWarning() << "Link Configuration" << root << "an invalid type: " << type;
                }
            } else {
                qWarning() << "Link Configuration" << root << "has no type." ;
            }
        }
    }
    // Debug buids always add MockLink automatically (if one is not already there)
#ifdef QT_DEBUG
    if(!mockPresent)
    {
        MockConfiguration* pMock = new MockConfiguration("Mock Link PX4");
        pMock->setDynamic(true);
        _linkConfigurations.append(pMock);
        linksChanged = true;
    }
#endif

    if(linksChanged) {
        emit linkConfigurationsChanged();
    }
    // Enable automatic Serial PX4/3DR Radio hunting
    _configurationsLoaded = true;
}

#ifndef __ios__
SerialConfiguration* LinkManager::_autoconnectConfigurationsContainsPort(const QString& portName)
{
    QString searchPort = portName.trimmed();

    for (int i=0; i<_autoconnectConfigurations.count(); i++) {
        SerialConfiguration* linkConfig = _autoconnectConfigurations.value<SerialConfiguration*>(i);

        if (linkConfig) {
            if (linkConfig->portName() == searchPort) {
                return linkConfig;
            }
        } else {
            qWarning() << "Internal error";
        }
    }
    return NULL;
}
#endif

void LinkManager::_updateAutoConnectLinks(void)
{
    if (_connectionsSuspended || qgcApp()->runningUnitTests()) {
        return;
    }

    // Re-add UDP if we need to
    bool foundUDP = false;
    for (int i=0; i<_links.count(); i++) {
        LinkConfiguration* linkConfig = _links.value<LinkInterface*>(i)->getLinkConfiguration();
        if (linkConfig->type() == LinkConfiguration::TypeUdp && linkConfig->name() == _defaultUPDLinkName) {
            foundUDP = true;
            break;
        }
    }
    if (!foundUDP && _autoconnectUDP) {
        qCDebug(LinkManagerLog) << "New auto-connect UDP port added";
        UDPConfiguration* udpConfig = new UDPConfiguration(_defaultUPDLinkName);
        udpConfig->setLocalPort(QGC_UDP_LOCAL_PORT);
        udpConfig->setDynamic(true);
        _linkConfigurations.append(udpConfig);
        createConnectedLink(udpConfig);
        emit linkConfigurationsChanged();
    }

#ifndef __ios__
    QStringList currentPorts;
    QList<QGCSerialPortInfo> portList = QGCSerialPortInfo::availablePorts();

    // Iterate Comm Ports
    foreach (QGCSerialPortInfo portInfo, portList) {
        qCDebug(LinkManagerVerboseLog) << "-----------------------------------------------------";
        qCDebug(LinkManagerVerboseLog) << "portName:          " << portInfo.portName();
        qCDebug(LinkManagerVerboseLog) << "systemLocation:    " << portInfo.systemLocation();
        qCDebug(LinkManagerVerboseLog) << "description:       " << portInfo.description();
        qCDebug(LinkManagerVerboseLog) << "manufacturer:      " << portInfo.manufacturer();
        qCDebug(LinkManagerVerboseLog) << "serialNumber:      " << portInfo.serialNumber();
        qCDebug(LinkManagerVerboseLog) << "vendorIdentifier:  " << portInfo.vendorIdentifier();
        qCDebug(LinkManagerVerboseLog) << "productIdentifier: " << portInfo.productIdentifier();

        // Save port name
        currentPorts << portInfo.systemLocation();

        QGCSerialPortInfo::BoardType_t boardType = portInfo.boardType();

        if (boardType != QGCSerialPortInfo::BoardTypeUnknown) {
            if (portInfo.isBootloader()) {
                // Don't connect to bootloader
                qCDebug(LinkManagerLog) << "Waiting for bootloader to finish" << portInfo.systemLocation();
                continue;
            }

            if (_autoconnectConfigurationsContainsPort(portInfo.systemLocation())) {
                qCDebug(LinkManagerVerboseLog) << "Skipping existing autoconnect" << portInfo.systemLocation();
            } else if (!_autoconnectWaitList.contains(portInfo.systemLocation())) {
                // We don't connect to the port the first time we see it. The ability to correctly detect whether we
                // are in the bootloader is flaky from a cross-platform standpoint. So by putting it on a wait list
                // and only connect on the second pass we leave enough time for the board to boot up.
                qCDebug(LinkManagerLog) << "Waiting for next autoconnect pass" << portInfo.systemLocation();
                _autoconnectWaitList[portInfo.systemLocation()] = 1;
            } else if (++_autoconnectWaitList[portInfo.systemLocation()] * _autoconnectUpdateTimerMSecs > _autoconnectConnectDelayMSecs) {
                SerialConfiguration* pSerialConfig = NULL;

                _autoconnectWaitList.remove(portInfo.systemLocation());

                switch (boardType) {
                case QGCSerialPortInfo::BoardTypePX4FMUV1:
                case QGCSerialPortInfo::BoardTypePX4FMUV2:
                case QGCSerialPortInfo::BoardTypePX4FMUV4:
                    if (_autoconnectPixhawk) {
                        pSerialConfig = new SerialConfiguration(QString("Pixhawk on %1").arg(portInfo.portName().trimmed()));
                        pSerialConfig->setUsbDirect(true);
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeAeroCore:
                    if (_autoconnectPixhawk) {
                        pSerialConfig = new SerialConfiguration(QString("AeroCore on %1").arg(portInfo.portName().trimmed()));
                        pSerialConfig->setUsbDirect(true);
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeMINDPXFMUV2:
                    if (_autoconnectPixhawk) {
                        pSerialConfig = new SerialConfiguration(QString("MindPX on %1").arg(portInfo.portName().trimmed()));
                        pSerialConfig->setUsbDirect(true);
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeTAPV1:
                    if (_autoconnectPixhawk) {
                        pSerialConfig = new SerialConfiguration(QString("TAP on %1").arg(portInfo.portName().trimmed()));
                        pSerialConfig->setUsbDirect(true);
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeASCV1:
                    if (_autoconnectPixhawk) {
                        pSerialConfig = new SerialConfiguration(QString("ASC on %1").arg(portInfo.portName().trimmed()));
                        pSerialConfig->setUsbDirect(true);
                    }
                    break;
                case QGCSerialPortInfo::BoardTypePX4Flow:
                    if (_autoconnectPX4Flow) {
                        pSerialConfig = new SerialConfiguration(QString("PX4Flow on %1").arg(portInfo.portName().trimmed()));
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeSikRadio:
                    if (_autoconnect3DRRadio) {
                        pSerialConfig = new SerialConfiguration(QString("SiK Radio on %1").arg(portInfo.portName().trimmed()));
                    }
                    break;
#ifndef __mobile__
                case QGCSerialPortInfo::BoardTypeRTKGPS:
                    if (_autoconnectRTKGPS && !_toolbox->gpsManager()->connected()) {
                        qCDebug(LinkManagerLog) << "RTK GPS auto-connected";
                        _toolbox->gpsManager()->connectGPS(portInfo.systemLocation());
                    }
                    break;
#endif
                default:
                    qWarning() << "Internal error";
                    continue;
                }

                if (pSerialConfig) {
                    qCDebug(LinkManagerLog) << "New auto-connect port added: " << pSerialConfig->name() << portInfo.systemLocation();
                    pSerialConfig->setBaud(boardType == QGCSerialPortInfo::BoardTypeSikRadio ? 57600 : 115200);
                    pSerialConfig->setDynamic(true);
                    pSerialConfig->setPortName(portInfo.systemLocation());
                    _autoconnectConfigurations.append(pSerialConfig);
                    createConnectedLink(pSerialConfig);
                }
            }
        }
    }

    // Now we go through the current configuration list and make sure any dynamic config has gone away
    QList<LinkConfiguration*>  _confToDelete;
    for (int i=0; i<_autoconnectConfigurations.count(); i++) {
        SerialConfiguration* linkConfig = _autoconnectConfigurations.value<SerialConfiguration*>(i);
        if (linkConfig) {
            if (!currentPorts.contains(linkConfig->portName())) {
                if (linkConfig->link()) {
                    if (linkConfig->link()->isConnected()) {
                        if (linkConfig->link()->active()) {
                            // We don't remove links which are still connected which have been active with a vehicle on them
                            // even though at this point the cable may have been pulled. Instead we wait for the user to
                            // Disconnect. Once the user disconnects, the link will be removed.
                            continue;
                        }
                    }
                }
                _confToDelete.append(linkConfig);
            }
        } else {
            qWarning() << "Internal error";
        }
    }

    // Now remove all configs that are gone
    foreach (LinkConfiguration* pDeleteConfig, _confToDelete) {
        qCDebug(LinkManagerLog) << "Removing unused autoconnect config" << pDeleteConfig->name();
        _autoconnectConfigurations.removeOne(pDeleteConfig);
        if (pDeleteConfig->link()) {
            disconnectLink(pDeleteConfig->link());
        }
        delete pDeleteConfig;
    }
#endif // __ios__
}

void LinkManager::shutdown(void)
{
    setConnectionsSuspended("Shutdown");
    disconnectAll();
}

bool LinkManager::_setAutoconnectWorker(bool& currentAutoconnect, bool newAutoconnect, const char* autoconnectKey)
{
    if (currentAutoconnect != newAutoconnect) {
        QSettings settings;

        settings.beginGroup(_settingsGroup);
        settings.setValue(autoconnectKey, newAutoconnect);
        currentAutoconnect = newAutoconnect;
        return true;
    }

    return false;
}

void LinkManager::setAutoconnectUDP(bool autoconnect)
{
    if (_setAutoconnectWorker(_autoconnectUDP, autoconnect, _autoconnectUDPKey)) {
        emit autoconnectUDPChanged(autoconnect);
    }
}

void LinkManager::setAutoconnectPixhawk(bool autoconnect)
{
    if (_setAutoconnectWorker(_autoconnectPixhawk, autoconnect, _autoconnectPixhawkKey)) {
        emit autoconnectPixhawkChanged(autoconnect);
    }
}

void LinkManager::setAutoconnect3DRRadio(bool autoconnect)
{
    if (_setAutoconnectWorker(_autoconnect3DRRadio, autoconnect, _autoconnect3DRRadioKey)) {
        emit autoconnect3DRRadioChanged(autoconnect);
    }
}

void LinkManager::setAutoconnectPX4Flow(bool autoconnect)
{
    if (_setAutoconnectWorker(_autoconnectPX4Flow, autoconnect, _autoconnectPX4FlowKey)) {
        emit autoconnectPX4FlowChanged(autoconnect);
    }
}

void LinkManager::setAutoconnectRTKGPS(bool autoconnect)
{
    if (_setAutoconnectWorker(_autoconnectRTKGPS, autoconnect, _autoconnectRTKGPSKey)) {
        emit autoconnectRTKGPSChanged(autoconnect);
    }
}

QStringList LinkManager::linkTypeStrings(void) const
{
    //-- Must follow same order as enum LinkType in LinkConfiguration.h
    static QStringList list;
    if(!list.size())
    {
#ifndef __ios__
        list += "Serial";
#endif
#ifdef __mindskin__
        list += "Bluetooth Low Energy";  ///< Bluetooth Serial Link
#endif
        list += "UDP";
        list += "TCP";
#ifdef QGC_ENABLE_BLUETOOTH
        list += "Bluetooth";
#endif
#ifdef QT_DEBUG
        list += "Mock Link";
#endif
#ifndef __mobile__
        list += "Log Replay";
#endif
        Q_ASSERT(list.size() == (int)LinkConfiguration::TypeLast);
    }
    return list;
}

void LinkManager::_updateSerialPorts()
{
    _commPortList.clear();
    _commPortDisplayList.clear();
#ifndef __ios__
    QList<QSerialPortInfo> portList = QSerialPortInfo::availablePorts();
    foreach (const QSerialPortInfo &info, portList)
    {
        QString port = info.systemLocation().trimmed();
        _commPortList += port;
        _commPortDisplayList += SerialConfiguration::cleanPortDisplayname(port);
    }
#endif
}

QStringList LinkManager::serialPortStrings(void)
{
    if(!_commPortDisplayList.size())
    {
        _updateSerialPorts();
    }
    return _commPortDisplayList;
}

QStringList LinkManager::serialPorts(void)
{
    if(!_commPortList.size())
    {
        _updateSerialPorts();
    }
    return _commPortList;
}

QStringList LinkManager::serialBaudRates(void)
{
#ifdef __ios__
    QStringList foo;
    return foo;
#else
    return SerialConfiguration::supportedBaudRates();
#endif
}

bool LinkManager::endConfigurationEditing(LinkConfiguration* config, LinkConfiguration* editedConfig)
{
    Q_ASSERT(config != NULL);
    Q_ASSERT(editedConfig != NULL);
    _fixUnnamed(editedConfig);
    config->copyFrom(editedConfig);
    saveLinkConfigurationList();
    // Tell link about changes (if any)
    config->updateSettings();
    // Discard temporary duplicate
    delete editedConfig;
    return true;
}

bool LinkManager::endCreateConfiguration(LinkConfiguration* config)
{
    Q_ASSERT(config != NULL);
    _fixUnnamed(config);
    _linkConfigurations.append(config);
    saveLinkConfigurationList();
    return true;
}

LinkConfiguration* LinkManager::createConfiguration(int type, const QString& name)
{
#ifndef __ios__
    if((LinkConfiguration::LinkType)type == LinkConfiguration::TypeSerial)
        _updateSerialPorts();
#endif
    return LinkConfiguration::createSettings(type, name);
}

LinkConfiguration* LinkManager::startConfigurationEditing(LinkConfiguration* config)
{
    Q_ASSERT(config != NULL);
#ifndef __ios__
    if(config->type() == LinkConfiguration::TypeSerial)
        _updateSerialPorts();
#endif
    return LinkConfiguration::duplicateSettings(config);
}


void LinkManager::_fixUnnamed(LinkConfiguration* config)
{
    Q_ASSERT(config != NULL);
    //-- Check for "Unnamed"
    if (config->name() == "Unnamed") {
        switch(config->type()) {
#ifndef __ios__
            case LinkConfiguration::TypeSerial: {
                QString tname = dynamic_cast<SerialConfiguration*>(config)->portName();
#ifdef Q_OS_WIN
                tname.replace("\\\\.\\", "");
#else
                tname.replace("/dev/cu.", "");
                tname.replace("/dev/", "");
#endif
                config->setName(QString("Serial Device on %1").arg(tname));
                break;
                }
#endif
            case LinkConfiguration::TypeUdp:
                config->setName(
                    QString("UDP Link on Port %1").arg(dynamic_cast<UDPConfiguration*>(config)->localPort()));
                break;
            case LinkConfiguration::TypeTcp: {
                    TCPConfiguration* tconfig = dynamic_cast<TCPConfiguration*>(config);
                    if(tconfig) {
                        config->setName(
                            QString("TCP Link %1:%2").arg(tconfig->address().toString()).arg((int)tconfig->port()));
                    }
                }
                break;
#ifdef QGC_ENABLE_BLUETOOTH
            case LinkConfiguration::TypeBluetooth: {
                    BluetoothConfiguration* tconfig = dynamic_cast<BluetoothConfiguration*>(config);
                    if(tconfig) {
                        config->setName(QString("%1 (Bluetooth Device)").arg(tconfig->device().name));
                    }
                }
                break;
#endif
#ifndef __mobile__
            case LinkConfiguration::TypeLogReplay: {
                    LogReplayLinkConfiguration* tconfig = dynamic_cast<LogReplayLinkConfiguration*>(config);
                    if(tconfig) {
                        config->setName(QString("Log Replay %1").arg(tconfig->logFilenameShort()));
                    }
                }
                break;
#endif
#ifdef QT_DEBUG
            case LinkConfiguration::TypeMock:
                config->setName(
                    QString("Mock Link"));
                break;
#endif
            case LinkConfiguration::TypeLast:
            default:
                break;
        }
    }
}

void LinkManager::removeConfiguration(LinkConfiguration* config)
{
    Q_ASSERT(config != NULL);
    LinkInterface* iface = config->link();
    if(iface) {
        disconnectLink(iface);
    }
    // Remove configuration
    _linkConfigurations.removeOne(config);
    delete config;
    // Save list
    saveLinkConfigurationList();
}

bool LinkManager::isAutoconnectLink(LinkInterface* link)
{
    return _autoconnectConfigurations.contains(link->getLinkConfiguration());
}

bool LinkManager::isBluetoothAvailable(void)
{
    return qgcApp()->isBluetoothAvailable();
}

#ifndef __ios__
void LinkManager::_activeLinkCheck(void)
{
    SerialLink* link = NULL;
    bool found = false;

    if (_activeLinkCheckList.count() != 0) {
        link = _activeLinkCheckList.takeFirst();
        if (_links.contains(link) && link->isConnected()) {
            // Make sure there is a vehicle on the link
            QmlObjectListModel* vehicles = _toolbox->multiVehicleManager()->vehicles();
            for (int i=0; i<vehicles->count(); i++) {
                Vehicle* vehicle = qobject_cast<Vehicle*>(vehicles->get(i));
                if (vehicle->containsLink(link)) {
                    found = true;
                    break;
                }
            }
        } else {
            link = NULL;
        }
    }

    if (_activeLinkCheckList.count() == 0) {
        _activeLinkCheckTimer.stop();
    }

    if (!found && link) {
        // See if we can get an NSH prompt on this link
        bool foundNSHPrompt = false;
        link->writeBytesSafe("\r", 1);
        QSignalSpy spy(link, SIGNAL(bytesReceived(LinkInterface*, QByteArray)));
        if (spy.wait(100)) {
            QList<QVariant> arguments = spy.takeFirst();
            if (arguments[1].value<QByteArray>().contains("nsh>")) {
                foundNSHPrompt = true;
            }
        }

        qgcApp()->showMessage(foundNSHPrompt ?
                                  QStringLiteral("Please check to make sure you have an SD Card inserted in your Vehicle and try again.") :
                                  QStringLiteral("Your Vehicle is not responding. If this continues shutdown QGroundControl, restart the Vehicle letting it boot completely, then start QGroundControl."));
    }
}
#endif
