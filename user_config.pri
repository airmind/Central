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
    DEFINES += __mindskin_DEBUG__
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

message(DEFINES $${DEFINES})
