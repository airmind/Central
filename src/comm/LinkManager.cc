/*=====================================================================

QGroundControl Open Source Ground Control Station

(c) 2009, 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

This file is part of the QGROUNDCONTROL project

    QGROUNDCONTROL is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    QGROUNDCONTROL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.

======================================================================*/

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

#ifndef __ios__
#include "QGCSerialPortInfo.h"
#endif

#include "LinkManager.h"
#include "MainWindow.h"
#include "QGCMessageBox.h"
#include "QGCApplication.h"
#include "QGCApplication.h"

QGC_LOGGING_CATEGORY(LinkManagerLog, "LinkManagerLog")

LinkManager::LinkManager(QGCApplication* app)
    : QGCTool(app)
    , _configUpdateSuspended(false)
    , _configurationsLoaded(false)
    , _connectionsSuspended(false)
    , _mavlinkChannelsUsedBitMask(0)
    , _nullSharedLink(NULL)
    , _mavlinkProtocol(NULL)
{

}

LinkManager::~LinkManager()
{
    // Clear configuration list
    while(_linkConfigurations.count()) {
        LinkConfiguration* pLink = _linkConfigurations.at(0);
        if(pLink) delete pLink;
        _linkConfigurations.removeAt(0);
    }
    Q_ASSERT_X(_links.count() == 0, "LinkManager", "LinkManager::_shutdown should have been called previously");
#ifdef __ios__
    delete blehelper;
#endif
}

void LinkManager::setToolbox(QGCToolbox *toolbox)
{
   QGCTool::setToolbox(toolbox);

   _mavlinkProtocol = _toolbox->mavlinkProtocol();

#ifndef __ios__
    connect(&_portListTimer, &QTimer::timeout, this, &LinkManager::_updateConfigurationList);
    _portListTimer.start(1000);
#endif
}

#ifdef __ios__
//for BT LE;
bool LinkManager::discoverBTLinks(void* delegate) {
    if (blehelper == NULL) {
        //create blehelper object;
        blehelper = new BLEHelper();
    }
    blehelper->discover(delegate);
}

bool LinkManager::stopScanning() {
    blehelper->stopScanning();
}

void LinkManager::setCallbackDelegate(void* delegate) {
    if(blehelper==NULL) {
        blehelper = new BLEHelper();
    }
    blehelper->setCallbackDelegate(delegate);
}

BTSerialLink* LinkManager::createConnectedBLELink(BTSerialConfiguration* config){
    BTSerialLink* blelink = new BTSerialLink((BTSerialConfiguration*)config, _mavlinkProtocol);
    
    if(blelink) {
        _addLink(blelink);
    
        blelink->_connect();
    
    }
    
    return blelink;

}


BTSerialLink* LinkManager::createConnectedBLELink(const QString& identifier){
    
    //BTSerialLink* blelink = new BTSerialLink(identifier);
    //blelink->_connect();
}

BTSerialLink* LinkManager::getBLELinkByConfiguration(BTSerialConfiguration* cfg) {
    
}

bool LinkManager::connectBLELink(BTSerialLink* link) {
    
}

bool LinkManager::disconnectBLELink(BTSerialLink* link) {
    
}



//mew signal - have a try;
void LinkManager::didDiscoverBLELinks(void* inrangelist, void* outrangelist) {
    //inrangelist/outrangelist have platform dependent types so can not use directly in implementation. needs type conversion.
    emit peripheralsDiscovered(inrangelist, outrangelist);
}


void LinkManager::didConnectBLELink(BTSerialLink* blelink) {
    emit linkConnected(blelink);

}

void LinkManager::didDisconnectBLELink(BTSerialLink* blelink) {
    emit linkDisconnected(blelink);
}


#endif

LinkInterface* LinkManager::createConnectedLink(LinkConfiguration* config)
{
    Q_ASSERT(config);
    LinkInterface* pLink = NULL;
    switch(config->type()) {
#ifndef __ios__
        case LinkConfiguration::TypeSerial:
            pLink = new SerialLink(dynamic_cast<SerialConfiguration*>(config));
            break;
#endif
        case LinkConfiguration::TypeUdp:
            pLink = new UDPLink(dynamic_cast<UDPConfiguration*>(config));
            break;
        case LinkConfiguration::TypeTcp:
            pLink = new TCPLink(dynamic_cast<TCPConfiguration*>(config));
            break;
        case LinkConfiguration::TypeLogReplay:
            pLink = new LogReplayLink(dynamic_cast<LogReplayLinkConfiguration*>(config));
            break;
#ifdef QT_DEBUG
        case LinkConfiguration::TypeMock:
            pLink = new MockLink(dynamic_cast<MockConfiguration*>(config));
            break;
#endif
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
        LinkConfiguration* conf = _linkConfigurations.at(i);
        if(conf && conf->name() == name)
            return createConnectedLink(conf);
    }
    return NULL;
}

void LinkManager::_addLink(LinkInterface* link)
{
    Q_ASSERT(link);

    _linkListMutex.lock();

    if (!containsLink(link)) {
        // Find a mavlink channel to use for this link
        for (int i=0; i<32; i++) {
            if (!(_mavlinkChannelsUsedBitMask && 1 << i)) {
                mavlink_reset_channel_status(i);
                link->_setMavlinkChannel(i);
                _mavlinkChannelsUsedBitMask |= i << i;
                break;
            }
        }
        
        _links.append(QSharedPointer<LinkInterface>(link));
        _linkListMutex.unlock();
        emit newLink(link);
    } else {
        _linkListMutex.unlock();
    }

    // MainWindow may be around when doing things like running unit tests
    if (MainWindow::instance()) {
        connect(link, &LinkInterface::communicationError, _app, &QGCApplication::criticalMessageBoxOnMainThread);
    }

    connect(link, &LinkInterface::bytesReceived,    _mavlinkProtocol, &MAVLinkProtocol::receiveBytes);
    connect(link, &LinkInterface::connected,        _mavlinkProtocol, &MAVLinkProtocol::linkConnected);
    connect(link, &LinkInterface::disconnected,     _mavlinkProtocol, &MAVLinkProtocol::linkDisconnected);
    _mavlinkProtocol->resetMetadataForLink(link);

    connect(link, &LinkInterface::connected,    this, &LinkManager::_linkConnected);
    connect(link, &LinkInterface::disconnected, this, &LinkManager::_linkDisconnected);
}

#ifdef __ios__


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


void LinkManager::_deleteLink(BTSerialLink* link) {
    Q_ASSERT(link);
    
    _bleLinkListMutex.lock();
    
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
    
    _bleLinkListMutex.unlock();
    
    // Emit removal of link
    emit linkDeleted(link);

}

void LinkManager::_addLink(BTSerialLink* link) {
    Q_ASSERT(link);
    
    _bleLinkListMutex.lock();
    
    if (!containsLink(link)) {
        // Find a mavlink channel to use for this link
        for (int i=0; i<32; i++) {
            if (!(_mavlinkChannelsUsedBitMask && 1 << i)) {
                mavlink_reset_channel_status(i);
                link->_setMavlinkChannel(i);
                _mavlinkChannelsUsedBitMask |= i << i;
                break;
            }
        }
        
        _blelinks.append(link);
        _bleLinkListMutex.unlock();
        //why we emit a newLink signal here but no receiving slot?
        emit newLink(link);
    } else {
        _bleLinkListMutex.unlock();
    }
    
    // MainWindow may be around when doing things like running unit tests
    if (MainWindow::instance()) {
        //connect(link, &BTSerialLink::communicationError, _app, &QGCApplication::criticalMessageBoxOnMainThread);
    }
    
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

bool LinkManager::connectAll()
{
    if (_connectionsSuspendedMsg()) {
        return false;
    }

    bool allConnected = true;

    foreach (SharedLinkInterface sharedLink, _links) {
        Q_ASSERT(sharedLink.data());
        if (!sharedLink.data()->_connect()) {
            allConnected = false;
        }
    }

    return allConnected;
}

bool LinkManager::disconnectAll()
{
    bool allDisconnected = true;

    // Make a copy so the list is modified out from under us
    QList<SharedLinkInterface> links = _links;

    foreach (SharedLinkInterface sharedLink, links) {
        Q_ASSERT(sharedLink.data());
        if (!disconnectLink(sharedLink.data())) {
            allDisconnected = false;
        }
    }

    return allDisconnected;
}

bool LinkManager::connectLink(LinkInterface* link)
{
    Q_ASSERT(link);

    if (_connectionsSuspendedMsg()) {
        return false;
    }

    if (link->_connect()) {
        return true;
    } else {
        return false;
    }
}

bool LinkManager::disconnectLink(LinkInterface* link)
{
    Q_ASSERT(link);
    if (link->_disconnect()) {
        LinkConfiguration* config = link->getLinkConfiguration();
        if(config) {
            config->setLink(NULL);
        }
        _deleteLink(link);
        return true;
    } else {
        return false;
    }
}

void LinkManager::_deleteLink(LinkInterface* link)
{
    Q_ASSERT(link);

    _linkListMutex.lock();
    
    // Free up the mavlink channel associated with this link
    _mavlinkChannelsUsedBitMask &= ~(1 << link->getMavlinkChannel());

    bool found = false;
    for (int i=0; i<_links.count(); i++) {
        if (_links[i].data() == link) {
            _links.removeAt(i);
            found = true;
            break;
        }
    }
    Q_UNUSED(found);
    Q_ASSERT(found);

    _linkListMutex.unlock();

    // Emit removal of link
    emit linkDeleted(link);
}

/**
 *
 */
const QList<LinkInterface*> LinkManager::getLinks()
{
    QList<LinkInterface*> list;
    
    foreach (SharedLinkInterface sharedLink, _links) {
        list << sharedLink.data();
    }
    
    return list;
}

/// @brief If all new connections should be suspended a message is displayed to the user and true
///         is returned;
bool LinkManager::_connectionsSuspendedMsg(void)
{
    if (_connectionsSuspended) {
        QGCMessageBox::information(tr("Connect not allowed"),
                                   tr("Connect not allowed: %1").arg(_connectionsSuspendedReason));
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

void LinkManager::_shutdown(void)
{
    while (_links.count() != 0) {
        disconnectLink(_links[0].data());
    }
}

void LinkManager::_linkConnected(void)
{
    emit linkConnected((LinkInterface*)sender());
}

void LinkManager::_linkDisconnected(void)
{
    emit linkDisconnected((LinkInterface*)sender());
}

void LinkManager::addLinkConfiguration(LinkConfiguration* link)
{
    Q_ASSERT(link != NULL);
    //-- If not there already, add it
    int idx = _linkConfigurations.indexOf(link);
    if(idx < 0)
    {
        _linkConfigurations.append(link);
    }
}

void LinkManager::removeLinkConfiguration(LinkConfiguration *link)
{
    Q_ASSERT(link != NULL);
    int idx = _linkConfigurations.indexOf(link);
    if(idx >= 0)
    {
        _linkConfigurations.removeAt(idx);
        delete link;
    }
}

const QList<LinkConfiguration*> LinkManager::getLinkConfigurationList()
{
    return _linkConfigurations;
}

void LinkManager::suspendConfigurationUpdates(bool suspend)
{
    _configUpdateSuspended = suspend;
}

void LinkManager::saveLinkConfigurationList()
{
    QSettings settings;
    settings.remove(LinkConfiguration::settingsRoot());
    int index = 0;
    foreach (LinkConfiguration* pLink, _linkConfigurations) {
        Q_ASSERT(pLink != NULL);
        if(!pLink->isDynamic())
        {
            QString root = LinkConfiguration::settingsRoot();
            root += QString("/Link%1").arg(index++);
            settings.setValue(root + "/name", pLink->name());
            settings.setValue(root + "/type", pLink->type());
            settings.setValue(root + "/preferred", pLink->isPreferred());
            // Have the instance save its own values
            pLink->saveSettings(settings, root);
        }
    }
    QString root(LinkConfiguration::settingsRoot());
    settings.setValue(root + "/count", index);
    emit linkConfigurationChanged();
}

void LinkManager::loadLinkConfigurationList()
{
    bool udpExists = false;
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
                if(type < LinkConfiguration::TypeLast) {
                    if(settings.contains(root + "/name")) {
                        QString name = settings.value(root + "/name").toString();
                        if(!name.isEmpty()) {
                            bool preferred = false;
                            if(settings.contains(root + "/preferred")) {
                                preferred = settings.value(root + "/preferred").toBool();
                            }
                            LinkConfiguration* pLink = NULL;
                            switch(type) {
#ifndef __ios__
                                case LinkConfiguration::TypeSerial:
                                    pLink = (LinkConfiguration*)new SerialConfiguration(name);
                                    pLink->setPreferred(preferred);
                                    break;
#endif
                                case LinkConfiguration::TypeUdp:
                                    pLink = (LinkConfiguration*)new UDPConfiguration(name);
                                    pLink->setPreferred(preferred);
                                    break;
                                case LinkConfiguration::TypeTcp:
                                    pLink = (LinkConfiguration*)new TCPConfiguration(name);
                                    pLink->setPreferred(preferred);
                                    break;
                                case LinkConfiguration::TypeLogReplay:
                                    pLink = (LinkConfiguration*)new LogReplayLinkConfiguration(name);
                                    pLink->setPreferred(preferred);
                                    break;
#ifdef QT_DEBUG
                                case LinkConfiguration::TypeMock:
                                    pLink = (LinkConfiguration*)new MockConfiguration(name);
                                    pLink->setPreferred(false);
                                    break;
#endif
                            }
                            if(pLink) {
                                // Have the instance load its own values
                                pLink->loadSettings(settings, root);
                                addLinkConfiguration(pLink);
                                linksChanged = true;
                                // Check for UDP links
                                if(pLink->type() == LinkConfiguration::TypeUdp) {
                                    UDPConfiguration* uLink = dynamic_cast<UDPConfiguration*>(pLink);
                                    if(uLink && uLink->localPort() == QGC_UDP_LOCAL_PORT) {
                                        udpExists = true;
                                    }
                                }
                            }
                        } else {
                            qWarning() << "Link Configuration " << root << " has an empty name." ;
                        }
                    } else {
                        qWarning() << "Link Configuration " << root << " has no name." ;
                    }
                } else {
                    qWarning() << "Link Configuration " << root << " an invalid type: " << type;
                }
            } else {
                qWarning() << "Link Configuration " << root << " has no type." ;
            }
        }
    }
    
    // Debug buids always add MockLink automatically
#ifdef QT_DEBUG
    MockConfiguration* pMock = new MockConfiguration("Mock Link PX4");
    pMock->setDynamic(true);
    addLinkConfiguration(pMock);
    linksChanged = true;
#endif

    //-- If we don't have a configured UDP link, create a default one
    if(!udpExists) {
        UDPConfiguration* uLink = new UDPConfiguration("Default UDP Link");
        uLink->setLocalPort(QGC_UDP_LOCAL_PORT);
        uLink->setDynamic();
        addLinkConfiguration(uLink);
        linksChanged = true;
    }
    
    if(linksChanged) {
        emit linkConfigurationChanged();
    }
    // Enable automatic Serial PX4/3DR Radio hunting
    _configurationsLoaded = true;
}

#ifndef __ios__
SerialConfiguration* LinkManager::_findSerialConfiguration(const QString& portName)
{
    QString searchPort = portName.trimmed();
    foreach (LinkConfiguration* pLink, _linkConfigurations) {
        Q_ASSERT(pLink != NULL);
        if(pLink->type() == LinkConfiguration::TypeSerial) {
            SerialConfiguration* pSerial = dynamic_cast<SerialConfiguration*>(pLink);
            if(pSerial->portName() == searchPort) {
                return pSerial;
            }
        }
    }
    return NULL;
}
#endif

#ifndef __ios__
void LinkManager::_updateConfigurationList(void)
{
    if (_configUpdateSuspended || !_configurationsLoaded) {
        return;
    }
    bool saveList = false;
    QStringList currentPorts;
    QList<QGCSerialPortInfo> portList = QGCSerialPortInfo::availablePorts();
    // Iterate Comm Ports
    foreach (QGCSerialPortInfo portInfo, portList) {
#if 0
        // Too noisy for most logging, so turn on as needed
        qCDebug(LinkManagerLog) << "-----------------------------------------------------";
        qCDebug(LinkManagerLog) << "portName:         " << portInfo.portName();
        qCDebug(LinkManagerLog) << "systemLocation:   " << portInfo.systemLocation();
        qCDebug(LinkManagerLog) << "description:      " << portInfo.description();
        qCDebug(LinkManagerLog) << "manufacturer:     " << portInfo.manufacturer();
        qCDebug(LinkManagerLog) << "serialNumber:     " << portInfo.serialNumber();
        qCDebug(LinkManagerLog) << "vendorIdentifier: " << portInfo.vendorIdentifier();
#endif
        // Save port name
        currentPorts << portInfo.systemLocation();

        QGCSerialPortInfo::BoardType_t boardType = portInfo.boardType();

        if (boardType != QGCSerialPortInfo::BoardTypeUnknown) {
            if (portInfo.isBootloader()) {
                // Don't connect to bootloader
                continue;
            }
            
            SerialConfiguration* pSerial = _findSerialConfiguration(portInfo.systemLocation());
            if (pSerial) {
                //-- If this port is configured make sure it has the preferred flag set
                if(!pSerial->isPreferred()) {
                    pSerial->setPreferred(true);
                    saveList = true;
                }
            } else {
                switch (boardType) {
                case QGCSerialPortInfo::BoardTypePX4FMUV1:
                case QGCSerialPortInfo::BoardTypePX4FMUV2:
                    pSerial = new SerialConfiguration(QString("Pixhawk on %1").arg(portInfo.portName().trimmed()));
                    break;
                case QGCSerialPortInfo::BoardTypeAeroCore:
                    pSerial = new SerialConfiguration(QString("AeroCore on %1").arg(portInfo.portName().trimmed()));
                    break;
                case QGCSerialPortInfo::BoardTypePX4Flow:
                    pSerial = new SerialConfiguration(QString("PX4Flow on %1").arg(portInfo.portName().trimmed()));
                    break;
                case QGCSerialPortInfo::BoardType3drRadio:
                    pSerial = new SerialConfiguration(QString("3DR Radio on %1").arg(portInfo.portName().trimmed()));
                default:
                    qWarning() << "Internal error";
                    break;
                }

                pSerial->setBaud(boardType == QGCSerialPortInfo::BoardType3drRadio ? 57600 : 115200);
                pSerial->setDynamic(true);
                pSerial->setPreferred(true);
                pSerial->setPortName(portInfo.systemLocation());
                addLinkConfiguration(pSerial);
                saveList = true;
            }
        }
    }

    // Now we go through the current configuration list and make sure any dynamic config has gone away
    QList<LinkConfiguration*>  _confToDelete;
    foreach (LinkConfiguration* pLink, _linkConfigurations) {
        Q_ASSERT(pLink != NULL);
        // We only care about dynamic links
        if(pLink->isDynamic()) {
            if(pLink->type() == LinkConfiguration::TypeSerial) {
                // Don't mess with connected link. Let it deal with the disapearing device.
                if(pLink->getLink() == NULL) {
                    SerialConfiguration* pSerial = dynamic_cast<SerialConfiguration*>(pLink);
                    if(!currentPorts.contains(pSerial->portName())) {
                        _confToDelete.append(pSerial);
                    }
                }
            }
        }
    }
    // Now remove all links that are gone
    foreach (LinkConfiguration* pDelete, _confToDelete) {
        removeLinkConfiguration(pDelete);
        saveList = true;
    }
    // Save configuration list, which will also trigger a signal for the UI
    if(saveList) {
        saveLinkConfigurationList();
    }
}
#endif

bool LinkManager::containsLink(LinkInterface* link)
{
    bool found = false;
    foreach (SharedLinkInterface sharedLink, _links) {
        if (sharedLink.data() == link) {
            found = true;
            break;
        }
    }
    return found;
}

bool LinkManager::anyConnectedLinks(void)
{
    bool found = false;
    foreach (SharedLinkInterface sharedLink, _links) {
        if (sharedLink.data()->isConnected()) {
            found = true;
            break;
        }
    }
    return found;
}

SharedLinkInterface& LinkManager::sharedPointerForLink(LinkInterface* link)
{
    for (int i=0; i<_links.count(); i++) {
        if (_links[i].data() == link) {
            return _links[i];
        }
    }
    // This should never happen
    Q_ASSERT(false);
    return _nullSharedLink;
}
