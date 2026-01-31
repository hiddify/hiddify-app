import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hiddify/core/model/failures.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

FutureOr<SentryEvent?> sentryBeforeSend(SentryEvent event, {Hint? hint}) {
  if (canSendEvent(event.throwable)) return event;
  return null;
}

bool canSendEvent(dynamic throwable) => switch (throwable) {
  UnexpectedFailure(:final error) => canSendEvent(error),
  DioException _ => false,
  SocketException _ => false,
  HttpException _ => false,
  HandshakeException _ => false,
  ExpectedFailure _ => false,
  ExpectedMeasuredFailure _ => false,
  _ => true,
};

bool canLogEvent(dynamic throwable) => switch (throwable) {
  ExpectedMeasuredFailure _ => true,
  _ => canSendEvent(throwable),
};
