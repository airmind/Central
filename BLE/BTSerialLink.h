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
#include "QmlObjectListModel.h"
#include "BLE_definitions.h"

//#include "LinkManager.h"
//#include "QGBTSerialManager.h"

#include "MAVLinkProtocol.h"

#define _BLE_DEBUG_ 1 //for the moment;

class BTSerialConfigurationWrapper;
class BTSerialLinkWrapper;
class BLEHelperWrapper;
class BTSerialLink;


//class MAVLinkProtocol;

/**
 1. the class will continously monitoring rssi to tell if device in range during scanning.
 2. after connected the scan will stop. The range of the device is still monitored. if out of range the device will be disconnected.
 3. after disconnected the class will try to reconnect.
 **/

class BLEHelper {
private:
    BLEHelperWrapper* ble_wrapper;

public:
    BLEHelper();
    ~BLEHelper();
    void setCallbackDelegate(void* delegate);
    void discover(void*);
    void discoverServices(void*);
    void discoverCharacteristics(void*);
    void stopScanning();
    
    void setPeripheralLinkQuality(QString& pname, BLE_LINK_QUALITY q);
    int currentFilteredPeripheralRSSI(QString& pname);
    BLE_LINK_QUALITY currentPeripheralLinkQuality(QString& pname);
    
};

class BTSerialConfiguration : public LinkConfiguration
{
private:
    BTSerialConfigurationWrapper* btcwrapper;
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
    inline bool equals(BTSerialConfiguration* other) {
        if( this == other ||
            (this->identifier.compare(other->identifier,Qt::CaseSensitive) == 0 &&
            this->serviceID.compare(other->serviceID,Qt::CaseSensitive) == 0 &&
            this->characteristicID.compare(other->characteristicID,Qt::CaseSensitive) == 0 ) )
        {
            return true;
        }

        return false;
    }
    QString getBLELinkServiceID();
    QString getBLELinkCharacteristicID();
    
    BLE_LINK_CONNECT_STAGE getBLELinkConnectStage();
    QString settingsURL();


    // operator;
    bool operator == (BTSerialConfiguration* cfg);
};

typedef QSharedPointer<BTSerialConfiguration> SharedBTLinkConfigurationPointer;

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
    BTSerialLinkWrapper* btlwrapper;
    MAVLinkProtocol* mavhandler;
   
    //for connected link;
    int filteredLinkRSSI;
    
    bool _mavlinkChannelSet;    ///< true: _mavlinkChannel has been set
    uint8_t _mavlinkChannel;    ///< mavlink channel to use for this link, as used by mavlink_parse_char


public:
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

    //for ble;
    BLE_LINK_STATUS linkConnectedStatus();
    void setLinkConnectedStatus(BLE_LINK_STATUS status);

    //link quality;
    void setLinkRSSI(int rssi);
    int  linkRSSI();
    void setLinkQuality(BLE_LINK_QUALITY lq);
    BLE_LINK_QUALITY linkQuality();

    //from LinkInterface;
    /* Connection characteristics */
    
    /**
     * @Enable/Disable data rate collection
     **/
    void enableDataRate(bool enable)
    {
        _enableRateCollection = enable;
    }
    
    /**
     * @Brief Get the current incoming data rate.
     *
     * This should be over a short timespan, something like 100ms. A precise value isn't necessary,
     * and this can be filtered, but should be a reasonable estimate of current data rate.
     *
     * @return The data rate of the interface in bits per second, 0 if unknown
     **/
    qint64 getCurrentInputDataRate() const
    {
        return _getCurrentDataRate(_inDataIndex, _inDataWriteTimes, _inDataWriteAmounts);
    }
    
    /**
     * @Brief Get the current outgoing data rate.
     *
     * This should be over a short timespan, something like 100ms. A precise value isn't necessary,
     * and this can be filtered, but should be a reasonable estimate of current data rate.
     *
     * @return The data rate of the interface in bits per second, 0 if unknown
     **/
    qint64 getCurrentOutputDataRate() const
    {
        return _getCurrentDataRate(_outDataIndex, _outDataWriteTimes, _outDataWriteAmounts);
    }
    
    /// mavlink channel to use for this link, as used by mavlink_parse_char. The mavlink channel is only
    /// set into the link when it is added to LinkManager
    uint8_t mavlinkChannel(void) const;
    
    bool decodedFirstMavlinkPacket(void) const { return _decodedFirstMavlinkPacket; }
    bool setDecodedFirstMavlinkPacket(bool decodedFirstMavlinkPacket) { return _decodedFirstMavlinkPacket = decodedFirstMavlinkPacket; }

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
    bool _hardwareDisconnect();

    
#ifdef BTSerialLINK_READWRITE_DEBUG
    void _writeDebugBytes(const char *data, qint16 size);
#endif
    
    BTSerialConfiguration* _config;
    //QTcpSocket*       _socket;
    //bool              _socketIsConnected;
    BLE_LINK_STATUS _linkstatus;
    BLE_LINK_QUALITY _linkquality;
    
private:
    //from LinkInterface
    /**
     * @brief logDataRateToBuffer Stores transmission times/amounts for statistics
     *
     * This function logs the send times and amounts of datas to the given circular buffers.
     * This data is used for calculating the transmission rate.
     *
     * @param bytesBuffer[out] The buffer to write the bytes value into.
     * @param timeBuffer[out] The buffer to write the time value into
     * @param writeIndex[out] The write index used for this buffer.
     * @param bytes The amount of bytes transmit.
     * @param time The time (in ms) this transmission occurred.
     */
    void _logDataRateToBuffer(quint64 *bytesBuffer, qint64 *timeBuffer, int *writeIndex, quint64 bytes, qint64 time);
    
    /**
     * @brief getCurrentDataRate Get the current data rate given a data rate buffer.
     *
     * This function attempts to use the times and number of bytes transmit into a current data rate
     * estimation. Since it needs to use timestamps to get the timeperiods over when the data was sent,
     * this is effectively a global data rate over the last _dataRateBufferSize - 1 data points. Also note
     * that data points older than NOW - dataRateCurrentTimespan are ignored.
     *
     * @param index The first valid sample in the data rate buffer. Refers to the oldest time sample.
     * @param dataWriteTimes The time, in ms since epoch, that each data sample took place.
     * @param dataWriteAmounts The amount of data (in bits) that was transferred.
     * @return The bits per second of data transferrence of the interface over the last [-statsCurrentTimespan, 0] timespan.
     */
    qint64 _getCurrentDataRate(int index, const qint64 dataWriteTimes[], const quint64 dataWriteAmounts[]) const;
    
    
    static const int _dataRateBufferSize = 20; ///< Specify how many data points to capture for data rate calculations.
    
    static const qint64 _dataRateCurrentTimespan = 500; ///< Set the maximum age of samples to use for data calculations (ms).
    
    // Implement a simple circular buffer for storing when and how much data was received.
    // Used for calculating the incoming data rate. Use with *StatsBuffer() functions.
    int     _inDataIndex;
    quint64 _inDataWriteAmounts[_dataRateBufferSize]; // In bytes
    qint64  _inDataWriteTimes[_dataRateBufferSize]; // in ms
    
    // Implement a simple circular buffer for storing when and how much data was transmit.
    // Used for calculating the outgoing data rate. Use with *StatsBuffer() functions.
    int     _outDataIndex;
    quint64 _outDataWriteAmounts[_dataRateBufferSize]; // In bytes
    qint64  _outDataWriteTimes[_dataRateBufferSize]; // in ms
    
    mutable QMutex _dataRateMutex; // Mutex for accessing the data rate member variables
    
    bool _active;                       ///< true: link is actively receiving mavlink messages
    bool _enableRateCollection;
    bool _decodedFirstMavlinkPacket;    ///< true: link has correctly decoded it's first mavlink packet
};

typedef QSharedPointer<BTSerialLink> SharedBTLinkPointer;
#endif
