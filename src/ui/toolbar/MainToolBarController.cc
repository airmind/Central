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
 *   @brief QGC Main Tool Bar
 *   @author Gus Grubba <mavlink@grubba.com>
 */

#include <QQmlContext>
#include <QQmlEngine>

#include "MainToolBarController.h"
#include "ScreenToolsController.h"
#include "UASMessageView.h"
#include "UASMessageHandler.h"
#include "QGCApplication.h"
#include "MultiVehicleManager.h"
#include "UAS.h"

#ifdef __ios__
#include "BTSerialLink.h"
#include "BLEDebugTextView.h"


#endif

MainToolBarController::MainToolBarController(QObject* parent)
    : QObject(parent)
    , _vehicle(NULL)
    , _mav(NULL)
    , _progressBarValue(0.0f)
    , _telemetryRRSSI(0)
    , _telemetryLRSSI(0)
{
    _activeVehicleChanged(qgcApp()->toolbox()->multiVehicleManager()->activeVehicle());
<<<<<<< HEAD
    
    // Link signals
    connect(qgcApp()->toolbox()->linkManager(),     &LinkManager::linkConfigurationChanged, this, &MainToolBarController::_updateConfigurations);
#ifndef __ios__
    connect(qgcApp()->toolbox()->linkManager(),     &LinkManager::linkConnected,            this, &MainToolBarController::_linkConnected);
    connect(qgcApp()->toolbox()->linkManager(),     &LinkManager::linkDisconnected,         this, &MainToolBarController::_linkDisconnected);
#else
    //has to use static cast for overloaded signals. Qt is terrible ...
    connect(qgcApp()->toolbox()->linkManager(),     static_cast<void (LinkManager::*)(LinkInterface*)>(&LinkManager::linkConnected),            this, static_cast<void (MainToolBarController::*)(LinkInterface*)>(&MainToolBarController::_linkConnected));
    
    connect(qgcApp()->toolbox()->linkManager(),     static_cast<void (LinkManager::*)(LinkInterface*)>(&LinkManager::linkDisconnected),         this, static_cast<void (MainToolBarController::*)(LinkInterface*)>(&MainToolBarController::_linkDisconnected));

    //for ble link;
    connect(qgcApp()->toolbox()->linkManager(),     static_cast<void (LinkManager::*)(BTSerialLink*)>(&LinkManager::linkConnected),            this, static_cast<void (MainToolBarController::*)(BTSerialLink*)>(&MainToolBarController::_linkConnected));
    
    connect(qgcApp()->toolbox()->linkManager(),     static_cast<void (LinkManager::*)(BTSerialLink*)>(&LinkManager::linkDisconnected),            this, static_cast<void (MainToolBarController::*)(BTSerialLink*)>(&MainToolBarController::_linkDisconnected));

    connect(qgcApp()->toolbox()->linkManager(),     &LinkManager::peripheralsDiscovered,      this, &MainToolBarController::_peripheralsDiscovered);
    connect(qgcApp()->toolbox()->linkManager(),     &LinkManager::bleLinkRSSIUpdated,      this, &MainToolBarController::_bleLinkRSSIUpdated);

#endif
    
    // RSSI (didn't like standard connection)
    connect(qgcApp()->toolbox()->mavlinkProtocol(),
        SIGNAL(radioStatusChanged(LinkInterface*, unsigned, unsigned, unsigned, unsigned, unsigned, unsigned, unsigned)), this,
        SLOT(_telemetryChanged(LinkInterface*, unsigned, unsigned, unsigned, unsigned, unsigned, unsigned, unsigned)));
    
=======
    connect(qgcApp()->toolbox()->mavlinkProtocol(),     &MAVLinkProtocol::radioStatusChanged, this, &MainToolBarController::_telemetryChanged);
>>>>>>> upstream/master
    connect(qgcApp()->toolbox()->multiVehicleManager(), &MultiVehicleManager::activeVehicleChanged, this, &MainToolBarController::_activeVehicleChanged);
    
#ifdef __mindskin__
    popoverpresented=false;
#endif
    
}

MainToolBarController::~MainToolBarController()
{

}

<<<<<<< HEAD
void MainToolBarController::onSetupView()
{
    MainWindow::instance()->showSetupView();
}

void MainToolBarController::onPlanView()
{
    MainWindow::instance()->showPlanView();
}

void MainToolBarController::onFlyView()
{
    MainWindow::instance()->showFlyView();
}

void MainToolBarController::onDisconnect(QString conf)
{
    if(conf.isEmpty()) {
        // Disconnect Only Connected Link
        int connectedCount = 0;
        LinkInterface* connectedLink = NULL;
        QList<LinkInterface*> links = qgcApp()->toolbox()->linkManager()->getLinks();
        foreach(LinkInterface* link, links) {
            if (link->isConnected()) {
                connectedCount++;
                connectedLink = link;
            }
        }
        Q_ASSERT(connectedCount   == 1);
        Q_ASSERT(_connectionCount == 1);
        Q_ASSERT(connectedLink);
        qgcApp()->toolbox()->linkManager()->disconnectLink(connectedLink);
    } else {
        // Disconnect Named Connected Link
        QList<LinkInterface*> links = qgcApp()->toolbox()->linkManager()->getLinks();
        foreach(LinkInterface* link, links) {
            if (link->isConnected()) {
                if(link->getLinkConfiguration() && link->getLinkConfiguration()->name() == conf) {
                    qgcApp()->toolbox()->linkManager()->disconnectLink(link);
                }
            }
        }
    }
}

void MainToolBarController::onConnect(QString conf)
{
    // Connect Link
    if(conf.isEmpty()) {
        MainWindow::instance()->manageLinks();
    } else {
        // We don't want the list updating under our feet
        qgcApp()->toolbox()->linkManager()->suspendConfigurationUpdates(true);
        // Create a link
        LinkInterface* link = qgcApp()->toolbox()->linkManager()->createConnectedLink(conf);
        if(link) {
            // Save last used connection
            MainWindow::instance()->saveLastUsedConnection(conf);
        }
        qgcApp()->toolbox()->linkManager()->suspendConfigurationUpdates(false);
    }
}

#ifdef __mindskin__
/***
 for iOS hook in MainToolBar.qml
 ****/
void MainToolBarController::onConnectTapped(QString conf)
{
    // show iOS popover from right side;
    if (popoverpresented==false) {
    
    
        popover = new ConnectPopover();
        popoverpresented=true;
        popover->presentPopover(this->_linkConfigurations);
    }
    else {
        popover->dismissPopover();
        popoverpresented=false;
    }
    
}


void MainToolBarController::onConnectTappedDismiss(QString conf)
{
    // show iOS popover from right side;
    //popover = new ConnectPopover();
    if (popover!=nullptr) {
        popover->dismissPopover();
    }
    
}

void MainToolBarController::_peripheralsDiscovered(void* inrangelist, void* outrangelist) {
    popover->peripheralsDiscovered(inrangelist, outrangelist);
}


void _bleLinkRSSIUpdated (void* peripheral_link_list) {
    
}


#endif

void MainToolBarController::onEnterMessageArea(int x, int y)
{
    Q_UNUSED(x);
    Q_UNUSED(y);

    // If not already there and messages are actually present
    if(!_rollDownMessages && qgcApp()->toolbox()->uasMessageHandler()->messages().count()) {
        if (qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()) {
            qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()->resetMessages();
        }

        // FIXME: Position of the message dropdown is hacked right now to speed up Qml conversion
        // Show messages
        int dialogWidth = 400;
#if 0
        x = x - (dialogWidth >> 1);
        if(x < 0) x = 0;
        y = height() / 3;
#endif

        // Put dialog on top of the message alert icon
        _rollDownMessages = new UASMessageViewRollDown(qgcApp()->toolbox()->uasMessageHandler(), MainWindow::instance());
        _rollDownMessages->setAttribute(Qt::WA_DeleteOnClose);
        _rollDownMessages->move(QPoint(100, 100));
        _rollDownMessages->setMinimumSize(dialogWidth,200);
        connect(_rollDownMessages, &UASMessageViewRollDown::closeWindow, this, &MainToolBarController::_leaveMessageView);
        _rollDownMessages->show();
    }
}

void MainToolBarController::_leaveMessageView()
{
    // Mouse has left the message window area (and it has closed itself)
    _rollDownMessages = NULL;
}

=======
>>>>>>> upstream/master
void MainToolBarController::_activeVehicleChanged(Vehicle* vehicle)
{
    // Disconnect the previous one (if any)
    if (_vehicle) {
        disconnect(_vehicle->autopilotPlugin(), &AutoPilotPlugin::parameterListProgress, this, &MainToolBarController::_setProgressBarValue);
        _mav = NULL;
        _vehicle = NULL;
    }

    // Connect new system
    if (vehicle)
    {
        _vehicle = vehicle;
        _mav = vehicle->uas();
        connect(_vehicle->autopilotPlugin(), &AutoPilotPlugin::parameterListProgress, this, &MainToolBarController::_setProgressBarValue);
    }
}

void MainToolBarController::_telemetryChanged(LinkInterface*, unsigned rxerrors, unsigned fixed, int rssi, int remrssi, unsigned txbuf, unsigned noise, unsigned remnoise)
{
    if(_telemetryLRSSI != rssi) {
        _telemetryLRSSI = rssi;
        emit telemetryLRSSIChanged(_telemetryLRSSI);
    }
<<<<<<< HEAD
}

void MainToolBarController::_linkConnected(LinkInterface*)
{
    _updateConnection();
}

void MainToolBarController::_linkDisconnected(LinkInterface* link)
{
    _updateConnection(link);
}


#ifdef __ios__
void MainToolBarController::_linkConnected                 (BTSerialLink* link) {
    _updateConnection();
    //dismiss popover;
    popover->dismissPopover();
    
    //show mindstick button;
    mindstickButton = new MindStickButton();
    mindstickButton->showButton();
    
#ifdef _BLE_DEBUG_
    //pop up debug view;
    BLEDebugTextView* debugview = qgcApp()->toolbox()->linkManager()->openDebugView();
    debugview->presentDebugView();
    QString line ="BLE link connected.";
    debugview->addline(line);
    
#endif

    
}

void MainToolBarController::_linkDisconnected              (BTSerialLink* link) {
    _updateConnection();
    
    //delete mindstick button;
    if (mindstickButton!=NULL) {
        mindstickButton->removeButton();
        delete mindstickButton;
        mindstickButton = NULL;
    }
    
    
}

void MainToolBarController::_bleLinkRSSIUpdated (void* peripheral_link_list) {
    //update RSSI value in UI;
}


#endif

void MainToolBarController::_updateConnection(LinkInterface *disconnectedLink)
{
    QStringList connList;
    int oldCount = _connectionCount;
    // If there are multiple connected links add/update the connect button menu
    _connectionCount = 0;
    QList<LinkInterface*> links = qgcApp()->toolbox()->linkManager()->getLinks();
    foreach(LinkInterface* link, links) {
        if (disconnectedLink != link && link->isConnected()) {
            _connectionCount++;
            if(link->getLinkConfiguration()) {
                connList << link->getLinkConfiguration()->name();
            }
        }
=======
    if(_telemetryRRSSI != remrssi) {
        _telemetryRRSSI = remrssi;
        emit telemetryRRSSIChanged(_telemetryRRSSI);
>>>>>>> upstream/master
    }
    if(_telemetryRXErrors != rxerrors) {
        _telemetryRXErrors = rxerrors;
        emit telemetryRXErrorsChanged(_telemetryRXErrors);
    }
    if(_telemetryFixed != fixed) {
        _telemetryFixed = fixed;
        emit telemetryFixedChanged(_telemetryFixed);
    }
    if(_telemetryTXBuffer != txbuf) {
        _telemetryTXBuffer = txbuf;
        emit telemetryTXBufferChanged(_telemetryTXBuffer);
    }
    if(_telemetryLNoise != noise) {
        _telemetryLNoise = noise;
        emit telemetryLNoiseChanged(_telemetryLNoise);
    }
    if(_telemetryRNoise != remnoise) {
        _telemetryRNoise = remnoise;
        emit telemetryRNoiseChanged(_telemetryRNoise);
    }
}

void MainToolBarController::_setProgressBarValue(float value)
{
    _progressBarValue = value;
    emit progressBarValueChanged(value);
}
