#ifndef EVENTFILTER_H
#define EVENTFILTER_H

#include <QAbstractNativeEventFilter>
#include <windows.h>
#include <QDebug>
#include <QTimer>

#include "service.h"
#include "loggingcategories.h"
#include "config.h"

class EventFilter : public QAbstractNativeEventFilter
{

public:
    explicit EventFilter(Service &service);
    virtual ~EventFilter(){ };
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

signals:
    void suspend();
    void resume();

private:
    Service &m_service;
};

#endif // EVENTFILTER_H
