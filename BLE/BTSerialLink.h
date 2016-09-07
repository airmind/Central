//
//  BTSerialLink.h
//  qgroundcontrol
//
//  Created by ning roland on 10/13/15.
//
//

#ifndef qgroundcontrol_BTSerialLink_h
#define qgroundcontrol_BTSerialLink_h

#include <QObject>
#include <QString>
#include <QList>
#include <QMap>
#include <QMutex>
#include <QHostAddress>
//#include <LinkInterface.h>
#include "QGCConfig.h"
#include <LinkConfiguration.h>

#include "MAVLinkProtocol.h"

#define _BLE_DEBUG_ 1 //for the moment;

typedef enum  {
    BLE_LINK_NOT_CONNECTED,
    BLE_LINK_HARDWARE_CONNECTED,
    BLE_LINK_ENDPOINT_CONNECTED   //fully connected to service and characteristic;

}BLE_LINK_STATUS;


typedef enum {
    BLE_LINK_CONNECTED_PERIPHERAL,
    BLE_LINK_CONNECTED_SERVICE,
    BLE_LINK_CONNECTED_CHARACTERISTIC
    
}BLE_LINK_CONNECT_STAGE ;

#ifdef __ios__
#define MAV_TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define MAV_TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"
#endif

#ifdef __android__
#define MAV_TRANSFER_SERVICE_UUID           "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define MAV_TRANSFER_CHARACTERISTIC_UUID    "08590F7E-DB05-467E-8757-72F6FAEB13D4"
#endif
#ifdef __ios__
class BTSerialConfigurationWrapper;
class BTSerialLinkWrapper;
class BLEHelperWrapper;
#endif

//class MAVLinkProtocol;

/**
 1. the class will continously monitoring rssi to tell if device in range during scanning.
 2. after connected the scan will stop. The range of the device is still monitored. if out of range the device will be disconnected.
 3. after disconnected the class will try to reconnect.
 **/

class BLEHelper {
private:
#ifdef __ios__
    BLEHelperWrapper* ble_wrapper;
#endif
public:
    BLEHelper();
    ~BLEHelper();
    void setCallbackDelegate(void* delegate);
    void discover(void*);
    void discoverServices(void*);
    void discoverCharacteristics(void*);
    void stopScanning();
    
};

class BTSerialConfiguration : public LinkConfiguration
{
private:
#ifdef __ios__
    BTSerialConfigurationWrapper* btcwrapper;
#endif
    //for peripheral on the link;
    QString identifier; //NSUUID, device-address for android or device-uuid for ios
    QString pname; //devicename
    QString serviceID; //service-uuid
    QString characteristicID;//characteristic-uuid
    BLE_LINK_CONNECT_STAGE connstage;
    
public:
    
    /*!
     * @brief Regular constructor
     *
     * @param[in] name Configuration (user friendly) name
     */
    BTSerialConfiguration(const QString& name);
    
    /*!
     * @brief Copy contructor
     *
     * When manipulating data, you create a copy of the configuration, edit it
     * and then transfer its content to the original (using copyFrom() below). Use this
     * contructor to create an editable copy.
     *
     * @param[in] source Original configuration
     */
    BTSerialConfiguration(BTSerialConfiguration* source);
    ~BTSerialConfiguration();
    
    /// From LinkConfiguration
    LinkType  type() { return LinkConfiguration::TypeBLESerial; }
    void copyFrom(LinkConfiguration* source);
    void loadSettings(QSettings& settings, const QString& root);
    void saveSettings(QSettings& settings, const QString& root);
    void updateSettings();
    
    void configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid, BLE_LINK_CONNECT_STAGE);
    void setBLEPeripheralIdentifier(QString*);
    QString getBLEPeripheralIdentifier();
    QString getBLEPeripheralName();
    QString getBLEPeripheralServiceID();
    QString getBLEPeripheralCharacteristicID();
//    const QString identifier() { return identifier;}
//    const QString name() {return pname};
//    const QString serviceID() {return serviceID;}
//    const QString characteristicID() {return characteristicID;}
    BLE_LINK_CONNECT_STAGE getBLELinkConnectStage();
    QString settingsURL();
};

/**
 A BTSerialLink is a link between one ble central and one ble peripheral. One ble central can have seral links with multiple peripherals.
 
 NOTE: BTserial doesnot use QThread, but use ios GCD instead.
 
 **/

class BTSerialLink : public QObject//: public LinkInterface
{
    Q_OBJECT
    
    //friend class TCPLinkUnitTest;
    friend class BTSerialConfiguration;
    friend class LinkManager;
    friend class LinkInterface;
    
private:
#ifdef __ios__
    BTSerialLinkWrapper* btlwrapper;
#endif
    MAVLinkProtocol* mavhandler;
   
    //for connected link;
    int filteredLinkRSSI;
    
    //from LinkInterface
    bool _active;       ///< true: link is actively receiving mavlink messages
    
    bool _mavlinkChannelSet;    ///< true: _mavlinkChannel has been set
    uint8_t _mavlinkChannel;    ///< mavlink channel to use for this link, as used by mavlink_parse_char


public:
    
#if defined(__mindskin__) && defined(__android__)
    void cleanJavaException(void);
#endif
    //set link operation call backs;
    void setLinkCallbackDelegte(void*);
    void setMAVLinkProtocolHandler(MAVLinkProtocol* protocolhandler);
    
    Q_PROPERTY(bool active      READ active         WRITE setActive         NOTIFY activeChanged)

    // Property accessors
    bool active(void)                       { return _active; }
    void setActive(bool active)             { _active = active; emit activeChanged(active); }

    
    
    //QTcpSocket* getSocket(void) { return _socket; }
    BTSerialConfiguration* getLinkConfiguration() { return _config; }

    void signalBytesWritten(void);
    
    // LinkInterface methods
    virtual QString getName(void) const;
    virtual bool    isConnected(void) const;
    virtual void    requestReset(void) {};
    
    // Extensive statistics for scientific purposes
    qint64 getConnectionSpeed() const;
    qint64 getCurrentInDataRate() const;
    qint64 getCurrentOutDataRate() const;
    
    // These are left unimplemented in order to cause linker errors which indicate incorrect usage of
    // connect/disconnect on link directly. All connect/disconnect calls should be made through LinkManager.
    bool connect(void);
    bool disconnect(void);
    
    /// @return true: "sh /etc/init.d/rc.usb" must be sent on link to start mavlink
    bool requiresUSBMavlinkStart(void) const { return false; }
    
    /// mavlink channel to use for this link, as used by mavlink_parse_char. The mavlink channel is only
    /// set into the link when it is added to LinkManager
    uint8_t getMavlinkChannel(void) const { Q_ASSERT(_mavlinkChannelSet); return _mavlinkChannel; }

    
public slots:
    
    // From LinkInterface
    //void waitForBytesWritten(int msecs);
    //void waitForReadyRead(int msecs);
    
    
    //new interfaces for BT LE;
    void writeMAVDataBytes(const char* data, qint64 size);
    
    void writeBytes(QString characteristic, const char* data, qint64 size);
    void writeBytesNeedsAck(QString characteristic, const char* data, qint64 size);

    void writeBytes(const char* data, qint64 size);
    void writeBytesNeedsAck(const char* data, qint64 size);

    
    void readMAVDataBytes();
    void readBytes(QString characteristic);
    
//call back interfaces;
    void didReadBytes(const char* data, qint64 size);
    void didConnect();
    void didDisconnect();
    
protected slots:
    void _socketError(QAbstractSocket::SocketError socketError);
    

    virtual void readBytes(void);
    
    virtual bool isLogReplay(void) { return false; }
    
    /// Sets the mavlink channel to use for this link
    void _setMavlinkChannel(uint8_t channel) { Q_ASSERT(!_mavlinkChannelSet); _mavlinkChannelSet = true; _mavlinkChannel = channel; }


signals:
    // From LinkInterface
    void autoconnectChanged(bool autoconnect);
    void activeChanged(bool active);
    void _invokeWriteBytes(QByteArray);
    


protected:
    // From LinkInterface->QThread
    virtual void run(void);
    void setLinkConnectedStatus(BLE_LINK_STATUS status);
    
private:
    // Links are only created/destroyed by LinkManager so constructor/destructor is not public
    BTSerialLink(BTSerialConfiguration* config);
    BTSerialLink(BTSerialConfiguration* config, MAVLinkProtocol* handler);

    ~BTSerialLink();
    
    // From LinkInterface
    virtual bool _connect(void);
    virtual bool _disconnect(void);
    
    //for BT LE;
    void setCallbackDelegate(void*);
    bool _discoverServices(void*);
    bool _discoverCharacteristics(void*);
    
    bool _hardwareConnect();
    void _restartConnection();
    
#ifdef BTSerialLINK_READWRITE_DEBUG
    void _writeDebugBytes(const char *data, qint16 size);
#endif
    
    BTSerialConfiguration* _config;
    //QTcpSocket*       _socket;
    //bool              _socketIsConnected;
    BLE_LINK_STATUS _linkstatus;
    
    quint64 _bitsSentTotal;
    quint64 _bitsSentCurrent;
    quint64 _bitsSentMax;
    quint64 _bitsReceivedTotal;
    quint64 _bitsReceivedCurrent;
    quint64 _bitsReceivedMax;
    quint64 _connectionStartTime;
    QMutex  _statisticsMutex;
};



#endif
