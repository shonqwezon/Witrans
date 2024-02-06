#include <iostream>
#include <urlmon.h>
#include <windows.h>
#include <sstream>
#include <tlhelp32.h>

using namespace std;

void some_error(string version) {
    string msg = "The application cannot be updated.\nNew version is " + version + ". Install new version manually?";
    int msgboxID = MessageBoxA(NULL, msg.c_str(), "Witrans's updator", MB_ICONERROR | MB_OKCANCEL);
    switch(msgboxID) {
        case IDOK:
        system("start https://github.com/shonqwezon/Witrans");
        break;
    }
    exit(-1);
}

bool isProcessRun(LPTSTR processName) {
    HANDLE hSnap = NULL;
    PROCESSENTRY32 pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32);
    hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnap!=NULL) {
        if (Process32First(hSnap, &pe32)) {
            if (lstrcmp(pe32.szExeFile, processName) == 0)
                return TRUE;
            while (Process32Next(hSnap, &pe32))
                if (lstrcmp(pe32.szExeFile, processName) == 0)
                    return TRUE;
        }
    }
    CloseHandle(hSnap);
    return FALSE;
}

int main(int argc, char *argv[]) {
    ShowWindow(GetConsoleWindow(), SW_HIDE);
    if(argc == 4) {
        string file;
        string path = argv[1];
        string availableVersion = argv[2];
        istringstream ss(argv[3]);

        string body_url = "https://github.com/shonqwezon/Witrans/raw/main/" + availableVersion + "/";
        //cout << "Update " + availableVersion << endl;

        while(isProcessRun(L"Witrans.exe")) Sleep(1000);

        while(getline(ss, file, '#')) {
            string url = body_url + file;
            //cout << url << endl;
            if(URLDownloadToFileA(NULL, url.c_str(), (path+file).c_str(), 0, NULL) != 0) some_error(availableVersion);
        }
        system(("start " + path + "Witrans.exe").c_str());
    }
    return 0;
}
