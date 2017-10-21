/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#ifndef MAVLINKPROTOCOL_H_
#define MAVLINKPROTOCOL_H_

#include <QObject>
#include <QMutex>
#include <QString>
#include <QTimer>
#include <QFile>
#include <QMap>
#include <QByteArray>
#include <QLoggingCategory>

#include "LinkInterface.h"
#include "QGCMAVLink.h"
#include "QGC.h"
#include "QGCTemporaryFile.h"
#include "QGCToolbox.h"

#ifdef __mindskin__
//#include "BTSerialLink.h"
class BTSerialLink;
#endif

class LinkManager;
class MultiVehicleManager;
class QGCApplication;

Q_DECLARE_LOGGING_CATEGORY(MAVLinkProtocolLog)

/**
 * @brief MAVLink micro air vehicle protocol reference implementation.
 *
 * MAVLink is a generic communication protocol for micro air vehicles.
 * for more information, please see the official website.
 * @ref http://pixhawk.ethz.ch/software/mavlink/
 **/
class MAVLinkProtocol : public QGCTool
{
    Q_OBJECT

public:
    MAVLinkProtocol(QGCApplication* app, QGCToolbox* toolbox);
    ~MAVLinkProtocol();

    /** @brief Get the human-friendly name of this protocol */
    QString getName();
    /** @brief Get the system id of this application */
    int getSystemId();
    /** @brief Get the component id of this application */
    int getComponentId();
    
    /** @brief Get protocol version check state */
    bool versionCheckEnabled() const {
        return m_enable_version_check;
    }
    /** @brief Get the protocol version */
    int getVersion() {
        return MAVLINK_VERSION;
    }
    /** @brief Get the currently configured protocol version */
    unsigned getCurrentVersion() {
        return _current_version;
    }
    /**
     * Retrieve a total of all successfully parsed packets for the specified link.
     * @returns -1 if this is not available for this protocol, # of packets otherwise.
     */
    qint32 getReceivedPacketCount(const LinkInterface *link) const {
        return totalReceiveCounter[link->mavlinkChannel()];
    }
    /**
     * Retrieve a total of all parsing errors for the specified link.
     * @returns -1 if this is not available for this protocol, # of errors otherwise.
     */
    qint32 getParsingErrorCount(const LinkInterface *link) const {
        return totalErrorCounter[link->mavlinkChannel()];
    }
    /**
     * Retrieve a total of all dropped packets for the specified link.
     * @returns -1 if this is not available for this protocol, # of packets otherwise.
     */
    qint32 getDroppedPacketCount(const LinkInterface *link) const {
        return totalLossCounter[link->mavlinkChannel()];
    }
    /**
     * Reset the counters for all metadata for this link.
     */
    virtual void resetMetadataForLink(LinkInterface *link);
    
#ifdef __mindskin__
    void resetMetadataForLink(const BTSerialLink *link);
    void linkConnected(BTSerialLink* link);
    void linkDisconnected(BTSerialLink* link);
#endif
    /// Suspend/Restart logging during replay.
    void suspendLogForReplay(bool suspend);

    /// Set protocol version
    void setVersion(unsigned version);

    // Override from QGCTool
    virtual void setToolbox(QGCToolbox *toolbox);

public slots:
    /** @brief Receive bytes from a communication interface */
    void receiveBytes(LinkInterface* link, QByteArray b);
    
#ifdef __mindskin__
    void receiveBytes(BTSerialLink* link, QByteArray b);
#endif
    
    //void linkConnected(void);
    //void linkDisconnected(void);


 

    
    /** @brief Send MAVLink message through serial interface */
    //void sendMessage(mavlink_message_t message);
    /** @brief Send MAVLink message */
    //void sendMessage(LinkInterface* link, mavlink_message_t message);
    /** @brief Send MAVLink message with correct system / component ID */
    //void sendMessage(LinkInterface* link, mavlink_message_t message, quint8 systemid, quint8 componentid);
    
    
    
    /** @brief Set the rate at which heartbeats are emitted */
    //void setHeartbeatRate(int rate);
    /** @brief Set the system id of this application */
    void setSystemId(int id);

    /** @brief Enable / disable version check */
    void enableVersionCheck(bool enabled);

    /** @brief Load protocol settings */
    void loadSettings();
    /** @brief Store protocol settings */
    void storeSettings();
    
    /// @brief Deletes any log files which are in the temp directory
    static void deleteTempLogFiles(void);
    
    /// Checks for lost log files
    void checkForLostLogFiles(void);

protected:
    bool m_enable_version_check; ///< Enable checking of version match of MAV and QGC
    QMutex receiveMutex;        ///< Mutex to protect receiveBytes function
    int lastIndex[256][256];    ///< Store the last received sequence ID for each system/componenet pair
    int totalReceiveCounter[MAVLINK_COMM_NUM_BUFFERS];    ///< The total number of successfully received messages
    int totalLossCounter[MAVLINK_COMM_NUM_BUFFERS];       ///< Total messages lost during transmission.
    int totalErrorCounter[MAVLINK_COMM_NUM_BUFFERS];      ///< Total count of all parsing errors. Generally <= totalLossCounter.
    int currReceiveCounter[MAVLINK_COMM_NUM_BUFFERS];     ///< Received messages during this sample time window. Used for calculating loss %.
    int currLossCounter[MAVLINK_COMM_NUM_BUFFERS];        ///< Lost messages during this sample time window. Used for calculating loss %.
    bool versionMismatchIgnore;
    int systemId;
    unsigned _current_version;
    unsigned _radio_version_mismatch_count;

signals:
    /// Heartbeat received on link
    void vehicleHeartbeatInfo(LinkInterface* link, int vehicleId, int componentId, int vehicleMavlinkVersion, int vehicleFirmwareType, int vehicleType);

#ifdef __mindskin__
    void vehicleHeartbeatInfo(BTSerialLink* link, int vehicleId, int vehicleMavlinkVersion, int vehicleFirmwareType, int vehicleType);
#endif
    
    /** @brief Message received and directly copied via signal */
    void messageReceived(LinkInterface* link, mavlink_message_t message);
    /** @brief Emitted if version check is enabled / disabled */
    void versionCheckChanged(bool enabled);
    /** @brief Emitted if a message from the protocol should reach the user */
    void protocolStatusMessage(const QString& title, const QString& message);
    /** @brief Emitted if a new system ID was set */
    void systemIdChanged(int systemId);

    void receiveLossPercentChanged(int uasId, float lossPercent);
    void receiveLossTotalChanged(int uasId, int totalLoss);

    /**
     * @brief Emitted if a new radio status packet received
     *
     * @param rxerrors receive errors
     * @param fixed count of error corrected packets
     * @param rssi local signal strength in dBm
     * @param remrssi remote signal strength in dBm
     * @param txbuf how full the tx buffer is as a percentage
     * @param noise background noise level
     * @param remnoise remote background noise level
     */
    void radioStatusChanged(LinkInterface* link, unsigned rxerrors, unsigned fixed, int rssi, int remrssi,
    unsigned txbuf, unsigned noise, unsigned remnoise);
#ifdef __mindskin__
    void radioStatusChanged(BTSerialLink* link, unsigned rxerrors, unsigned fixed, unsigned rssi, unsigned remrssi,
                            unsigned txbuf, unsigned noise, unsigned remnoise);
    
    void messageReceived(BTSerialLink* link, mavlink_message_t message);
    
#endif
    
    /// Emitted when a temporary telemetry log file is ready for saving
    void saveTelemetryLog(QString tempLogfile);

    /// Emitted when a telemetry log is started to save.
    void checkTelemetrySavePath(void);

private slots:
    void _vehicleCountChanged(void);
    
private:
    //void _linkStatusChanged(LinkInterface* link, bool connected);
//#ifdef __ios__
    //void _linkStatusChanged(BTSerialLink* link, bool connected);
//#endif
    void _sendMessage(mavlink_message_t message);
    void _sendMessage(LinkInterface* link, mavlink_message_t message);
    void _sendMessage(LinkInterface* link, mavlink_message_t message, quint8 systemid, quint8 componentid);

#ifdef __mindskin__
    /** @brief Send MAVLink message */
    void _sendMessage(BTSerialLink* link, mavlink_message_t message);
    /** @brief Send MAVLink message with correct system / component ID */
    void _sendMessage(BTSerialLink* link, mavlink_message_t message, quint8 systemid, quint8 componentid);
    
#endif

    
#ifndef __mobile__
    bool _closeLogFile(void);
    void _startLogging(void);
    void _stopLogging(void);

    bool _logSuspendError;      ///< true: Logging suspended due to error
    bool _logSuspendReplay;     ///< true: Logging suspended due to replay
    bool _vehicleWasArmed;      ///< true: Vehicle was armed during log sequence

    QGCTemporaryFile    _tempLogFile;            ///< File to log to
    static const char*  _tempLogFileTemplate;    ///< Template for temporary log file
    static const char*  _logFileExtension;       ///< Extension for log files
#endif
    
    /// List of all links connected to protocol. We keep SharedLinkInterface objects
    /// which are QSharedPointer's in order to maintain reference counts across threads.
    /// This way Link deletion works correctly.
    //QList<SharedLinkInterface> _connectedLinks;
//#ifdef __ios__
    //QList<BTSerialLink*> _connectedBLELinks;
//#endif
    
    //QTimer  _heartbeatTimer;    ///< Timer to emit heartbeats
    //int     _heartbeatRate;     ///< Heartbeat rate, controls the timer interval
    //bool    _heartbeatsEnabled; ///< Enabled/disable heartbeat emission

    LinkManager*            _linkMgr;
    MultiVehicleManager*    _multiVehicleManager;
};

#endif // MAVLINKPROTOCOL_H_
