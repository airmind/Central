//
//  BTSerialLink.h
//  qgroundcontrol
//
//  Created by ning roland on 10/13/15.
//
//

#ifndef qgroundcontrol_BTSerialLink_h
#define qgroundcontrol_BTSerialLink_h


#include <QString>
#include <QList>
#include <QMap>
#include <QMutex>
#include <QHostAddress>
#include <LinkInterface.h>
#include "QGCConfig.h"
//#include "LinkManager.h"
//#include "QGBTSerialManager.h"



typedef enum  {
    BLE_LINK_NOT_CONNECTED,
    BLE_LINK_HARDWARE_CONNECTED,
    BLE_LINK_ENDPOINT_CONNECTED   //fully connected to service and characteristic;

}BLE_LINK_STATUS;

class BTSerialConfigurationWrapper;
class BTSerialLinkWrapper;
class BLEHelperWrapper;


/**
 1. the class will continously monitoring rssi to tell if device in range during scanning.
 2. 
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
    
};

class BTSerialConfiguration : public LinkConfiguration
{
    
    //CBCentralManager *manager;
    //QGBTSerialManager* qbtmanager;
private:
    
    BTSerialConfigurationWrapper* btcwrapper;
    //for peripheral on the link;
    QString identifier; //NSUUID
    QString pname;
    QString serviceID;
    QString characteristicID;
    
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
    
    /// From LinkConfiguration
    int  type() { return LinkConfiguration::TypeBLESerial; }
    void copyFrom(LinkConfiguration* source);
    void loadSettings(QSettings& settings, const QString& root);
    void saveSettings(QSettings& settings, const QString& root);
    void updateSettings();
    
    void configBLESerialLink(QString&, QString&, QString&, QString&);
    void setBLEPeripheralIdentifier(QString*);
    QString getBLEPeripheralIdentifier();
    QString getBLEPeripheralName();
    QString getBLEPeripheralServiceID();
    QString getBLEPeripheralCharacteristicID();


};

/**
 A BTSerialLink is a link between one ble central and one ble peripheral. One ble central can have seral links with multiple peripherals.
 
 NOTE: BTserial doesnot use QThread, but use ios GCD instead.
 
 **/

class BTSerialLink //: public LinkInterface
{
    //Q_OBJECT
    
    //friend class TCPLinkUnitTest;
    friend class BTSerialConfiguration;
    friend class LinkManager;
    
private:
    
    BTSerialLinkWrapper* btlwrapper;
   
    
public:
    
    
    
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
    
    
    protected slots:
    void _socketError(QAbstractSocket::SocketError socketError);
    
    // From LinkInterface
    virtual void readBytes(void);
    
    virtual bool isLogReplay(void) { return false; }
    
protected:
    // From LinkInterface->QThread
    virtual void run(void);
    
private:
    // Links are only created/destroyed by LinkManager so constructor/destructor is not public
    BTSerialLink(BTSerialConfiguration* config);
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
