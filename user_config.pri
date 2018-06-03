MobileBuild {
    CONFIG += __mindskin__
}

MacBuild {
    CONFIG += __mindskin__
}

CONFIG += __DRONETAG_BLE__
# CONFIG += __remotehead__

# Airmind - BLE
__DRONETAG_BLE__ {
    message ("Use DroneTag BLE config")
    DEFINES += __DRONETAG_BLE__
}

# Airmind - mind skin
__mindskin__ {
    message ("Use mind skin config")
    !contains (DEFINES, __DRONETAG_BLE__) {
        message ("BLE support is mandatory for mindskin config")
        DEFINES += __DRONETAG_BLE__
    }

    DebugBuild {
        DEFINES += _BLE_DEBUG_
    }

#    __dronetag__ {
#        DEFINES += __dronetag__
#    }

    DEFINES += __mindskin__
    DEFINES += __mindskin_DEBUG__
#exclusive macro
    DEFINES -= __remotehead__
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

message(DEFINES $${DEFINES})
