import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/singbox/generated/core.pbgrpc.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';

abstract class CoreSingboxService extends CoreServiceClient
    implements SingboxService {
  CoreSingboxService()
      : super(
          ClientChannel(
            'localhost',
            port: 7078,
            options: const ChannelOptions(
              credentials: ChannelCredentials.insecure(),
            ),
          ),
        );

  @override
  TaskEither<String, Unit> validateConfigByPath(
    String path,
    String tempPath,
    bool debug,
  ) {
    return TaskEither(
      () async {
        final response = await parseConfig(
          ParseConfigRequest(tempPath: tempPath, path: path, debug: false),
        );
        if (response.error != "") return left(response.error);
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, String> generateFullConfigByPath(String path) {
    return TaskEither(
      () async {
        final response = await generateFullConfig(
          GenerateConfigRequest(path: path, debug: false),
        );
        if (response.error != "") return left(response.error);
        return right(response.config);
      },
    );
  }
}
