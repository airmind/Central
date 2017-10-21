/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include <QList>
#include <QApplication>
#include <QDebug>
#include <QSignalSpy>

#ifndef NO_SERIAL_LINK
#include "QGCSerialPortInfo.h"
#endif

#include "LinkManager.h"
#include "QGCApplication.h"
#include "UDPLink.h"
#include "TCPLink.h"
#include "SettingsManager.h"
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

const char* LinkManager::_defaultUPDLinkName =       "UDP Link (AutoConnect)";

const int LinkManager::_autoconnectUpdateTimerMSecs =   1000;
#ifdef Q_OS_WIN
// Have to manually let the bootloader go by on Windows to get a working connect
const int LinkManager::_autoconnectConnectDelayMSecs =  6000;
#else
const int LinkManager::_autoconnectConnectDelayMSecs =  1000;
#endif

LinkManager::LinkManager(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
    , _configUpdateSuspended(false)
    , _configurationsLoaded(false)
    , _connectionsSuspended(false)
    , _mavlinkChannelsUsedBitMask(1)    // We never use channel 0 to avoid sequence numbering problems
    , _autoConnectSettings(NULL)
    , _mavlinkProtocol(NULL)
{
    qmlRegisterUncreatableType<LinkManager>         ("QGroundControl", 1, 0, "LinkManager",         "Reference only");
    qmlRegisterUncreatableType<LinkConfiguration>   ("QGroundControl", 1, 0, "LinkConfiguration",   "Reference only");
    qmlRegisterUncreatableType<LinkInterface>       ("QGroundControl", 1, 0, "LinkInterface",       "Reference only");

    QSettings settings;

    settings.beginGroup(_settingsGroup);
    _autoconnectUDP =       settings.value(_autoconnectUDPKey, true).toBool();
    qDebug() << "[LinkManager] _autoconnectUDP:" << _autoconnectUDP;
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
    static bool isUDP = true;
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
            //tcp-link
            if(!isUDP) {
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
            } else {
                qDebug() << "[processPendingDatagrams] auto-connected UDP socket will handle connection to this host";
            }

            //udp-link
//            QString linkConfigName = QString::asprintf("%s-%s-%d","udp",sHost.data(), tcpLinkIndex++);
//            UDPConfiguration* udpConfig = new UDPConfiguration(linkConfigName);
//            udpConfig->setLocalPort(QGC_UDP_LOCAL_PORT);
//            udpConfig->setDynamic(true);
//            _linkConfigurations.append(udpConfig);
//            createConnectedLink(udpConfig);
        }
    }
}
#endif

void LinkManager::setToolbox(QGCToolbox *toolbox)
{
    QGCTool::setToolbox(toolbox);

    _autoConnectSettings = toolbox->settingsManager()->autoConnectSettings();
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
    qDebug()<<"LinkManager: updating ble link rssi \n";
    
    for (int i=0; i<peripheral_link_list->count(); i++) {
        QString pname = peripheral_link_list->at(i);
        int rssi = blehelper->currentFilteredPeripheralRSSI(pname);
        qDebug()<<"LinkManager: current rssi " << rssi << "\n";

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
                    qDebug()<<"back into range \n";

                    //signal all links belong to this peripheral going active;
                    for (int j=0; j<_blelinks.count(); j++) {
                        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(j);
                        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
                        blink->setLinkRSSI(rssi);
                        Q_ASSERT(cfg);
                        
                        if (cfg->getBLEPeripheralIdentifier() == peripheral_link_list->at(j)) {
                            //emit get into range signal;
                            emit radioLinkGetIntoRange(blink, rssi);
                        }
                    }

                }
                break;
            case BLE_LINK_QUALITY_ALERT:
                if (lq == BLE_LINK_QUALITY_OUTOFRANGE) {
                    qDebug()<<"getting into range \n";
                   
                    //signal all links belong to this peripheral going active;
                    for (int j=0; j<_blelinks.count(); j++) {
                        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(j);
                        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
                        blink->setLinkRSSI(rssi);

                        Q_ASSERT(cfg);
                        
                        if (cfg->getBLEPeripheralIdentifier() == peripheral_link_list->at(j)) {
                            //emit get into range signal;
                            emit radioLinkGetIntoRange(blink, rssi);
                        }
                    }

                }
                break;
            case BLE_LINK_QUALITY_OUTOFRANGE:
                if (lq == BLE_LINK_QUALITY_ALERT || lq == BLE_LINK_QUALITY_INRANGE) {
                    qDebug()<<"out of range \n";

                    //signal all links belong to this peripheral going inactive;
                    for (int j=0; j<_blelinks.count(); j++) {
                        BTSerialLink* blink = _bletriallinks.value<BTSerialLink*>(j);
                        BTSerialConfiguration* cfg = blink->getLinkConfiguration();
                        blink->setLinkRSSI(rssi);

                        Q_ASSERT(cfg);
                        
                        if (cfg->getBLEPeripheralIdentifier() == peripheral_link_list->at(j)) {
                            ////emit out of range signal;
                            emit radioLinkOutOfRange(blink, rssi);
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
    if (!config) {
        qWarning() << "LinkManager::createConnectedLink called with NULL config";
        return NULL;
    }

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
    }
        break;
#endif
    case LinkConfiguration::TypeUdp:
        pLink = new UDPLink(config);
        break;
    case LinkConfiguration::TypeTcp:
        pLink = new TCPLink(config);
        break;
#ifdef QGC_ENABLE_BLUETOOTH
    case LinkConfiguration::TypeBluetooth:
        pLink = new BluetoothLink(config);
        break;
#endif
#ifndef __mobile__
    case LinkConfiguration::TypeLogReplay:
        pLink = new LogReplayLink(config);
        break;
#endif
#ifdef QT_DEBUG
    case LinkConfiguration::TypeMock:
        pLink = new MockLink(config);
        break;
#endif
    case LinkConfiguration::TypeLast:
    default:
        break;
    }

    if (pLink) {
        _addLink(pLink);
        connectLink(pLink);
    }

    return pLink;
}

LinkInterface* LinkManager::createConnectedLink(const QString& name)
{
    if (name.isEmpty()) {
        qWarning() << "Internal error";
    } else {
        for(int i = 0; i < _sharedConfigurations.count(); i++) {
            SharedLinkConfigurationPointer& conf = _sharedConfigurations[i];
            if (conf->name() == name) {
                return createConnectedLink(conf);
            }
        }
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

    if (!containsLink(link)) {
        int mavlinkChannel = _reserveMavlinkChannel();
        if (mavlinkChannel != 0) {
            link->_setMavlinkChannel(mavlinkChannel);
        } else {
            qWarning() << "Ran out of mavlink channels";
            return;
        }

        _sharedLinks.append(SharedLinkInterfacePointer(link));
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
    _mavlinkProtocol->setVersion(_mavlinkProtocol->getCurrentVersion());

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
    for (int i=_sharedLinks.count()-1; i>=0; i--) {
        disconnectLink(_sharedLinks[i].data());
    }
}

bool LinkManager::connectLink(LinkInterface* link)
{
    if (link) {
        if (_connectionsSuspendedMsg()) {
            return false;
        }
        return link->_connect();
    } else {
        qWarning() << "Internal error";
        return false;
    }
}

void LinkManager::disconnectLink(LinkInterface* link)
{
    if (!link || !containsLink(link)) {
        return;
    }

    link->_disconnect();

    LinkConfiguration* config = link->getLinkConfiguration();
    for (int i=0; i<_sharedAutoconnectConfigurations.count(); i++) {
        if (_sharedAutoconnectConfigurations[i].data() == config) {
            qCDebug(LinkManagerLog) << "Removing disconnected autoconnect config" << config->name();
            _sharedAutoconnectConfigurations.removeAt(i);
            break;
        }
    }

    _deleteLink(link);
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
    _freeMavlinkChannel(link->mavlinkChannel());

    for (int i=0; i<_sharedLinks.count(); i++) {
        if (_sharedLinks[i].data() == link) {
            _sharedLinks.removeAt(i);
            break;
        }
    }

    // Emit removal of link
    emit linkDeleted(link);
}

SharedLinkInterfacePointer LinkManager::sharedLinkInterfacePointerForLink(LinkInterface* link)
{
    for (int i=0; i<_sharedLinks.count(); i++) {
        if (_sharedLinks[i].data() == link) {
            return _sharedLinks[i];
        }
    }

    qWarning() << "LinkManager::sharedLinkInterfaceForLink returning NULL";
    return SharedLinkInterfacePointer(NULL);
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
}

void LinkManager::_linkConnected(void)
{
    emit linkConnected((LinkInterface*)sender());
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
//                if(linkConfig->type() != LinkConfiguration::TypeUdp) {
                    MSLog("[_linkDisconnected] %s",linkConfig->name().toLatin1().data());
                    QAndroidJniObject jLinkConfigName = QAndroidJniObject::fromString(linkConfig->name());
                    QAndroidJniObject::callStaticMethod<void>( "org/airmind/ble/LinkManager", "disConnected", "(Ljava/lang/String;)V",jLinkConfigName.object<jstring>());
                    cleanJavaException();
//                }
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
    for (int i = 0; i < _sharedConfigurations.count(); i++) {
        SharedLinkConfigurationPointer linkConfig = _sharedConfigurations[i];
        if (linkConfig) {
            if (!linkConfig->isDynamic()) {
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
#ifndef NO_SERIAL_LINK
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
                                addConfiguration(pLink);
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

    if(linksChanged) {
        emit linkConfigurationsChanged();
    }
    // Enable automatic Serial PX4/3DR Radio hunting
    _configurationsLoaded = true;
}

#ifndef NO_SERIAL_LINK
SerialConfiguration* LinkManager::_autoconnectConfigurationsContainsPort(const QString& portName)
{
    QString searchPort = portName.trimmed();

    for (int i=0; i<_sharedAutoconnectConfigurations.count(); i++) {
        SerialConfiguration* serialConfig = qobject_cast<SerialConfiguration*>(_sharedAutoconnectConfigurations[i].data());

        if (serialConfig) {
            if (serialConfig->portName() == searchPort) {
                return serialConfig;
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
    for (int i=0; i<_sharedLinks.count(); i++) {
        LinkConfiguration* linkConfig = _sharedLinks[i]->getLinkConfiguration();
        if (linkConfig->type() == LinkConfiguration::TypeUdp && linkConfig->name() == _defaultUPDLinkName) {
            foundUDP = true;
            break;
        }
    }
//    qDebug() << "[_updateAutoConnectLinks] foundUDP:" << foundUDP << ", _autoconnectUDP:" << _autoconnectUDP;
    if (!foundUDP && _autoconnectUDP) {
//        qCDebug(LinkManagerLog) << "New auto-connect UDP port added";
        qDebug() << "[_updateAutoConnectLinks] New auto-connect UDP port added";
        UDPConfiguration* udpConfig = new UDPConfiguration(_defaultUPDLinkName);
        udpConfig->setDynamic(true);
        SharedLinkConfigurationPointer config = addConfiguration(udpConfig);
        createConnectedLink(config);
        emit linkConfigurationsChanged();
    }

#ifndef NO_SERIAL_LINK
    QStringList currentPorts;
    QList<QGCSerialPortInfo> portList;

#ifdef __android__
    // Android builds only support a single serial connection. Repeatedly calling availablePorts after that one serial
    // port is connected leaks file handles due to a bug somewhere in android serial code. In order to work around that
    // bug after we connect the first serial port we stop probing for additional ports.
    if (!_sharedAutoconnectConfigurations.count()) {
        portList = QGCSerialPortInfo::availablePorts();
    }
#else
    portList = QGCSerialPortInfo::availablePorts();
#endif

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

        QGCSerialPortInfo::BoardType_t boardType;
        QString boardName;

        if (portInfo.getBoardInfo(boardType, boardName)) {
            if (portInfo.isBootloader()) {
                // Don't connect to bootloader
                qCDebug(LinkManagerLog) << "Waiting for bootloader to finish" << portInfo.systemLocation();
                continue;
            }

            if (_autoconnectConfigurationsContainsPort(portInfo.systemLocation()) || _autoConnectRTKPort == portInfo.systemLocation()) {
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
                case QGCSerialPortInfo::BoardTypePixhawk:
                    if (_autoConnectSettings->autoConnectPixhawk()->rawValue().toBool()) {
                        pSerialConfig = new SerialConfiguration(tr("%1 on %2 (AutoConnect)").arg(boardName).arg(portInfo.portName().trimmed()));
                        pSerialConfig->setUsbDirect(true);
                    }
                    break;
                case QGCSerialPortInfo::BoardTypePX4Flow:
                    if (_autoConnectSettings->autoConnectPX4Flow()->rawValue().toBool()) {
                        pSerialConfig = new SerialConfiguration(tr("%1 on %2 (AutoConnect)").arg(boardName).arg(portInfo.portName().trimmed()));
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeSiKRadio:
                    if (_autoConnectSettings->autoConnectSiKRadio()->rawValue().toBool()) {
                        pSerialConfig = new SerialConfiguration(tr("%1 on %2 (AutoConnect)").arg(boardName).arg(portInfo.portName().trimmed()));
                    }
                    break;
                case QGCSerialPortInfo::BoardTypeOpenPilot:
                    if (_autoConnectSettings->autoConnectLibrePilot()->rawValue().toBool()) {
                        pSerialConfig = new SerialConfiguration(tr("%1 on %2 (AutoConnect)").arg(boardName).arg(portInfo.portName().trimmed()));
                    }
                    break;
#ifndef __mobile__
                case QGCSerialPortInfo::BoardTypeRTKGPS:
                    if (_autoConnectSettings->autoConnectRTKGPS()->rawValue().toBool() && !_toolbox->gpsManager()->connected()) {
                        qCDebug(LinkManagerLog) << "RTK GPS auto-connected" << portInfo.portName().trimmed();
                        _autoConnectRTKPort = portInfo.systemLocation();
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
                    pSerialConfig->setBaud(boardType == QGCSerialPortInfo::BoardTypeSiKRadio ? 57600 : 115200);
                    pSerialConfig->setDynamic(true);
                    pSerialConfig->setPortName(portInfo.systemLocation());
                    _sharedAutoconnectConfigurations.append(SharedLinkConfigurationPointer(pSerialConfig));
                    createConnectedLink(_sharedAutoconnectConfigurations.last());
                }
            }
        }
    }

#ifndef __android__
    // Android builds only support a single serial connection. Repeatedly calling availablePorts after that one serial
    // port is connected leaks file handles due to a bug somewhere in android serial code. In order to work around that
    // bug after we connect the first serial port we stop probing for additional ports. The means we must rely on
    // the port disconnecting itself when the radio is pulled to signal communication list as opposed to automatically
    // closing the Link.

    // Now we go through the current configuration list and make sure any dynamic config has gone away
    QList<LinkConfiguration*>  _confToDelete;
    for (int i=0; i<_sharedAutoconnectConfigurations.count(); i++) {
        SerialConfiguration* serialConfig = qobject_cast<SerialConfiguration*>(_sharedAutoconnectConfigurations[i].data());
        if (serialConfig) {
            if (!currentPorts.contains(serialConfig->portName())) {
                if (serialConfig->link()) {
                    if (serialConfig->link()->isConnected()) {
                        if (serialConfig->link()->active()) {
                            // We don't remove links which are still connected which have been active with a vehicle on them
                            // even though at this point the cable may have been pulled. Instead we wait for the user to
                            // Disconnect. Once the user disconnects, the link will be removed.
                            continue;
                        }
                    }
                }
                _confToDelete.append(serialConfig);
            }
        } else {
            qWarning() << "Internal error";
        }
    }

    // Now remove all configs that are gone
    foreach (LinkConfiguration* pDeleteConfig, _confToDelete) {
        qCDebug(LinkManagerLog) << "Removing unused autoconnect config" << pDeleteConfig->name();
        if (pDeleteConfig->link()) {
            disconnectLink(pDeleteConfig->link());
        }
        for (int i=0; i<_sharedAutoconnectConfigurations.count(); i++) {
            if (_sharedAutoconnectConfigurations[i].data() == pDeleteConfig) {
                _sharedAutoconnectConfigurations.removeAt(i);
                break;
            }
        }
    }

    // Check for RTK GPS connection gone
    if (!_autoConnectRTKPort.isEmpty() && !currentPorts.contains(_autoConnectRTKPort)) {
        qCDebug(LinkManagerLog) << "RTK GPS disconnected" << _autoConnectRTKPort;
        _toolbox->gpsManager()->disconnectGPS();
        _autoConnectRTKPort.clear();
    }

#endif
#endif // NO_SERIAL_LINK
}

void LinkManager::shutdown(void)
{
    setConnectionsSuspended("Shutdown");
    disconnectAll();
}

QStringList LinkManager::linkTypeStrings(void) const
{
    //-- Must follow same order as enum LinkType in LinkConfiguration.h
    static QStringList list;
    if(!list.size())
    {
#ifndef NO_SERIAL_LINK
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
        if (list.size() != (int)LinkConfiguration::TypeLast) {
            qWarning() << "Internal error";
        }
    }
    return list;
}

void LinkManager::_updateSerialPorts()
{
    _commPortList.clear();
    _commPortDisplayList.clear();
#ifndef NO_SERIAL_LINK
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
#ifdef NO_SERIAL_LINK
    QStringList foo;
    return foo;
#else
    return SerialConfiguration::supportedBaudRates();
#endif
}

bool LinkManager::endConfigurationEditing(LinkConfiguration* config, LinkConfiguration* editedConfig)
{
    if (config && editedConfig) {
        _fixUnnamed(editedConfig);
        config->copyFrom(editedConfig);
        saveLinkConfigurationList();
        // Tell link about changes (if any)
        config->updateSettings();
        // Discard temporary duplicate
        delete editedConfig;
    } else {
        qWarning() << "Internal error";
    }
    return true;
}

bool LinkManager::endCreateConfiguration(LinkConfiguration* config)
{
    if (config) {
        _fixUnnamed(config);
        addConfiguration(config);
        saveLinkConfigurationList();
    } else {
        qWarning() << "Internal error";
    }
    return true;
}

LinkConfiguration* LinkManager::createConfiguration(int type, const QString& name)
{
#ifndef NO_SERIAL_LINK
    if((LinkConfiguration::LinkType)type == LinkConfiguration::TypeSerial)
        _updateSerialPorts();
#endif
    return LinkConfiguration::createSettings(type, name);
}

LinkConfiguration* LinkManager::startConfigurationEditing(LinkConfiguration* config)
{
    if (config) {
#ifndef NO_SERIAL_LINK
        if(config->type() == LinkConfiguration::TypeSerial)
            _updateSerialPorts();
#endif
        return LinkConfiguration::duplicateSettings(config);
    } else {
        qWarning() << "Internal error";
        return NULL;
    }
}


void LinkManager::_fixUnnamed(LinkConfiguration* config)
{
    if (config) {
        //-- Check for "Unnamed"
        if (config->name() == "Unnamed") {
            switch(config->type()) {
#ifndef NO_SERIAL_LINK
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
    } else {
        qWarning() << "Internal error";
    }
}

void LinkManager::removeConfiguration(LinkConfiguration* config)
{
    if (config) {
        LinkInterface* iface = config->link();
        if(iface) {
            disconnectLink(iface);
        }

        _removeConfiguration(config);
        saveLinkConfigurationList();
    } else {
        qWarning() << "Internal error";
    }
}

bool LinkManager::isAutoconnectLink(LinkInterface* link)
{
    for (int i=0; i<_sharedAutoconnectConfigurations.count(); i++) {
        if (_sharedAutoconnectConfigurations[i].data() == link->getLinkConfiguration()) {
            return true;
        }
    }
    return false;
}

bool LinkManager::isBluetoothAvailable(void)
{
    return qgcApp()->isBluetoothAvailable();
}

#ifndef NO_SERIAL_LINK
void LinkManager::_activeLinkCheck(void)
{
    SerialLink* link = NULL;
    bool found = false;

    if (_activeLinkCheckList.count() != 0) {
        link = _activeLinkCheckList.takeFirst();
        if (containsLink(link) && link->isConnected()) {
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
                                  tr("Please check to make sure you have an SD Card inserted in your Vehicle and try again.") :
                                  tr("Your Vehicle is not responding. If this continues, shutdown %1, restart the Vehicle letting it boot completely, then start %1.").arg(qgcApp()->applicationName()));
    }
}
#endif

bool LinkManager::containsLink(LinkInterface* link)
{
    for (int i=0; i<_sharedLinks.count(); i++) {
        if (_sharedLinks[i].data() == link) {
            return true;
        }
    }
    return false;
}

SharedLinkConfigurationPointer LinkManager::addConfiguration(LinkConfiguration* config)
{
    _qmlConfigurations.append(config);
    _sharedConfigurations.append(SharedLinkConfigurationPointer(config));
    return _sharedConfigurations.last();
}

void LinkManager::_removeConfiguration(LinkConfiguration* config)
{
    _qmlConfigurations.removeOne(config);

    for (int i=0; i<_sharedConfigurations.count(); i++) {
        if (_sharedConfigurations[i].data() == config) {
            _sharedConfigurations.removeAt(i);
            return;
        }
    }

    qWarning() << "LinkManager::_removeConfiguration called with unknown config";
}

QList<LinkInterface*> LinkManager::links(void)
{
    QList<LinkInterface*> rawLinks;

    for (int i=0; i<_sharedLinks.count(); i++) {
        rawLinks.append(_sharedLinks[i].data());
    }

    return rawLinks;
}

void LinkManager::startAutoConnectedLinks(void)
{
    SharedLinkConfigurationPointer conf;

    for(int i = 0; i < _sharedConfigurations.count(); i++) {
        conf = _sharedConfigurations[i];
        if (conf->isAutoConnect())
            createConnectedLink(conf);
    }
}

int LinkManager::_reserveMavlinkChannel(void)
{
    // Find a mavlink channel to use for this link, Channel 0 is reserved for internal use.
    for (int mavlinkChannel=1; mavlinkChannel<32; mavlinkChannel++) {
        if (!(_mavlinkChannelsUsedBitMask & 1 << mavlinkChannel)) {
            mavlink_reset_channel_status(mavlinkChannel);
            // Start the channel on Mav 1 protocol
            mavlink_status_t* mavlinkStatus = mavlink_get_channel_status(mavlinkChannel);
            mavlinkStatus->flags |= MAVLINK_STATUS_FLAG_OUT_MAVLINK1;
            _mavlinkChannelsUsedBitMask |= 1 << mavlinkChannel;
            return mavlinkChannel;
        }
    }

    return 0;   // All channels reserved
}

void LinkManager::_freeMavlinkChannel(int channel)
{
    _mavlinkChannelsUsedBitMask &= ~(1 << channel);
}
