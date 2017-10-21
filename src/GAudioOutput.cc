/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include <QApplication>
#include <QDebug>
#include <QRegularExpression>

#include "GAudioOutput.h"
#include "QGCApplication.h"
#include "QGC.h"
#include "SettingsManager.h"

GAudioOutput::GAudioOutput(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
{
    _tts = new QTextToSpeech(this);
    connect(_tts, &QTextToSpeech::stateChanged, this, &GAudioOutput::_stateChanged);
}

bool GAudioOutput::say(const QString& inText)
{
    bool muted = qgcApp()->toolbox()->settingsManager()->appSettings()->audioMuted()->rawValue().toBool();
    muted |= qgcApp()->runningUnitTests();
    if (!muted && !qgcApp()->runningUnitTests()) {
        QString text = fixTextMessageForAudio(inText);
        if(_tts->state() == QTextToSpeech::Speaking) {
            if(!_texts.contains(text)) {
                //-- Some arbitrary limit
                if(_texts.size() > 20) {
                    _texts.removeFirst();
                }
                _texts.append(text);
            }
        } else {
            _tts->say(text);
        }
    }
    return true;
}

void GAudioOutput::_stateChanged(QTextToSpeech::State state)
{
    if(state == QTextToSpeech::Ready) {
        if(_texts.size()) {
            QString text = _texts.first();
            _texts.removeFirst();
            _tts->say(text);
        }
    }
}

bool GAudioOutput::getMillisecondString(const QString& string, QString& match, int& number) {
    static QRegularExpression re("([0-9]+ms)");
    QRegularExpressionMatchIterator i = re.globalMatch(string);
    while (i.hasNext()) {
        QRegularExpressionMatch qmatch = i.next();
        if (qmatch.hasMatch()) {
            match = qmatch.captured(0);
            number = qmatch.captured(0).replace("ms", "").toInt();
            return true;
        }
    }
    return false;
}

bool GAudioOutput::say(const QString& inText)
{
    if (!muted && !qgcApp()->runningUnitTests()) {
#if defined __android__
#if defined QGC_SPEECH_ENABLED
        static const char V_jniClassName[] {"org/qgroundcontrol/qgchelper/MindSkinActivity"};
        QAndroidJniEnvironment env;
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        result.replace(match, newNumber);
    }
    return result;
}
