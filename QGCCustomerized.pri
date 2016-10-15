CONFIG += __mindskin__
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

iOSBuild:__mindskin__ {
    BUNDLE.files       += $$PWD/mindskin/ios/TagNodesViewController.xib
    BUNDLE.files       += $$PWD/mindskin/ios/RacerMainMenuViewController.xib
    BUNDLE.files       += $$PWD/BLE/BEEP1C.WAV
    LIBS               += -framework CoreBluetooth
}

__mindskin__ {
    iOSBuild {
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
            mindskin/ios/RacerMainMenuViewController.h \

        SOURCES += \
            mindskin/tagNodesManager.cpp \
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
        message("Adding mindskin Java Classes")
        HEADERS += \
#            BLE/android/BTSerialLink_java.h \
#            BLE/BTSerialLink.h \

        SOURCES += \
#            BLE/android/BTSerialLink.cc \
#            BLE/android/BTSerialLink.java \

        ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
        OTHER_FILES += \
            $$PWD/android/res/layout/actionbar_indeterminate_progress.xml \
            $$PWD/android/res/layout/gatt_services_characteristics.xml \
            $$PWD/android/res/layout/listitem_device.xml \
            $$PWD/android/res/layout/main_activity.xml \
            $$PWD/android/res/menu/gatt_services.xml \
            $$PWD/android/res/menu/main.xml \
            $$PWD/android/res/values/color.xml \
            $$PWD/android/res/values/string.xml \
            $$PWD/android/src/org/airmind/ble/DeviceControlActivity.java \
            $$PWD/android/src/org/airmind/ble/DeviceScanActivity.java \
            $$PWD/android/src/org/airmind/ble/BluetoothLeService.java \
            $$PWD/android/src/org/airmind/ble/SampleGattAttributes.java \
            $$PWD/android/src/org/airmind/ble/BLECommNative.java \
            $$PWD/android/src/org/airmind/ble/BLEComm.java \
            $$PWD/android/src/org/airmind/ble/BLECommInterface.java \

            # views
            $$PWD/android/src/org/airmind/view/BaseFragment.java \
            $$PWD/android/src/org/airmind/view/FlightFragment.java \
            $$PWD/android/src/org/airmind/view/MindSkinBaseLayout.java \
            $$PWD/android/src/org/airmind/view/MindSkinContainer.java \
            $$PWD/android/src/org/airmind/view/MindSkinLayout.java \
            # xml layout
            $$PWD/android/res/layout/activity_qt.xml \
            $$PWD/android/res/layout/fragment_flight.xml \
            $$PWD/android/res/layout/include_qt_content.xml \
            #drawable
            $$PWD/android/res/drawable \

    }
}
