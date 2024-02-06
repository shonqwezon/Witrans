#ifndef WINDOWSHOOKS_H
#define WINDOWSHOOKS_H

#include <QObject>
#include <QDebug>
#include <QMultiHash>
#include <windows.h>
#include "registry.h"

#include "loggingcategories.h"

class WindowsHooks : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(WindowsHooks)

public:
    static WindowsHooks &instance();
    explicit WindowsHooks(QObject *parent = nullptr);
    virtual ~WindowsHooks() { };

    static LRESULT CALLBACK keyboardProc(int nCode, WPARAM wParam, LPARAM lParam);

    inline static int modifier;
    inline static unsigned long key;

public slots:
    void setNewSequence(int modifier, unsigned long key);

signals:
    void keyboardEvent();
};

#endif // WINDOWSHOOKS_H
