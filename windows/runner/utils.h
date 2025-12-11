#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>
#include <windows.h>

void CreateAndAttachConsole();

std::string Utf8FromUtf16(const wchar_t* utf16_string);

std::vector<std::string> GetCommandLineArguments();

class ScopedHandle {
 public:
  explicit ScopedHandle(HANDLE handle) : handle_(handle) {}
  ~ScopedHandle();

  HANDLE get() const { return handle_; }
  bool is_valid() const { return handle_ != nullptr && handle_ != INVALID_HANDLE_VALUE; }

  ScopedHandle(const ScopedHandle&) = delete;
  ScopedHandle& operator=(const ScopedHandle&) = delete;
  ScopedHandle(ScopedHandle&& other) noexcept : handle_(other.handle_) {
    other.handle_ = nullptr;
  }
  ScopedHandle& operator=(ScopedHandle&& other) noexcept {
    if (this != &other) {
      if (handle_) CloseHandle(handle_);
      handle_ = other.handle_;
      other.handle_ = nullptr;
    }
    return *this;
  }

 private:
  HANDLE handle_;
};

class ScopedMutex {
 public:
  explicit ScopedMutex(const std::wstring& name);
  ~ScopedMutex();

  bool success() const { return mutex_.is_valid() && GetLastError() != ERROR_ALREADY_EXISTS; }
  void release();

 private:
  ScopedHandle mutex_;
};

#endif  // RUNNER_UTILS_H_
