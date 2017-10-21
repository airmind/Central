/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick              2.3
import QtQuick.Layouts      1.2
import QtQuick.Controls     1.2

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.Palette               1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Controllers           1.0

Rectangle {
    id:         toolBar
    color:      qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.8) : Qt.rgba(0,0,0,0.75)
    visible:    !QGroundControl.videoManager.fullScreen

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    property var  _activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle

    signal showSettingsView
    signal showSetupView
    signal showPlanView
    signal showFlyView
    signal showAnalyzeView
    signal armVehicle
    signal disarmVehicle

    function checkSettingsButton() {
        settingsButton.checked = true
    }

    function checkSetupButton() {
        setupButton.checked = true
    }

    function checkPlanButton() {
        planButton.checked = true
    }

    function checkFlyButton() {
        flyButton.checked = true
    }

    function checkAnalyzeButton() {
        analyzeButton.checked = true
    }

    Component.onCompleted: {
        //-- TODO: Get this from the actual state
        flyButton.checked = true
    }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          "black"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }

    RowLayout {
        anchors.bottomMargin:   1
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 2
        anchors.fill:           parent
        spacing:                ScreenTools.defaultFontPixelWidth * 2

        //---------------------------------------------
        // Toolbar Row
        Row {
            id:             viewRow
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            spacing:        ScreenTools.defaultFontPixelWidth / 2

            ExclusiveGroup { id: mainActionGroup }

            QGCToolBarButton {
                id:                 settingsButton
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                exclusiveGroup:     mainActionGroup
                source:             "/res/QGCLogoWhite"
                logo:               true
                onClicked:          toolBar.showSettingsView()
                visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
            }

            QGCToolBarButton {
                id:                 setupButton
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                exclusiveGroup:     mainActionGroup
                source:             "/qmlimages/Gears.svg"
                onClicked:          toolBar.showSetupView()
            }

            QGCToolBarButton {
                id:                 planButton
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                exclusiveGroup:     mainActionGroup
                source:             "/qmlimages/Plan.svg"
                onClicked:          toolBar.showPlanView()
            }

            QGCToolBarButton {
                id:                 flyButton
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                exclusiveGroup:     mainActionGroup
                source:             "/qmlimages/PaperPlane.svg"
                onClicked:          toolBar.showFlyView()
            }

            QGCToolBarButton {
                id:                 analyzeButton
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                exclusiveGroup:     mainActionGroup
                source:             "/qmlimages/Analyze.svg"
                visible:            !ScreenTools.isMobile && QGroundControl.corePlugin.showAdvancedUI
                onClicked:          toolBar.showAnalyzeView()
            }

            Rectangle {
                anchors.margins:    ScreenTools.defaultFontPixelHeight / 2
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              1
                color:              qgcPal.text
                visible:            _activeVehicle
            }
        }

        //-------------------------------------------------------------------------
        //-- Vehicle Selector
        QGCButton {
            id:                     vehicleSelectorButton
            width:                  ScreenTools.defaultFontPixelHeight * 8
            text:                   "Vehicle " + (_activeVehicle ? _activeVehicle.id : "None")
            visible:                QGroundControl.multiVehicleManager.vehicles.count > 1
            anchors.verticalCenter: parent.verticalCenter

            menu: vehicleMenu

            Menu {
                id: vehicleMenu
            }

            Component {
                id: vehicleMenuItemComponent

                MenuItem {
                    onTriggered: QGroundControl.multiVehicleManager.activeVehicle = vehicle

                    property int vehicleId: Number(text.split(" ")[1])
                    property var vehicle:   QGroundControl.multiVehicleManager.getVehicleById(vehicleId)
                }
            }

            property var vehicleMenuItems: []

            function updateVehicleMenu() {
                // Remove old menu items
                for (var i = 0; i < vehicleMenuItems.length; i++) {
                    vehicleMenu.removeItem(vehicleMenuItems[i])
                }
                vehicleMenuItems.length = 0

                // Add new items
                for (var i=0; i<QGroundControl.multiVehicleManager.vehicles.count; i++) {
                    var vehicle = QGroundControl.multiVehicleManager.vehicles.get(i)
                    var menuItem = vehicleMenuItemComponent.createObject(null, { "text": "Vehicle " + vehicle.id })
                    vehicleMenuItems.push(menuItem)
                    vehicleMenu.insertItem(i, menuItem)
                }
            }

            Component.onCompleted: updateVehicleMenu()

            Connections {
                target:         QGroundControl.multiVehicleManager.vehicles
                onCountChanged: vehicleSelectorButton.updateVehicleMenu()
            }
        }

        MainToolBarIndicators {
            anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.66
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            exclusiveGroup:     mainActionGroup
            source:             "/qmlimages/PaperPlane.svg"
            onClicked:          toolBar.showFlyView()
        }
    }

    Item {
        id:                     vehicleIndicators
        height:                 mainWindow.tbCellHeight
        anchors.leftMargin:     mainWindow.tbSpacing * 2
        anchors.left:           viewRow.right
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter

        property bool vehicleConnectionLost: activeVehicle ? activeVehicle.connectionLost : false

        Loader {
            source:                 activeVehicle && !parent.vehicleConnectionLost ? "MainToolBarIndicators.qml" : ""
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

//<<<<<<< HEAD
        QGCToolBarButton {
            id:             connectButton
            width:          mainWindow.tbButtonWidth
            height:         mainWindow.tbCellHeight
            visible:        _controller.connectionCount === 0
            source:         "/qmlimages/Connect.svg"
            checked:        false
            onClicked: {

                checked = false
                //checked = !checked;

//for ios;
                _controller.onConnectTapped("");
                //connectMenu.popup()
                /*
                console.log("Main Window Width:   " + mainWindow.width)
                console.log("Toolbar height:      " + toolBar.height)
                console.log("Default font:        " + ScreenTools.defaultFontPixelSize)
                console.log("Font (.75):          " + ScreenTools.defaultFontPixelSize * 0.75)
                console.log("Font (.85):          " + ScreenTools.defaultFontPixelSize * 0.85)
                console.log("Font 1.5):           " + ScreenTools.defaultFontPixelSize * 1.5)
                console.log("Default Font Width:  " + ScreenTools.defaultFontPixelWidth)
                console.log("Default Font Height: " + ScreenTools.defaultFontPixelHeight)
                console.log("--")
                console.log("Real Font Height:    " + ScreenTools.realFontHeight)
                console.log("fontHRatio:          " + ScreenTools.fontHRatio)
                console.log("--")
                console.log("cellHeight:          " + cellHeight)
                console.log("tbFontSmall:         " + tbFontSmall);
                console.log("tbFontNormal:        " + tbFontNormal);
                console.log("tbFontLarge:         " + tbFontLarge);
                console.log("mainWindow.tbSpacing:           " + tbSpacing);
                */
            }
        }
//=======
        QGCLabel {
            id:                     connectionLost
            text:                   qsTr("COMMUNICATION LOST")
            font.pointSize:         ScreenTools.largeFontPointSize
            font.family:            ScreenTools.demiboldFontFamily
            color:                  colorRed
            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
            anchors.right:          disconnectButton.left
            anchors.verticalCenter: parent.verticalCenter
            visible:                parent.vehicleConnectionLost
//>>>>>>> upstream/master

        }

        QGCButton {
            id:                     disconnectButton
            anchors.rightMargin:     mainWindow.tbSpacing * 2
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            text:                   qsTr("Disconnect")
            visible:                parent.vehicleConnectionLost
            primary:                true
            onClicked:              activeVehicle.disconnectInactiveVehicle()
        }
    }

    // Progress bar
    Rectangle {
        id:             progressBar
        anchors.bottom: parent.bottom
        height:         toolBar.height * 0.05
        width:          _activeVehicle ? _activeVehicle.parameterManager.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
    }
}
