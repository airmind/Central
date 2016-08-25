CONFIG += __mindskin__
# CONFIG += __remotehead__

# Airmind - mind skin
__mindskin__ {
    message ("Use mind skin")

    DebugBuild {
        DEFINES += _BLE_DEBUG_
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

iOSBuild:__mindskin__ {
    BUNDLE.files       += $$PWD/mindskin/ios/TagNodesViewController.xib
    BUNDLE.files       += $$PWD/mindskin/ios/RacerMainMenuViewController.xib
    LIBS               += -framework CoreBluetooth
}

__mindskin__ {
    iOSBuild {
        HEADERS += \
            BLE/ios/BTSerialLink_objc.h \
            BLE/BTSerialLink.h \
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
            mindskin/ios/RacerMainMenuViewController.h \

        SOURCES += \
            mindskin/ios/MindStickButton.cpp \

        OBJECTIVE_SOURCES += \
            BLE/ios/BTSerialLink.mm \
            mindskin/ios/ConnectPopoverViewController.mm \
            mindskin/ios/MindStickButtonViewController.mm \
            mindskin/ios/MindSkinRootView_impl_objc.mm \
            mindskin/ios/tagNodesViewController.m \
            mindskin/ios/mindskinMessageViewController.mm \
            mindskin/ios/RacerMainMenuView.m \
            mindskin/ios/RacerMainMenuViewController.m \


        DebugBuild {
            HEADERS += \
                mindskin/ios/BLEDebugTextView.h \
                mindskin/ios/BLEDebugTextViewController.h \

            OBJECTIVE_SOURCES += \
                mindskin/ios/BLEDebugTextViewController.mm \

        }


    }

    AndroidBuild {
        HEADERS += \
            BLE/android/BTSerialLink_java.h \
            BLE/BTSerialLink.h \

        SOURCES += \
            BLE/android/BTSerialLink.cc \
            BLE/android/BTSerialLink.java \



    }
}
