import 'package:hiddify/core/db/provider/db_providers.dart';
import 'package:hiddify/features/app_based_routing/data/app_proxy_data_source.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_data_provider.g.dart';

@riverpod
AppProxyDataSource appProxyDataSource(Ref ref) => AppProxyDao(ref.watch(dbProvider));
