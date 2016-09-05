android {

    QT += androidextras

    INCLUDEPATH += $$PWD

    PUBLIC_HEADERS += \
        $$PWD/qble.h \

#    PRIVATE_HEADERS += \
#        $$PWD/qserialport_p.h \
#        $$PWD/qserialportinfo_p.h \
#        $$PWD/qserialport_android_p.h

    SOURCES += \
        $$PWD/qble.cpp \

    CONFIG += mobility

    HEADERS += $$PUBLIC_HEADERS $$PRIVATE_HEADERS

}
