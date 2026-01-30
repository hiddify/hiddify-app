#include "utils.h"
#include <flutter_windows.h>
#include <windows.h>
#include <shellapi.h>
#include <iostream>
#include <string>
#include <vector>
#include <memory>

void CreateAndAttachConsole() {
    if (!::AttachConsole(ATTACH_PARENT_PROCESS)) {
        if (!::AllocConsole()) return;
    }
    FILE* unused;
    freopen_s(&unused, "CONOUT$", "w", stdout);
    freopen_s(&unused, "CONOUT$", "w", stderr);
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    FlutterDesktopResyncOutputStreams();
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
    if (!utf16_string || *utf16_string == L'\0') return {};
    int size_needed = ::WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, -1, nullptr, 0, nullptr, nullptr);
    if (size_needed <= 1) return {};
    std::string result(size_needed - 1, 0);
    int converted = ::WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, -1, result.data(), size_needed, nullptr, nullptr);
    if (converted == 0) return {};
    return result;
}

ScopedMutex::ScopedMutex(const std::wstring& name) {
    std::wstring global_name = L"Global\\" + name;
    mutex_handle_ = ::CreateMutexW(nullptr, TRUE, global_name.c_str());
    last_error_ = ::GetLastError();
    owns_mutex_ = (mutex_handle_ != nullptr && last_error_ != ERROR_ALREADY_EXISTS);
}

ScopedMutex::~ScopedMutex() {
    release();
}

void ScopedMutex::release() {
    if (mutex_handle_) {
        if (owns_mutex_) ::ReleaseMutex(mutex_handle_);
        ::CloseHandle(mutex_handle_);
        mutex_handle_ = nullptr;
        owns_mutex_ = false;
    }
}
