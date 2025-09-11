import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/app_update/data/github_release_parser.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/utils/utils.dart';

abstract interface class AppUpdateRepository {
  TaskEither<AppUpdateFailure, RemoteVersionEntity> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  });
}

class AppUpdateRepositoryImpl
    with ExceptionHandler, InfraLogger
    implements AppUpdateRepository {
  AppUpdateRepositoryImpl({required this.httpClient});

  final DioHttpClient httpClient;

  @override
  TaskEither<AppUpdateFailure, RemoteVersionEntity> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  }) {
    return exceptionHandler(
      () async {
        if (!release.allowCustomUpdateChecker) {
          throw Exception("custom update checkers are not supported");
        }
        final response =
            await httpClient.get<List>(Constants.githubReleasesApiUrl);
        if (response.statusCode != 200 || response.data == null) {
          loggy.warning("failed to fetch latest version info");
          return left(const AppUpdateFailure.unexpected());
        }

        final releases = response.data!.map(
          (e) => GithubReleaseParser.parse(e as Map<String, dynamic>),
        );
        late RemoteVersionEntity latest;
        if (includePreReleases) {
          latest = releases.first;
        } else {
          latest = releases.firstWhere((e) => e.preRelease == false);
        }
        return right(latest);
      },
      AppUpdateFailure.unexpected,
    );
  }
}
