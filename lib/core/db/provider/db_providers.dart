import 'package:hiddify/core/db/v1/db_v1.dart';
import 'package:hiddify/core/db/v2/db_v2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_providers.g.dart';

@Riverpod(keepAlive: true)
DbV1 db(Ref ref) => DbV1();

@Riverpod(keepAlive: true)
DbV2 dbV2(Ref ref) => DbV2();
