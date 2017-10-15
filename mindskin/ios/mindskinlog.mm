#include <mindskinlog.h>
#include <QDebug>

void MSLog(const char *msg, ...) {
    #ifndef __mindskin_DEBUG__
        return;
    #endif

    if( msg == 0 || msg[0] == '\0') return;

    va_list ap;
    va_start(ap, msg); // use variable arg list
    QString buf = QString::vasprintf(msg, ap);
    va_end(ap);

    #ifdef __ios__
      qDebug() << buf;
    #endif
}

