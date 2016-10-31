CONFIG += __mindskin__ installer
# CONFIG += __remotehead__
# CONFIG += __dronetag__

# Airmind - mind skin
__mindskin__ {
    message ("Use mind skin")

    DebugBuild {
        DEFINES += _BLE_DEBUG_
    }

    __dronetag__ {
        DEFINES += __dronetag__
    }

    DEFINES += __mindskin__
#exclusive macro
    DEFINES -= __remotehead__
}

# Airmind - BLE
contains (DEFINES, __mindble__) {
    message ("Enable BLE")
}

# Airmind - Remote Head
__remotehead__ {
    message ("Use remote head")

    DebugBuild {
    DEFINES += _REMOTEHEAD_DEBUG_
    }

    DEFINES += __remotehead__
#exclusive macro
    DEFINES -= __mindskin__

}
__mindskin__ {
    INCLUDEPATH += BLE
    iOSBuild {
        INCLUDEPATH += BLE/ios
        HEADERS += \
            BLE/ios/BTSerialLink_objc.h \
            BLE/BTSerialLink.h \
            mindskin/tagNodesManager.h \
            mindskin/ios/qt2ioshelper.h \
            mindskin/ios/ConnectPopover.h \
            mindskin/ios/ConnectPopoverViewController.h \
            mindskin/ios/MindStickButton.h \
            mindskin/ios/MindStickButtonViewController.h \
            mindskin/MindSkinRootView.h \
            mindskin/ios/MindSkinRootView_impl_objc.h \
            mindskin/ios/tagNodesViewController.h \
            mindskin/ios/mindskinMessageViewController.h \
            mindskin/ios/RacerMainMenuView.h \
            mindskin/ios/RacerMainMenuViewController.h

        DebugBuild {
            HEADERS += \
                mindskin/ios/BLEDebugTextView.h \
                mindskin/ios/BLEDebugTextViewController.h
        }
    }

    AndroidBuild {
        INCLUDEPATH += BLE/android
        INCLUDEPATH += libs/qtandroidble/src
        HEADERS +=  $$PWD/libs/qtandroidble/src/qble.h \
                    $$PWD/BLE/BTSerialLink.h
    }
}
