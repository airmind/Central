/*=====================================================================

PIXHAWK Micro Air Vehicle Flying Robotics Toolkit

(c) 2009, 2015 PIXHAWK PROJECT  <http://pixhawk.ethz.ch>

This file is part of the PIXHAWK project

    PIXHAWK is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    PIXHAWK is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with PIXHAWK. If not, see <http://www.gnu.org/licenses/>.

======================================================================*/

/// @file
///     @author Lorenz Meier <mavteam@student.ethz.ch>

#ifndef _LINKMANAGER_H_
#define _LINKMANAGER_H_

#include <QList>
#include <QMultiMap>
#include <QMutex>

#include "LinkConfiguration.h"
#include "LinkInterface.h"
#include "QGCLoggingCategory.h"
#include "QGCToolbox.h"

// Links
#ifndef __ios__
#include "SerialLink.h"
#endif

#ifdef __ios__
#include "BTSerialLink.h"
#endif


#include "UDPLink.h"
#include "TCPLink.h"
#include "LogReplayLink.h"

#ifdef QT_DEBUG
#include "MockLink.h"
#endif

#include "ProtocolInterface.h"
#include "MAVLinkProtocol.h"

Q_DECLARE_LOGGING_CATEGORY(LinkManagerLog)

class QGCApplication;

/// Manage communication links
///
/// The Link Manager organizes the physical Links. It can manage arbitrary
/// links and takes care of connecting them as well assigning the correct
/// protocol instance to transport the link data into the application.

class LinkManager : public QGCTool
{
    Q_OBJECT

    /// Unit Test has access to private constructor/destructor
    friend class LinkManagerTest;

public:
    LinkManager(QGCApplication* app);
    ~LinkManager();

    /*!
      Add a new link configuration setting to the list
      @param[in] link An instance of the link setting.
    */
    void addLinkConfiguration(LinkConfiguration* link);

    /*!
      Removes (and deletes) an existing link configuration setting from the list
      @param[in] link An instance of the link setting.
    */
    void removeLinkConfiguration(LinkConfiguration* link);

    /// Load list of link configurations from disk
    void loadLinkConfigurationList();

    /// Save list of link configurations from disk
    void saveLinkConfigurationList();

    /// Get a list of the configured links. This is the list of configured links that can be used by QGC.
    const QList<LinkConfiguration*> getLinkConfigurationList();

    /// Suspend automatic confguration updates (during link maintenance for instance)
    void suspendConfigurationUpdates(bool suspend);

    /// Returns list of all links
    const QList<LinkInterface*> getLinks();

    // Returns list of all serial links
#ifndef __ios__
    const QList<SerialLink*> getSerialLinks();
#endif
    
#ifdef __ios__
    //BTSerialLink* getlink();
    const QList<BTSerialLink*> getBTSerialLinks();
    void setCallbackDelegate(void*);
    bool discoverBTLinks(void * delegate);
    bool discoverServices(void*);
    bool discoverCharacteristics(void*);
    bool stopScanning();
    BTSerialLink* createConnectedBLELink(LinkConfiguration* config);
    BTSerialLink* createConnectedBLELink(const QString& identifier);
    //void didDiscoverBTLinks(QStringList* ids);
    //void disDiscoverServices(QStringList* svcids);
    //void disDiscoverPeripherals(QStringList* pids);
    
    /// Connect the specified link
    bool connectBLELink(BTSerialLink* link);
    bool disconnectBLELink(BTSerialLink* link);
    
    //return matching ble link give specific ble configuration;
    BTSerialLink* getBLELinkByConfiguration(BTSerialConfiguration* cfg);

    /// BLE link use these call backs to notify other receivers about link status;
    void didConnectedBLELink();
    void didDisconnectedBLELink();
    
    /// use Qt signal instead ?
    void registerLinkStatusNotification(void*);
    
#endif

    
    /// Sets the flag to suspend the all new connections
    ///     @param reason User visible reason to suspend connections
    void setConnectionsSuspended(QString reason);

    /// Sets the flag to allow new connections to be made
    void setConnectionsAllowed(void) { _connectionsSuspended = false; }

    /// Creates, connects (and adds) a link  based on the given configuration instance.
    /// Link takes ownership of config.
    LinkInterface* createConnectedLink(LinkConfiguration* config);

    /// Creates, connects (and adds) a link  based on the given configuration name.
    LinkInterface* createConnectedLink(const QString& name);

    /// Returns true if the link manager is holding this link
    bool containsLink(LinkInterface* link);

#ifdef __ios__
    bool containsLink(BTSerialLink* link);
#endif
    
    /// Returns the QSharedPointer for this link. You must use SharedLinkInterface if you are going to
    /// keep references to a link in a thread other than the main ui thread.
    SharedLinkInterface& sharedPointerForLink(LinkInterface* link);

    /// Re-connects all existing links
    bool connectAll();

    /// Disconnects all existing links
    bool disconnectAll();

    /// Connect the specified link
    bool connectLink(LinkInterface* link);

    /// Disconnect the specified link
    bool disconnectLink(LinkInterface* link);
    
    /// Returns true if there are any connected links
    bool anyConnectedLinks(void);
    
    // The following APIs are public but should not be called in normal use. The are mainly exposed
    // here for unit test code.
    void _deleteLink(LinkInterface* link);
    void _addLink(LinkInterface* link);

#ifdef __ios__
    void _deleteLink(BTSerialLink* link);
    void _addLink(BTSerialLink* link);
#endif
    
    // Override from QGCTool
    virtual void setToolbox(QGCToolbox *toolbox);

signals:
    void newLink(LinkInterface* link);
    void linkDeleted(LinkInterface* link);
    void linkConnected(LinkInterface* link);
    void linkDisconnected(LinkInterface* link);
    void linkConfigurationChanged();
    
#ifdef __ios__
    void newlink(BTSerialLink* link);
    void linkDeleted(BTSerialLink* link);
    void linkConnected(BTSerialLink* link);
    void linkDisconnected(BTSerialLink* link);
#endif
    
private slots:
    
    
    void _linkConnected(void);
    void _linkDisconnected(void);

#ifdef __ios__
    
    void _bleLinkConnected(void);
    void _bleLlinkDisconnected(void);
#endif

private:
    virtual void _shutdown(void);

    bool _connectionsSuspendedMsg(void);
    void _updateConfigurationList(void);
#ifndef __ios__
    SerialConfiguration* _findSerialConfiguration(const QString& portName);
#endif
    
#ifdef __ios__
    BLEHelper* blehelper = NULL;
#endif
    
    QList<LinkConfiguration*>   _linkConfigurations;    ///< List of configured links
    
    /// List of available links kept as QSharedPointers. We use QSharedPointer since
    /// there are other objects that maintain copies of these links in other threads.
    /// The reference counting allows for orderly deletion.
    QList<SharedLinkInterface>  _links;
    
#ifdef __ios__
    //BTSerialLink is not a Qthread, so need to be handled seperately.
    QList<BTSerialLink> _blelinks;
    QMutex                      _bleLinkListMutex;         ///< Mutex for thread safe access to _blelinks list

#endif
    
    QMutex                      _linkListMutex;         ///< Mutex for thread safe access to _links list

    bool    _configUpdateSuspended;                     ///< true: stop updating configuration list
    bool    _configurationsLoaded;                      ///< true: Link configurations have been loaded
    bool    _connectionsSuspended;                      ///< true: all new connections should not be allowed
    QString _connectionsSuspendedReason;                ///< User visible reason for suspension
#ifndef __ios__
    QTimer  _portListTimer;
#endif
    uint32_t _mavlinkChannelsUsedBitMask;
    
    SharedLinkInterface _nullSharedLink;

    MAVLinkProtocol*    _mavlinkProtocol;
};

#endif
