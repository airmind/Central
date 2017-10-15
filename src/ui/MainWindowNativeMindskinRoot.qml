/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick          2.5
import QtQuick.Window   2.2
import QtQuick.Dialogs  1.2

import QGroundControl   1.0

Window {
    id:         _rootWindow
    visible:    true
    TextEdit {
        id:             mindSkinMessageText
        readOnly:       true
        text:           "MindSkin"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        opacity: 1
        color:"#FF0000"
        horizontalAlignment: Text.AlignHCenter
        wrapMode:       TextEdit.WordWrap
    }
}

