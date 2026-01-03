package com.gobull.app;

interface IServiceCallback {
  void onServiceStatusChanged(int status);
  void onServiceAlert(int type, String message);
  void onServiceWriteLog(String message);
  void onServiceResetLogs(in List<String> messages);
}