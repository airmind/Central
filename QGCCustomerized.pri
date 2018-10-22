iOSBuild:__mindskin__ {
    BUNDLE.files       += $$PWD/mindskin/ios/TagNodesViewController.xib
    BUNDLE.files       += $$PWD/mindskin/ios/RacerMainMenuViewController.xib
    BUNDLE.files       += $$PWD/BLE/BEEP1C.WAV $$PWD/mindskin/ios/tagBLEScanningView.xib
    LIBS               += -framework CoreBluetooth
    LIBS               += -framework AudioToolbox

}

MacBuild:__DRONETAG_BLE__ {
    LIBS               += -framework CoreBluetooth
}

MacBuild:__mindskin__ {
    BUNDLE.files       += $$PWD/BLE/BEEP1C.WAV $$PWD/mindskin/macos/newview.xib
    BUNDLE.path        = Contents/Resources
    QMAKE_BUNDLE_DATA  += BUNDLE
    LIBS               += -framework AppKit
    LIBS               += -framework CoreBluetooth
    LIBS               += -framework AudioToolbox
}

__DRONETAG_BLE__ {
    INCLUDEPATH += BLE
    HEADERS += \
        BLE/BTSerialLink.h \
        BLE/BLE_definitions.h \

    iOSBuild {
        INCLUDEPATH += BLE/macxios
        HEADERS += \
        BLE/macxios/BTSerialLink_objc.h \
        BLE/macxios/BLELinkConnectionDelegate.h \
        BLE/macxios/qt2ioshelper.h \
 
        OBJECTIVE_SOURCES += \
        BLE/macxios/BTSerialLink.mm \
        
        DebugBuild {
            HEADERS += \
            mindskin/ios/BLEDebugTextView.h \
            mindskin/ios/BLEDebugTextViewController.h \
            
            OBJECTIVE_SOURCES += \
            mindskin/ios/BLEDebugTextViewController.mm \
            
        }
    }
    
    MacBuild {
        INCLUDEPATH += BLE/macxios
        HEADERS += \
        BLE/macxios/BTSerialLink_objc.h \
        BLE/macxios/BLELinkConnectionDelegate.h \
        BLE/macxios/qt2ioshelper.h \

        OBJECTIVE_SOURCES += \
        BLE/macxios/BTSerialLink.mm \
        
        DebugBuild {
            
        }
    }
    
    AndroidBuild {
        INCLUDEPATH += BLE/android
        INCLUDEPATH += libs/qtandroidble/src
        HEADERS += \
        $$PWD/libs/qtandroidble/src/qble.h \
        
        SOURCES += \
        BLE/android/BTSerialLink.cc \
        $$PWD/libs/qtandroidble/src/qble.cpp \
        mindskin/android/mindskinlog.cc \
        
        ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
        OTHER_FILES += \
        $$PWD/android/src/org/airmind/ble/DeviceControlActivity.java \
        $$PWD/android/src/org/airmind/ble/DeviceScanActivity.java \
        $$PWD/android/src/org/airmind/ble/BluetoothLeService.java \
        $$PWD/android/src/org/airmind/ble/SampleGattAttributes.java \
        $$PWD/android/src/org/airmind/ble/BLEUtil.java \
        $$PWD/android/src/org/airmind/ble/BTLinkIO.java \
        $$PWD/android/src/org/airmind/ble/BTLinkIONative.java \
        $$PWD/android/src/org/airmind/ble/LinkManager.java \
        $$PWD/android/src/org/airmind/ble/LinkManagerNative.java \
        $$PWD/android/src/org/airmind/ble/VehicleManager.java \
        $$PWD/android/src/org/airmind/ble/ParameterManager.java \
        $$PWD/android/src/org/airmind/ble/ReliableWriter.java \
        $$PWD/android/src/org/airmind/ble/DeviceScanFragment.java \
        $$PWD/android/src/org/qtproject/qt5/android/bindings/QtActivity.java \
        $$PWD/android/src/org/qtproject/qt5/android/bindings/QtApplication.java \

    }
}

__mindskin__ {
    INCLUDEPATH += BLE mindskin
    HEADERS += $$PWD/mindskin/mindskinlog.h \
               $$PWD/mindskin/ParameterLoadHelper.h
    iOSBuild {
        INCLUDEPATH += BLE/macxios
        HEADERS += \
            mindskin/tagNodesManager.h \
            mindskin/ios/tagBLEScanningPanel.h \
            mindskin/ios/MindStickButton.h \
            mindskin/ios/MindStickButtonViewController.h \
            mindskin/MindSkinRootView.h \
            mindskin/ios/MindSkinRootView_impl_objc.h \
            mindskin/ios/tagNodesViewController.h \
            mindskin/ios/mindskinMessageViewController.h \
            mindskin/ios/RacerMainMenuView.h \
            mindskin/ios/RacerMainMenuViewController.h \
            mindskin/ios/ParameterLoadHelper_objc.h \
            mindskin/ios/TagNodesUIDelegateHelper.h

        SOURCES += \
            mindskin/tagNodesManager.cpp \
            mindskin/ios/MindStickButton.cpp \
            mindskin/mindskinlog.cc \

        OBJECTIVE_SOURCES += \
            mindskin/ios/tagBLEScanningPanel.m \
            mindskin/ios/MindStickButtonViewController.mm \
            mindskin/ios/MindSkinRootView_impl_objc.mm \
            mindskin/ios/tagNodesViewController.mm \
            mindskin/ios/mindskinMessageViewController.mm \
            mindskin/ios/RacerMainMenuView.mm \
            mindskin/ios/RacerMainMenuViewController.mm \
            mindskin/ios/ParameterLoadHelper.mm \
            mindskin/ios/TagNodesUIDelegateHelper.m

        DebugBuild {
            HEADERS += \
                mindskin/ios/BLEDebugTextView.h \
                mindskin/ios/BLEDebugTextViewController.h \

            OBJECTIVE_SOURCES += \
                mindskin/ios/BLEDebugTextViewController.mm \

        }
    }
    
    MacBuild {
        INCLUDEPATH += mindskin/macos
        HEADERS += \
        mindskin/macos/tagNodesViewController.h \
        mindskin/MindSkinRootView.h \
        mindskin/macos/MindSkinRootView_impl_objc.h \
        mindskin/macos/mindskinMessageViewController.h\
        mindskin/macos/ParameterLoadHelper_objc.h \
        mindskin/macos/TagNodesUIDelegateHelper.h
        mindskin/macos/tagBLEScanningPanel.h

        OBJECTIVE_SOURCES += \
        mindskin/macos/tagNodesViewController.mm \
        mindskin/macos/MindSkinRootView_impl_objc.mm \
        mindskin/macos/mindskinMessageViewController.mm \
        mindskin/macos/ParameterLoadHelper.mm \
        mindskin/macos/TagNodesUIDelegateHelper.m \
        mindskin/macos/tagBLEScanningPanel.m
    }


    AndroidBuild {
        INCLUDEPATH += BLE/android
        INCLUDEPATH += libs/qtandroidble/src
        HEADERS += \
             $$PWD/libs/qtandroidble/src/qble.h \
             $$PWD/BLE/BTSerialLink.h \

        SOURCES += \
            BLE/android/BTSerialLink.cc \
            $$PWD/libs/qtandroidble/src/qble.cpp \
            mindskin/android/mindskinlog.cc \

        ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
        OTHER_FILES += \
            $$PWD/android/res/layout/actionbar_indeterminate_progress.xml \
            $$PWD/android/res/layout/gatt_services_characteristics.xml \
            $$PWD/android/res/layout/listitem_device.xml \
            $$PWD/android/res/layout/main_activity.xml \
            $$PWD/android/res/layout/mindskin_expandable_list_item_2.xml \
            $$PWD/android/res/layout/fragment_comm_selection.xml \
            $$PWD/android/res/menu/gatt_services.xml \
            $$PWD/android/res/menu/main.xml \
            $$PWD/android/res/values/color.xml \
            $$PWD/android/res/values/string.xml \
            $$PWD/android/src/org/airmind/ble/DeviceControlActivity.java \
            $$PWD/android/src/org/airmind/ble/DeviceScanActivity.java \
            $$PWD/android/src/org/airmind/ble/BluetoothLeService.java \
            $$PWD/android/src/org/airmind/ble/SampleGattAttributes.java \
            $$PWD/android/src/org/airmind/ble/BLEUtil.java \
            $$PWD/android/src/org/airmind/ble/BTLinkIO.java \
            $$PWD/android/src/org/airmind/ble/BTLinkIONative.java \
            $$PWD/android/src/org/airmind/ble/LinkManager.java \
            $$PWD/android/src/org/airmind/ble/LinkManagerNative.java \
            $$PWD/android/src/org/airmind/ble/VehicleManager.java \
            $$PWD/android/src/org/airmind/ble/ParameterManager.java \
            $$PWD/android/src/org/airmind/ble/ReliableWriter.java \
            $$PWD/android/src/org/airmind/ble/DeviceScanFragment.java \
            $$PWD/android/src/org/qtproject/qt5/android/bindings/QtActivity.java \
            $$PWD/android/src/org/qtproject/qt5/android/bindings/QtApplication.java \
            $$PWD/android/src/org/airmind/view/BaseFragment.java \
            $$PWD/android/src/org/airmind/view/FlightFragment.java \
            $$PWD/android/src/org/airmind/view/MindSkinBaseLayout.java \
            $$PWD/android/src/org/airmind/view/MindSkinContainer.java \
            $$PWD/android/src/org/airmind/view/MindSkinLayout.java \
            $$PWD/android/res/layout/activity_qt.xml \
            $$PWD/android/res/layout/fragment_flight.xml \
            $$PWD/android/res/layout/include_qt_content.xml \
            $$PWD/android/res/drawable \
      DISTFILES += $$PWD/android/res/layout/mindskin_expandable_list_item_2.xml
    }
}
