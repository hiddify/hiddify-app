import 'package:hiddify/core/db/db.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_providers.g.dart';

@Riverpod(keepAlive: true)
Db db(Ref ref) => Db();
