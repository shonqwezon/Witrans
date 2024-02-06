#include "windowshooks.h"

WindowsHooks &WindowsHooks::instance() {
    static WindowsHooks _instance;
    return _instance;
}

WindowsHooks::WindowsHooks(QObject *parent) : QObject(parent) {
    QMultiHash<QString, unsigned long> binds = Registry::getSequences();
    setNewSequence(binds.values("hideApp").first(), binds.values("hideApp").last());
    HINSTANCE hInstance = GetModuleHandle(NULL);
    HHOOK keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, keyboardProc, hInstance, 0);
    if (keyboardHook == NULL) qWarning(logWindowsHooks()) << "Keyboard Hook failed";
}

LRESULT WindowsHooks::keyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    PKBDLLHOOKSTRUCT pHookStruct = (PKBDLLHOOKSTRUCT) lParam;
    if (GetAsyncKeyState(modifier) & 1 && pHookStruct->vkCode == key) emit instance().keyboardEvent();
    return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void WindowsHooks::setNewSequence(int modifier, unsigned long key) {
    switch(modifier) {
        case Qt::AltModifier:
            this->modifier = VK_MENU;
            break;
        case Qt::ShiftModifier:
            this->modifier = VK_SHIFT;
            break;
        case Qt::ControlModifier:
            this->modifier = VK_CONTROL;
            break;
    }
    this->key = key;
}
