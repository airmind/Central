#include <mindskinlog.h>
#include <QDebug>

void MINDSKIN_Log(const char *msg, ...) {
    #ifndef __mindskin_DEBUG__
        return;
    #endif

    if( msg == 0 || msg[0] == '\0') return;

    va_list ap;
    va_start(ap, msg); // use variable arg list
    QString buf = QString::vasprintf(msg, ap);
    va_end(ap);

    #ifdef __android__
      qDebug() << buf;
    #endif
}

