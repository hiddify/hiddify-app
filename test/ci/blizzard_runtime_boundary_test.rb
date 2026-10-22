# frozen_string_literal: true

require "json"
require "open3"
require "yaml"
require "digest"
require "minitest/autorun"

# Local mandatory gate; the existing release workflow is deliberately unchanged.
class BlizzardRuntimeBoundaryTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  BASELINE = "0830294eff5b8cd86324545ed00689648c70bd23"
  UI_FILES = %w[
    lib/core/theme/app_theme.dart lib/core/theme/theme_extensions.dart
    lib/core/router/adaptive_layout/my_adaptive_layout.dart
    lib/features/home/widget/home_page.dart lib/features/home/widget/connection_button.dart
    lib/features/profile/widget/profile_tile.dart lib/features/proxy/widget/proxy_tile.dart
    lib/features/proxy/active/active_proxy_card.dart lib/features/proxy/active/active_proxy_delay_indicator.dart
    lib/features/settings/widget/preference_tile.dart lib/features/common/general_pref_tiles.dart
    lib/features/profile/add/add_profile_modal.dart lib/features/profile/overview/profiles_modal.dart
    lib/core/router/bottom_sheets/widgets/quick_settings_modal.dart
    lib/features/profile/details/profile_details_page.dart lib/features/profile/details/json_editor.dart
    lib/features/proxy/overview/proxies_overview_page.dart lib/features/common/qr_code_scanner_screen.dart
    lib/features/common/qr_code_dialog.dart
    lib/features/log/overview/logs_page.dart lib/features/about/widget/about_page.dart
    lib/features/intro/widget/intro_page.dart
  ].freeze
  UI_PREFIXES = %w[lib/core/router/dialog/widgets/ lib/features/settings/overview/].freeze
  NEW_UI_PREFIXES = %w[lib/core/widget/blizzard/].freeze
  NEW_UI_FILES = %w[lib/core/theme/blizzard_tokens.dart lib/core/theme/blizzard_theme.dart lib/core/router/adaptive_layout/blizzard_dock.dart].freeze
  NATIVE_GLASS_FILE = "ios/Runner/BlizzardNativeGlass.swift"
  NATIVE_GLASS_SHA256 = "6375fa6fe9aa7d1e1377c69842149b703e69f32ffa08093bb26d9b5fd40f02ca"
  NATIVE_GLASS_HOST_SHA256 = {
    "ios/Runner/AppDelegate.swift" => [
      "cd1c79e1b3320c6e6fd01d08df8ebd7d310c55adbd548a5a3397d7454b88bf04",
      "b18922b8c1ee98e4100a3cb5ba4fac0fded931b89d64202c7f2aa39ec62b18f6",
    ],
    "ios/Runner.xcodeproj/project.pbxproj" => [
      "11423d2e5f5c60edf42587fc9797d6c3948437d2acd47fbaa7959a54b7928f69",
      "221630aace49cfa805c367e231bed8fc86318a17060e4f53efd8398f9c3edf51",
    ],
    "ios/RunnerTests/RunnerTests.swift" => [
      "5e8f4908dacea6f29b2a790e4d38bf5fded69096063f9a27a2f21584d62b30c0",
      "793aba1f25915236e8efbe516c4a42109cd7fc77533c34fdda44924627ed24aa",
    ],
  }.freeze
  # Exact build-21 source additions carried forward from the trusted release
  # line. These paths are protected from incidental runtime drift just like
  # the older diagnostics fingerprints below.
  RELEASE_SOURCE_SHA256 = {
    ".github/workflows/build.yml" => ["a2eb32f3a0bf0d30f3b31a51ea92a0b32d4fa9973b726eee383caf15656f69e6", "d49a02606bfc045fae46448e8a7dcb514ab78fd51fca979f95546453cbde559d"],
    ".github/workflows/ci.yml" => ["6bcc935cb7841475f50748cd5d8b5be391af3a347857fbfa08920e6bd963f80b", "8f606970df6b5abb03b1b25b1253d15e4d15c66497994bb68220703b35479606"],
    ".github/workflows/ios-baseline.yml" => ["8ff1f9100e5d6d19747c251b23afc8e931082151c38a34960671da86f7c276d0", "85a85c2c223ed4e062a6b19709fc519d63ea3cfca9476cbdbb02b6f7af921054"],
    "assets/translations/en.i18n.json" => ["d1bdfe06b016b0e72828f4a5c980d8e1ae4146983ddd3d7630a1861bfd448acc", "c8620bce25da968f9af9d6ee5c2433487556032a754638331673b35c6e482dfa"],
    "assets/translations/ru.i18n.json" => ["218e2472e8eeca970a0ff160e612e87904f09cc8f4fba7ca4f351df47a0c35c5", "214b34c544c0135d90a252b36b525a15ebcabe654b28861a6ebf38ff7fcba1c6"],
    "ios/Runner/Handlers/StatusEventHandler.swift" => ["7dc456b95a10a459017a957a2146c0df3581a6df790d57b4dc75c9d041b3816d", "8910e6c427a204102d8261cc2594d9a293084e4c44c32f2c765e41637ef65655"],
    "ios/Runner/Info.plist" => ["3b43eb43ba3f09383810c8d231a8e5c0b67cd8f5bb19d23053e30289ee850b7d", "e470873245ee919499c8b57d4ff6b46014467ad4a8009056c0347158a3e86c2e"],
    "ios/Runner/VPN/VPNManager.swift" => ["9f207ded470097e274e1cdb4d238fe1734d57ac4ae452e9844de0a89dfa86dff", "9b69434490e99cb68c93d55c1d3ffcedb2da08f5007a8de94cd390651789aa1d"],
    "lib/core/analytics/analytics_controller.dart" => ["2a84ad1b04bd809c2641605c070c9c2baae0bcb67c896e02604d8c35d9d02498", "c7e09f00d20b504d350c890850231bd2e44ec6a5ad0c81ebbc1d696ec51cad6a"],
    "lib/core/model/app_info_entity.dart" => ["89e024c6f3041e18540e8a78cfec49529020d36ba70cd7b27b45f70416a999bb", "7207abcabc9dc7e676a9524f5f08985a28350d0b195fbb92e36d6d04611fbd5b"],
    "lib/core/model/constants.dart" => ["cb46da835e646341f79f41f53da2b1c665cb159ef10c61dbea5d72f55382b369", "da33cdb4b668428371bf8749d718d132571b175d79324e98b1f3fad9ef6895d8"],
    "lib/core/model/environment.dart" => ["5c932e3d18573ca445ca1acf6dd2c7179cb9b971d1710d9003afaa6382fc63b5", "7b8ce7a0f3ac9b3d820f64a39e3984db4ff791766d53c6b72d4aaaa12b384260"],
    "lib/features/connection/data/connection_repository.dart" => ["4317bad18edde90be73228303e8cbf9a779c6b8a80c53d0539d296b1f9602d4c", "b8247270dd21d92df1fefa23ea856c3ca7d4529e8ecc8fba08884aedbc76ccfb"],
    "lib/hiddifycore/core_interface/core_interface.dart" => ["0576c4eb9a35f0d8302c13f193da05079c9ba7b311026c7b328b5707889b4280", "660445286fc44d4ba38256c5dee154f5f09c188368601a77f5e7d7531db801ff"],
    "lib/hiddifycore/core_interface/core_interface_mobile.dart" => ["e0672d710ce7341cde00e6543458e2ed6ab5a6948c389ff45dcc7788c19baf26", "76460b9358ab9099288d162199ae97544efe9689dc2f080bb3eda0973a03c6b0"],
    "lib/hiddifycore/hiddify_core_service.dart" => ["d55abf280b332358e89a6ee932929616e711b7c923ee60caf08413de9b781ac3", "b6b1be09d437eab148d494dfb5e784896493f1d4fc71ea1e64ce699cab06aee4"],
  }.freeze
  RELEASE_NEW_SHA256 = {
    ".github/workflows/baseline-telemetry.yml" => "afd597ef89b7cdfe37b7f8a951787a29b80c776560d26d66e0f20efca3a06128",
    "lib/core/analytics/telemetry_delivery_provider.dart" => "b81e932c072452710203e57cb92cd76e285d07113f3f45248eb1f2d15218b83e",
    "lib/core/observability/better_stack_log_printer.dart" => "8955fd3587c047dec4e23af21feedcb18fda4100910b854c06e4a2cc69089162",
    "lib/core/observability/telemetry_budget.dart" => "b5251021276928c3927e5026d60f0e22cadfb07aa8aae42f4771c38287676777",
    "lib/core/observability/telemetry_delivery_status.dart" => "c774f10e3f011fd98987ae2278cb0647d212577dd4d0c018fb1c1661b6602af1",
    "lib/features/diagnostics/remote_diagnostic_subscription.dart" => "d9d386c45564403e69be4a43163388f3189caab4da5b86518bf6c99bc23a3e5c",
    "lib/features/diagnostics/remote_ios_ping_subscription.dart" => "3462df29c7779f0d3623442f4a9d3e1bae5d33ecbc797c5b68b9580a765649eb",
    "lib/features/diagnostics/telemetry_delivery_labels.dart" => "c86eb93a4f04e500bb9846b5d2117e5344d62e9c0a3ab4a2dd3623d34ec7e989",
  }.freeze
  DEV_ADDITIONS = %w[flutter_driver fuchsia_remote_debug_protocol integration_test sync_http webdriver].freeze
  PROFILE_DETAILS_NOTIFIER = "lib/features/profile/details/profile_details_notifier.dart"
  APPROVED_RAW_LOG_LINE = "      loggy.info(profContent);\n"
  TRUSTED_PARSE_ERROR_LINE = "      loggy.error('Error parsing profile-content JSON', e, st);\n"
  APPROVED_PARSE_ERROR_LINE =
    "      loggy.error('Error parsing profile-content JSON (${e.runtimeType})', null, st);\n"

  # Exact source fingerprints for the independently reviewed diagnostics batch.
  # Keep this list narrow; the VPN repository, notifier, core and bridge remain protected.
  DIAGNOSTIC_EXISTING_FILES = %w[
    assets/translations/en.i18n.json assets/translations/ru.i18n.json
    ios/HiddifyPacketTunnel/Logger.swift
    ios/HiddifyPacketTunnel/SingBox/ExtensionProvider.swift
    ios/Runner/VPN/VPNManager.swift
    lib/core/analytics/analytics_controller.dart lib/core/analytics/analytics_filter.dart
    lib/core/logger/logger_controller.dart
    lib/features/connection/data/connection_data_providers.dart
    lib/features/log/overview/logs_page.dart
  ].freeze
  DIAGNOSTIC_SOURCE_SHA256 = {
    "assets/translations/en.i18n.json" => ["d1bdfe06b016b0e72828f4a5c980d8e1ae4146983ddd3d7630a1861bfd448acc", "c8620bce25da968f9af9d6ee5c2433487556032a754638331673b35c6e482dfa"],
    "assets/translations/ru.i18n.json" => ["218e2472e8eeca970a0ff160e612e87904f09cc8f4fba7ca4f351df47a0c35c5", "214b34c544c0135d90a252b36b525a15ebcabe654b28861a6ebf38ff7fcba1c6"],
    "ios/HiddifyPacketTunnel/Logger.swift" => ["197a03eb1212f113e934b913525a6d329e2ec5538b97bf71a3296571c07499a7", "dd25284df008b05268740bbd720969eb337982eece068819002a20b8a58a8964"],
    "ios/HiddifyPacketTunnel/SingBox/ExtensionProvider.swift" => ["5d34a57ef76d904bece6462519d340c7ff217b57ff3237bb82e69d82b1a28848", "8876aae20b2e98c0cef2abf66b82080461f770e5b007d0eba9ff547e9880f4aa"],
    "ios/Runner/VPN/VPNManager.swift" => ["9f207ded470097e274e1cdb4d238fe1734d57ac4ae452e9844de0a89dfa86dff", "9b69434490e99cb68c93d55c1d3ffcedb2da08f5007a8de94cd390651789aa1d"],
    "lib/core/analytics/analytics_controller.dart" => ["2a84ad1b04bd809c2641605c070c9c2baae0bcb67c896e02604d8c35d9d02498", "c7e09f00d20b504d350c890850231bd2e44ec6a5ad0c81ebbc1d696ec51cad6a"],
    "lib/core/analytics/analytics_filter.dart" => ["3395f98c9c53da22017b48b657a29d725c3cbbd7ef6cc205a3506332ab5c4e59", "537bd175fa6172c7ac621b1c150f81f2fe2bfa388f205f42c954c43f1f89090a"],
    "lib/core/logger/logger_controller.dart" => ["d78b51210488b4d967c2aee9efbc42d1e6f50b325dc42319d535569c17902e5c", "887355613fb31ae023c1582fc8c7b9e98f0424da1567a6465831514991f900b8"],
    "lib/features/connection/data/connection_data_providers.dart" => ["08624ce007644a397effdeaa42da18d4381195c0feda55e4fe7d7faa2587483d", "aea92301c08f51c603a3917f17c95c0d42b7c54936757545936df5e3ab31abe3"],
    "lib/features/log/overview/logs_page.dart" => ["492d35c4ea6cf24f86dc1b1114ecbdb2713ed6657b8c8d6053d077e6bb2be66b", "8683fc35beb7940ddbef4423166b0440e79bef23f697b8d247f98b6fd9cabee5"],
  }.freeze

  DIAGNOSTIC_NEW_FILES = %w[
    lib/core/logger/safe_log_record.dart
    lib/features/diagnostics/safe_diagnostic_event.dart
    lib/features/diagnostics/safe_diagnostic_journal.dart
    lib/features/diagnostics/home_presentation_snapshot.dart
    lib/features/diagnostics/home_presentation_providers.dart
    lib/features/diagnostics/home_presentation_probe.dart
    lib/features/diagnostics/observed_connection_repository.dart
    lib/features/diagnostics/diagnostic_providers.dart
    lib/features/diagnostics/safe_diagnostics_page.dart
    lib/features/diagnostics/ios_ping_trace.dart
  ].freeze
  DIAGNOSTIC_NEW_SHA256 = {
    "lib/core/logger/safe_log_record.dart" => "57137aee501d92bd54129bc3ce34814efabb2a96f6dd5deab5c48040019b183a",
    "lib/features/diagnostics/safe_diagnostic_event.dart" => "867a3fc3c57f729b0de11787f130e18ed2cabc66cbfd36a3344a3a9f1e7a66a6",
    "lib/features/diagnostics/safe_diagnostic_journal.dart" => "b84f1dca5f57aee57a7cc2658306038909a48c7eb2b71a00a5c427dcd346f364",
    "lib/features/diagnostics/home_presentation_snapshot.dart" => "2e816bf1093b990599747c3860138d489f1a520667c0bbb093ca930289913ded",
    "lib/features/diagnostics/home_presentation_providers.dart" => "43cb56211b4055a2ebf41abb2097d754be3f589d56b377f06c3450b6f3433602",
    "lib/features/diagnostics/home_presentation_probe.dart" => "f51164d3f3433f0ff3c9ebffdc82de291cc38382f93e7200c28f938bec5bc728",
    "lib/features/diagnostics/observed_connection_repository.dart" => "8bd1bdcc05099863f93641b08a16a21e3d3b209f0736ea1cb9df35fc922e8cb1",
    "lib/features/diagnostics/diagnostic_providers.dart" => "ccbd9164f42ef63602b640de0ce0c5e35f81bf2f3dcaafca07351ccd16a2be75",
    "lib/features/diagnostics/safe_diagnostics_page.dart" => "9d46c9744651164f99572c80dbe8a932dab89f73d05c3b02c5058d2904151067",
    "lib/features/diagnostics/ios_ping_trace.dart" => "7b0818f4d26fdddd5c59dcafc9decb6f90e54244edf8722ba96a058b4a0b9292",
  }.freeze

  # Exact reviewed iOS active-proxy measurement sources; no directory allowance.
  IOS_MEASUREMENT_SOURCE_SHA256 = {
    "lib/features/proxy/active/active_proxy_notifier.dart" => ["d1c13a0efac2e778de8e7a3d74bdfb97518aeba4cf1ed036c70051d44f9d1529", "9a6b08f9ca02a6c997f445a4309a7de13190f9508915870bcb1f0206c4807290"],
    "lib/hiddifycore/hiddify_core_service.dart" => ["d55abf280b332358e89a6ee932929616e711b7c923ee60caf08413de9b781ac3", "b6b1be09d437eab148d494dfb5e784896493f1d4fc71ea1e64ce699cab06aee4"],
  }.freeze
  IOS_MEASUREMENT_NEW_SHA256 = {
    "lib/features/proxy/active/ios_active_proxy_measurement.dart" => "71d35a6282bb85980bfc91f9a3c128af028a10d20e82f0f2a6d7ee1cd9b4ce1e",
    "lib/features/proxy/active/ios_active_proxy_measurement_providers.dart" => "2fd3bfbe42f72594054ba06e3922acdaad08cf352712f6d41f393fc617a35e50",
    "lib/features/proxy/active/ios_active_proxy_delay_indicator.dart" => "b68b3d61ad632bbe1d2b46ce5ecbe0094ee4b693107fd36a0b4da03027bb7d91",
  }.freeze

  # Exact iOS startup recovery sources; no lifecycle/core directory allowance.
  IOS_STARTUP_SOURCE_SHA256 = {
    "lib/bootstrap.dart" => ["d035a1bec3386d5f1320cfc7ef7eec9f260621f5d2868706670efe71fcfb24e9", "c7c92337c2f9ece8f392ae851df0f15f8269a8c8367b0a4fafaa7ff9a2901fda"],
    "lib/features/app/widget/app.dart" => ["f3907fa99dcbe37c300f9c1c856d1ae18943754019193eda1a01dc6df3532390", "c3923577ee27bfa100cb2f1a3fdf687f611b988186eabc0dd2f758675c093b67"],
    "lib/hiddifycore/core_interface/core_interface_mobile.dart" => ["e0672d710ce7341cde00e6543458e2ed6ab5a6948c389ff45dcc7788c19baf26", "76460b9358ab9099288d162199ae97544efe9689dc2f080bb3eda0973a03c6b0"],
    "ios/Runner/Handlers/MethodHandler.swift" => ["288bcd062d01bd336e97346a0b160e5e45f772956380c1c7392b04a6771e0006", "0b31cee80b348c6e3cbf31bf0abc9187d58d0665ccbbde81758fd03813ae1195"],
  }.freeze
  IOS_STARTUP_NEW_SHA256 = {
    "lib/features/app/startup/ios_startup_gate.dart" => "9073defe1819cc9801ea3e3a5495947970c40ea60df175a664206c715a6a87db",
  }.freeze

  def approved_ios_startup_change?(path, trusted_source, current_source)
    fingerprints = IOS_STARTUP_SOURCE_SHA256[path]
    fingerprints &&
      Digest::SHA256.hexdigest(trusted_source) == fingerprints.fetch(0) &&
      Digest::SHA256.hexdigest(current_source) == fingerprints.fetch(1)
  end

  def approved_native_glass_host_change?(path, trusted_source, current_source)
    fingerprints = NATIVE_GLASS_HOST_SHA256[path]
    fingerprints &&
      Digest::SHA256.hexdigest(trusted_source) == fingerprints.fetch(0) &&
      Digest::SHA256.hexdigest(current_source) == fingerprints.fetch(1)
  end

  def approved_release_change?(path, trusted_source, current_source)
    fingerprints = RELEASE_SOURCE_SHA256[path]
    fingerprints &&
      Digest::SHA256.hexdigest(trusted_source) == fingerprints.fetch(0) &&
      Digest::SHA256.hexdigest(current_source) == fingerprints.fetch(1)
  end

  def test_release_fingerprints_reject_unreviewed_bytes_and_paths
    RELEASE_SOURCE_SHA256.each do |path, _|
      trusted = git("show", "#{BASELINE}:#{path}")
      current = File.binread(File.join(ROOT, path))
      assert approved_release_change?(path, trusted, current), path
      refute approved_release_change?(path, trusted + " ", current), path
      refute approved_release_change?(path, trusted, current + " "), path
      refute approved_release_change?("#{path}.unreviewed", trusted, current), path
    end
  end

  def test_release_additions_match_reviewed_fingerprints
    RELEASE_NEW_SHA256.each do |path, expected|
      assert_equal expected, Digest::SHA256.file(File.join(ROOT, path)).hexdigest, path
      refute_equal expected, Digest::SHA256.hexdigest(File.binread(File.join(ROOT, path)) + " "), path
      refute RELEASE_NEW_SHA256.key?("#{path}.unreviewed"), path
    end
  end

  def test_native_glass_allowlist_accepts_only_the_frozen_host_changes
    NATIVE_GLASS_HOST_SHA256.each_key do |path|
      trusted = git("show", "#{BASELINE}:#{path}")
      current = File.binread(File.join(ROOT, path))
      assert approved_native_glass_host_change?(path, trusted, current), path
      refute approved_native_glass_host_change?(path, trusted + " ", current), path
      refute approved_native_glass_host_change?(path, trusted, current + " "), path
      refute approved_native_glass_host_change?("ios/Runner/Unapproved.swift", trusted, current), path
    end
    assert_equal NATIVE_GLASS_SHA256, Digest::SHA256.file(File.join(ROOT, NATIVE_GLASS_FILE)).hexdigest
    refute_equal NATIVE_GLASS_SHA256, Digest::SHA256.hexdigest(File.binread(File.join(ROOT, NATIVE_GLASS_FILE)) + " ")
  end

  def approved_ios_startup_addition?(path, current_source)
    fingerprint = IOS_STARTUP_NEW_SHA256[path]
    fingerprint && Digest::SHA256.hexdigest(current_source) == fingerprint
  end

  def test_ios_startup_existing_fingerprints_reject_unreviewed_bytes_and_paths
    IOS_STARTUP_SOURCE_SHA256.each_key do |path|
      trusted = git("show", "#{BASELINE}:#{path}")
      current = File.binread(File.join(ROOT, path))
      assert approved_ios_startup_change?(path, trusted, current), path
      refute approved_ios_startup_change?(path, trusted + " ", current), path
      refute approved_ios_startup_change?(path, trusted, current + " "), path
      refute approved_ios_startup_change?("#{path}.unreviewed", trusted, current), path
      refute approved_ios_startup_change?("lib/hiddifycore/unreviewed.dart", trusted, current), path
    end
  end

  def test_ios_startup_new_fingerprints_reject_unreviewed_bytes_and_paths
    IOS_STARTUP_NEW_SHA256.each_key do |path|
      current = File.binread(File.join(ROOT, path))
      assert approved_ios_startup_addition?(path, current), path
      refute approved_ios_startup_addition?(path, current + " "), path
      refute approved_ios_startup_addition?("#{path}.unreviewed", current), path
      refute allowed_addition?("#{path}/extra.dart"), path
    end
    refute allowed_addition?("lib/features/app/startup/unreviewed.dart")
    refute allowed_addition?("lib/features/app/startup/ios_startup_gate_extra.dart")
    refute approved_ios_startup_addition?("lib/features/app/startup/unreviewed.dart", "")
  end

  def approved_ios_measurement_change?(path, trusted_source, current_source)
    fingerprints = IOS_MEASUREMENT_SOURCE_SHA256[path]
    fingerprints &&
      Digest::SHA256.hexdigest(trusted_source) == fingerprints.fetch(0) &&
      Digest::SHA256.hexdigest(current_source) == fingerprints.fetch(1)
  end

  def approved_ios_measurement_addition?(path, current_source)
    fingerprint = IOS_MEASUREMENT_NEW_SHA256[path]
    fingerprint && Digest::SHA256.hexdigest(current_source) == fingerprint
  end

  def test_ios_measurement_existing_fingerprints_reject_unreviewed_bytes_and_paths
    IOS_MEASUREMENT_SOURCE_SHA256.each_key do |path|
      trusted = git("show", "#{BASELINE}:#{path}")
      current = File.binread(File.join(ROOT, path))
      assert approved_ios_measurement_change?(path, trusted, current), path
      refute approved_ios_measurement_change?(path, trusted + " ", current), path
      refute approved_ios_measurement_change?(path, trusted, current + " "), path
      refute approved_ios_measurement_change?("lib/features/proxy/active/unreviewed.dart", trusted, current)
    end
  end

  def test_ios_measurement_new_fingerprints_reject_unreviewed_bytes_and_paths
    IOS_MEASUREMENT_NEW_SHA256.each_key do |path|
      current = File.binread(File.join(ROOT, path))
      assert approved_ios_measurement_addition?(path, current), path
      refute approved_ios_measurement_addition?(path, current + " "), path
      refute approved_ios_measurement_addition?("lib/features/proxy/active/unreviewed.dart", current)
    end
    refute allowed_addition?("lib/features/proxy/active/unreviewed.dart")
    refute allowed_addition?("lib/features/proxy/active/ios_active_proxy_measurement_extra.dart")
    refute allowed_addition?("lib/features/proxy/active/ios_active_proxy_measurement.dart/extra.dart")
  end

  def test_new_diagnostic_sources_match_reviewed_fingerprints
    assert_equal DIAGNOSTIC_NEW_FILES.sort, DIAGNOSTIC_NEW_SHA256.keys.sort
    DIAGNOSTIC_NEW_SHA256.each do |path, expected|
      assert_equal expected, Digest::SHA256.file(File.join(ROOT, path)).hexdigest, path
    end
  end

  def approved_diagnostic_change?(path, trusted_source, current_source)
    fingerprints = DIAGNOSTIC_SOURCE_SHA256[path]
    fingerprints &&
      Digest::SHA256.hexdigest(trusted_source) == fingerprints.fetch(0) &&
      Digest::SHA256.hexdigest(current_source) == fingerprints.fetch(1)
  end

  def test_diagnostic_fingerprints_reject_unreviewed_bytes_and_paths
    assert_equal DIAGNOSTIC_EXISTING_FILES.sort, DIAGNOSTIC_SOURCE_SHA256.keys.sort
    DIAGNOSTIC_SOURCE_SHA256.each do |path, _|
      trusted = git("show", "#{BASELINE}:#{path}")
      current = File.binread(File.join(ROOT, path))
      assert approved_diagnostic_change?(path, trusted, current), path
      refute approved_diagnostic_change?(path, trusted, current + " "), path
      refute approved_diagnostic_change?(path, trusted + " ", current), path
      refute approved_diagnostic_change?("ios/Runner/Unapproved.swift", trusted, current)
    end
  end

  def test_diagnostics_do_not_allow_vpn_policy_identity_or_pipeline_changes
    %w[
      lib/features/connection/data/connection_repository.dart
      lib/features/connection/notifier/connection_notifier.dart
      lib/hiddifycore/hiddify_core_service.dart
      ios/Runner/VPN/MethodHandler.swift
      ios/Runner/Info.plist
      ios/Runner/Runner.entitlements
      .github/workflows/ios-baseline.yml
      pubspec.yaml pubspec.lock
    ].each do |path|
      refute DIAGNOSTIC_SOURCE_SHA256.key?(path), path
      refute DIAGNOSTIC_NEW_FILES.include?(path), path
      refute approved_diagnostic_change?(path, "old", "new"), path
    end
    refute allowed_addition?("lib/features/diagnostics/unreviewed.dart")
  end

  def git(*args)
    output, status = Open3.capture2("git", "-C", ROOT, *args)
    assert status.success?, "Git read failed: #{args.first}"
    output
  end

  def allowed_ui?(path)
    UI_FILES.include?(path) || UI_PREFIXES.any? { |prefix| path.start_with?(prefix) }
  end

  def approved_protected_change?(path, trusted_source, current_source)
    approved_log_removal = trusted_source.sub(APPROVED_RAW_LOG_LINE, "")
    path == PROFILE_DETAILS_NOTIFIER &&
      trusted_source.scan(APPROVED_RAW_LOG_LINE).length == 1 &&
      trusted_source.scan(TRUSTED_PARSE_ERROR_LINE).length == 1 &&
      [
        approved_log_removal,
        approved_log_removal.sub(TRUSTED_PARSE_ERROR_LINE, APPROVED_PARSE_ERROR_LINE),
      ].include?(current_source)
  end

  def trusted_profile_details_notifier
    git("show", "#{BASELINE}:#{PROFILE_DETAILS_NOTIFIER}")
  end

  def approved_profile_details_notifier
    trusted_profile_details_notifier.sub(APPROVED_RAW_LOG_LINE, "")
  end

  def approved_private_profile_details_notifier
    approved_profile_details_notifier.sub(TRUSTED_PARSE_ERROR_LINE, APPROVED_PARSE_ERROR_LINE)
  end

  def test_exact_profile_raw_log_removal_is_approved
    assert approved_protected_change?(
      PROFILE_DETAILS_NOTIFIER,
      trusted_profile_details_notifier,
      approved_profile_details_notifier,
    )
  end

  def test_exact_profile_raw_log_removal_and_safe_parse_error_replacement_is_approved
    assert approved_protected_change?(
      PROFILE_DETAILS_NOTIFIER,
      trusted_profile_details_notifier,
      approved_private_profile_details_notifier,
    )
  end

  def test_profile_raw_log_removal_is_not_approved_for_another_file
    refute approved_protected_change?(
      "lib/features/profile/details/profile_details_state.dart",
      trusted_profile_details_notifier,
      approved_profile_details_notifier,
    )
  end

  def test_profile_raw_log_removal_with_an_extra_body_change_is_rejected
    unsafe = approved_profile_details_notifier.sub("import 'dart:convert';", "import 'dart:async';")
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_safe_parse_error_replacement_with_an_extra_body_change_is_rejected
    unsafe = approved_private_profile_details_notifier.sub("import 'dart:convert';", "import 'dart:async';")
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_original_profile_raw_log_is_rejected
    refute approved_protected_change?(
      PROFILE_DETAILS_NOTIFIER,
      trusted_profile_details_notifier,
      trusted_profile_details_notifier,
    )
  end

  def test_relocated_profile_raw_log_is_rejected
    unsafe = approved_profile_details_notifier + APPROVED_RAW_LOG_LINE
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_replaced_profile_raw_log_is_rejected
    unsafe = trusted_profile_details_notifier.sub(APPROVED_RAW_LOG_LINE, "      loggy.debug(profContent);\n")
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_duplicated_profile_raw_log_is_rejected
    unsafe = trusted_profile_details_notifier.sub(APPROVED_RAW_LOG_LINE, APPROVED_RAW_LOG_LINE * 2)
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_reintroduced_raw_parse_error_is_rejected_from_safe_variant
    unsafe = approved_private_profile_details_notifier + TRUSTED_PARSE_ERROR_LINE
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_parse_error_to_string_is_rejected
    unsafe = approved_profile_details_notifier.sub(
      TRUSTED_PARSE_ERROR_LINE,
      "      loggy.error('Error parsing profile-content JSON (${e.toString()})', null, st);\n",
    )
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_parse_error_message_is_rejected
    unsafe = approved_profile_details_notifier.sub(
      TRUSTED_PARSE_ERROR_LINE,
      "      loggy.error('Error parsing profile-content JSON (${e.message})', null, st);\n",
    )
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_safe_parse_error_with_altered_stack_is_rejected
    unsafe = approved_profile_details_notifier.sub(
      TRUSTED_PARSE_ERROR_LINE,
      "      loggy.error('Error parsing profile-content JSON (${e.runtimeType})', null, StackTrace.current);\n",
    )
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_safe_parse_error_without_stack_is_rejected
    unsafe = approved_profile_details_notifier.sub(
      TRUSTED_PARSE_ERROR_LINE,
      "      loggy.error('Error parsing profile-content JSON (${e.runtimeType})', null);\n",
    )
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_relocated_safe_parse_error_is_rejected
    unsafe = approved_profile_details_notifier.sub(TRUSTED_PARSE_ERROR_LINE, "") + APPROVED_PARSE_ERROR_LINE
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_duplicated_safe_parse_error_is_rejected
    unsafe = approved_profile_details_notifier.sub(TRUSTED_PARSE_ERROR_LINE, APPROVED_PARSE_ERROR_LINE * 2)
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_changed_trusted_raw_log_multiplicity_is_rejected
    changed_trusted_source = trusted_profile_details_notifier.sub(
      APPROVED_RAW_LOG_LINE,
      APPROVED_RAW_LOG_LINE * 2,
    )
    candidate = changed_trusted_source.sub(APPROVED_RAW_LOG_LINE, "")
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, changed_trusted_source, candidate)
  end

  def test_missing_trusted_parse_error_line_is_rejected
    changed_trusted_source = trusted_profile_details_notifier.sub(TRUSTED_PARSE_ERROR_LINE, "")
    candidate = changed_trusted_source.sub(APPROVED_RAW_LOG_LINE, "")
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, changed_trusted_source, candidate)
  end

  def test_repeated_trusted_parse_error_line_is_rejected
    changed_trusted_source = trusted_profile_details_notifier.sub(
      TRUSTED_PARSE_ERROR_LINE,
      TRUSTED_PARSE_ERROR_LINE * 2,
    )
    candidate = changed_trusted_source.sub(APPROVED_RAW_LOG_LINE, "")
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, changed_trusted_source, candidate)
  end

  def test_any_additional_byte_in_approved_profile_source_is_rejected
    unsafe = approved_profile_details_notifier + " "
    refute approved_protected_change?(PROFILE_DETAILS_NOTIFIER, trusted_profile_details_notifier, unsafe)
  end

  def test_all_existing_runtime_native_identity_and_pipeline_files_outside_ui_are_unchanged
    paths = git("ls-tree", "-r", "--name-only", BASELINE).lines.map(&:strip)
    protected_paths = paths.select do |path|
      !path.start_with?("docs/", "test/") && !allowed_ui?(path) && !%w[pubspec.yaml pubspec.lock].include?(path)
    end
    changed = git("diff", "--name-only", BASELINE, "--", *protected_paths).lines.map(&:strip)
    changed.reject! do |path|
      current_path = File.join(ROOT, path)
      File.file?(current_path) &&
        (approved_protected_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)) ||
         approved_diagnostic_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)) ||
         approved_ios_measurement_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)) ||
         approved_ios_startup_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)) ||
         approved_native_glass_host_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)) ||
         approved_release_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)))
    end
    assert_empty changed, "Protected runtime/native/dependency/identity files changed: #{changed.join(', ')}"
  end

  # Test hosts are created outside the repository; only their reviewed runners
  # and integration entry point may be added here. No blanket scripts allowance.
  NEW_TOOL_FILES = %w[scripts/blizzard_prepare_test_host.py scripts/blizzard_simulator_run.py
                     scripts/ui_test_simulator_id.py integration_test/blizzard_preservation_test.dart integration_test/blizzard_v3_geometry_test.dart].freeze

  def allowed_addition?(path)
    path == "assets/images/blizzard_wave_envelope.png" || path.start_with?("test/", "docs/") || NEW_TOOL_FILES.include?(path) || path == NATIVE_GLASS_FILE ||
      DIAGNOSTIC_NEW_FILES.include?(path) || RELEASE_NEW_SHA256.key?(path) ||
      IOS_MEASUREMENT_NEW_SHA256.key?(path) || IOS_STARTUP_NEW_SHA256.key?(path) || NEW_UI_FILES.include?(path) ||
      NEW_UI_PREFIXES.any? { |prefix| path.start_with?(prefix) }
  end

  def unexpected_additions(current, baseline)
    (current - baseline).uniq.reject { |path| allowed_addition?(path) }
  end

  def test_new_repository_files_are_only_explicitly_approved
    paths = git("ls-files", "--cached", "--others", "--exclude-standard").lines.map(&:strip)
    old = git("ls-tree", "-r", "--name-only", BASELINE).lines.map(&:strip)
    unexpected = unexpected_additions(paths, old)
    assert_empty unexpected, "Unexpected new repository files: #{unexpected.join(', ')}"
  end

  def test_new_native_and_workflow_additions_are_detected
    old = %w[lib/main.dart ios/Runner/AppDelegate.swift]
    additions = %w[ios/Runner/Unapproved.swift .github/workflows/unapproved.yml]
    assert_equal additions, unexpected_additions(old + additions, old)
    assert_empty unexpected_additions(old + %w[test/new_test.dart docs/evidence.json] + NEW_TOOL_FILES, old)
    refute allowed_addition?("scripts/arbitrary-release.py")
    refute allowed_addition?("integration_test/ios/Runner/AppDelegate.swift")
    refute allowed_addition?("lib/features/profile/notifier/new_runtime.dart")
  end

  def test_runtime_dependency_declarations_and_sdk_constraints_are_identical
    before = YAML.safe_load(git("show", "#{BASELINE}:pubspec.yaml"))
    after = YAML.safe_load(File.read(File.join(ROOT, "pubspec.yaml")))
    %w[name environment dependencies dependency_overrides].each do |key|
      assert_equal before[key], after[key], "Changed runtime manifest field: #{key}"
    end
    expected_flutter = Marshal.load(Marshal.dump(before.fetch("flutter")))
    expected_flutter.fetch("assets").unshift("assets/images/blizzard_wave_envelope.png")
    assert_equal expected_flutter, after.fetch("flutter"), "Only the reviewed v3 wave asset may be added"
    assert_equal "5bca6e7c672919e0bc63f30e5048816f6285869b97a5b92e382e00f16bf6d3ea", Digest::SHA256.file(File.join(ROOT, "assets/images/blizzard_wave_envelope.png")).hexdigest
    delta = after.fetch("dev_dependencies").keys - before.fetch("dev_dependencies").keys
    assert_equal %w[flutter_test integration_test], delta.sort
    before.fetch("dev_dependencies").each do |key, value|
      assert_equal value, after.fetch("dev_dependencies")[key], "Existing dev tool changed: #{key}"
    end
  end

  def test_existing_resolved_packages_do_not_upgrade_and_additions_are_test_only
    before = YAML.safe_load(git("show", "#{BASELINE}:pubspec.lock"))
    after = YAML.safe_load(File.read(File.join(ROOT, "pubspec.lock")))
    before.fetch("packages").each do |name, package|
      actual = after.fetch("packages")[name]
      refute_nil actual, "Removed resolved package: #{name}"
      expected = package.dup
      expected["dependency"] = "direct dev" if name == "flutter_test"
      assert_equal expected, actual, "Changed resolved package: #{name}"
    end
    assert_equal DEV_ADDITIONS.sort, (after.fetch("packages").keys - before.fetch("packages").keys).sort
    assert_equal before.fetch("sdks"), after.fetch("sdks")
  end

  def test_hydrated_core_framework_matches_baseline_bytes
    receipt = JSON.parse(File.read(File.join(ROOT, "docs/verification/blizzard/native-framework-hydration.json")))
    refute_empty receipt.fetch("files")
    receipt.fetch("files").each do |entry|
      path = File.join(ROOT, "ios/Frameworks/HiddifyCore.xcframework", entry.fetch("path"))
      assert File.file?(path), "Missing baseline core file"
      assert_equal entry.fetch("sha256"), Digest::SHA256.file(path).hexdigest, "Core artifact changed"
    end
  end
end
