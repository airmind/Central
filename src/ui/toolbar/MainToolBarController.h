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
 *   @brief QGC Main Tool Bar
 *   @author Gus Grubba <mavlink@grubba.com>
 */

#ifndef MainToolBarController_H
#define MainToolBarController_H

#include <QObject>

#include "Vehicle.h"
#include "UASMessageView.h"

//#define __mindskin__ 1 //for the moment; //move to "custom compiler flags" - "other C flags"

#if defined(__mindskin__) && defined(__ios__)
#include "BTSerialLink.h"
#endif

#if defined(__mindskin__) && defined(__ios__)
#include "ConnectPopover.h"
#include "MindStickButton.h"
#endif

#define TOOL_BAR_SETTINGS_GROUP "TOOLBAR_SETTINGS_GROUP"
#define TOOL_BAR_SHOW_BATTERY   "ShowBattery"
#define TOOL_BAR_SHOW_GPS       "ShowGPS"
#define TOOL_BAR_SHOW_MAV       "ShowMav"
#define TOOL_BAR_SHOW_MESSAGES  "ShowMessages"
#define TOOL_BAR_SHOW_RSSI      "ShowRSSI"

class MainToolBarController : public QObject
{
    Q_OBJECT

public:
    MainToolBarController(QObject* parent = NULL);
    ~MainToolBarController();
/*
<<<<<<< HEAD
    Q_INVOKABLE void    onSetupView();
    Q_INVOKABLE void    onPlanView();
    Q_INVOKABLE void    onFlyView();
    Q_INVOKABLE void    onConnect(QString conf);
    Q_INVOKABLE void    onDisconnect(QString conf);
    Q_INVOKABLE void    onEnterMessageArea(int x, int y);
    Q_INVOKABLE void    onToolBarMessageClosed(void);
    Q_INVOKABLE void    showSettings(void);

=======
>>>>>>> upstream/master
    */
#if defined(__mindskin__) && defined(__ios__)
    Q_INVOKABLE void    onConnectTapped(QString conf);
    Q_INVOKABLE void    onConnectTappedDismiss(QString conf);
    
#endif

    Q_PROPERTY(double       height              MEMBER _toolbarHeight           NOTIFY heightChanged)
    Q_PROPERTY(float        progressBarValue    MEMBER _progressBarValue        NOTIFY progressBarValueChanged)
    Q_PROPERTY(int          telemetryRRSSI      READ telemetryRRSSI             NOTIFY telemetryRRSSIChanged)
    Q_PROPERTY(int          telemetryLRSSI      READ telemetryLRSSI             NOTIFY telemetryLRSSIChanged)
    Q_PROPERTY(unsigned int telemetryRXErrors   READ telemetryRXErrors          NOTIFY telemetryRXErrorsChanged)
    Q_PROPERTY(unsigned int telemetryFixed      READ telemetryFixed             NOTIFY telemetryFixedChanged)
    Q_PROPERTY(unsigned int telemetryTXBuffer   READ telemetryTXBuffer          NOTIFY telemetryTXBufferChanged)
    Q_PROPERTY(unsigned int telemetryLNoise     READ telemetryLNoise            NOTIFY telemetryLNoiseChanged)
    Q_PROPERTY(unsigned int telemetryRNoise     READ telemetryRNoise            NOTIFY telemetryRNoiseChanged)

    void        viewStateChanged        (const QString& key, bool value);

    int         telemetryRRSSI          () { return _telemetryRRSSI; }
    int         telemetryLRSSI          () { return _telemetryLRSSI; }
    unsigned int telemetryRXErrors      () { return _telemetryRXErrors; }
    unsigned int telemetryFixed         () { return _telemetryFixed; }
    unsigned int telemetryTXBuffer      () { return _telemetryTXBuffer; }
    unsigned int telemetryLNoise        () { return _telemetryLNoise; }
    unsigned int telemetryRNoise        () { return _telemetryRNoise; }

signals:
    void progressBarValueChanged        (float value);
    void telemetryRRSSIChanged          (int value);
    void telemetryLRSSIChanged          (int value);
    void heightChanged                  (double height);
    void telemetryRXErrorsChanged       (unsigned int value);
    void telemetryFixedChanged          (unsigned int value);
    void telemetryTXBufferChanged       (unsigned int value);
    void telemetryLNoiseChanged         (unsigned int value);
    void telemetryRNoiseChanged         (unsigned int value);

private slots:
    void _activeVehicleChanged          (Vehicle* vehicle);
    
//<<<<<<< HEAD
    /*
    void _updateConfigurations          ();
    void _linkConnected                 (LinkInterface* link);
    void _linkDisconnected              (LinkInterface* link);
    */
#if defined(__mindskin__) && defined(__ios__)
    void _linkConnected                 (BTSerialLink* link);
    void _linkDisconnected              (BTSerialLink* link);

    void _peripheralsDiscovered(void* inrangelist, void* outrangelist);
    void _bleLinkRSSIUpdated (void* peripheral_link_list);
#endif
    //void _leaveMessageView              ();
//=======
//>>>>>>> upstream/master
    
    void _setProgressBarValue           (float value);
    void _telemetryChanged              (LinkInterface* link, unsigned rxerrors, unsigned fixed, int rssi, int remrssi, unsigned txbuf, unsigned noise, unsigned remnoise);
    
#if defined(__mindskin__) && defined(__ios__)
    void _telemetryChanged              (BTSerialLink* link, unsigned rxerrors, unsigned fixed, int rssi, int remrssi, unsigned txbuf, unsigned noise, unsigned remnoise);

#endif
    
private:
    Vehicle*        _vehicle;
    UASInterface*   _mav;
    float           _progressBarValue;
    double          _remoteRSSIstore;
    int             _telemetryRRSSI;
    int             _telemetryLRSSI;
    uint32_t        _telemetryRXErrors;
    uint32_t        _telemetryFixed;
    uint32_t        _telemetryTXBuffer;
    uint32_t        _telemetryLNoise;
    uint32_t        _telemetryRNoise;

    double          _toolbarHeight;

    QStringList     _toolbarMessageQueue;
    QMutex          _toolbarMessageQueueMutex;
    
#if defined(__mindskin__) && defined(__ios__)
    ConnectPopover* popover;
    MindStickButton* mindstickButton;
    bool popoverpresented;
    
#endif
};

#endif // MainToolBarController_H
