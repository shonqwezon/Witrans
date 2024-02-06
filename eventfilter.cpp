#include "eventfilter.h"

EventFilter::EventFilter(Service &service) : m_service(service) {

}

bool EventFilter::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) {
    Q_UNUSED(result)
    if(eventType == "windows_generic_MSG") {
        MSG *event = static_cast<MSG *>(message);
        if (event->message == WM_POWERBROADCAST) {
            if(event->wParam == PBT_APMSUSPEND) {
                qDebug(logEventFilter()) << "PBT_APMSUSPEND";
                m_service.closeSession();
                return true;
            }
            if(event->wParam == PBT_APMRESUMEAUTOMATIC) {
                qDebug(logEventFilter()) << "PBT_APMRESUMEAUTOMATIC";
                m_service.openSession();
                return true;
            }
            qDebug(logEventFilter()) << "Unknown WM_POWERBROADCAST event:" << event->wParam;
        }
    }
    return false;
}
