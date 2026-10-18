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
  NEW_UI_FILES = %w[lib/core/theme/blizzard_tokens.dart lib/core/theme/blizzard_theme.dart].freeze
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
    "assets/translations/en.i18n.json" => ["d1bdfe06b016b0e72828f4a5c980d8e1ae4146983ddd3d7630a1861bfd448acc", "9feb87b6ba90df93815f65f801cd84625954876da6d0c3174cc45af4600a4514"],
    "assets/translations/ru.i18n.json" => ["218e2472e8eeca970a0ff160e612e87904f09cc8f4fba7ca4f351df47a0c35c5", "11c8fd4330e7a755cc727b26d058d99c2bc6c0a85833bdb0c4688880f22da283"],
    "ios/HiddifyPacketTunnel/Logger.swift" => ["197a03eb1212f113e934b913525a6d329e2ec5538b97bf71a3296571c07499a7", "dd25284df008b05268740bbd720969eb337982eece068819002a20b8a58a8964"],
    "ios/HiddifyPacketTunnel/SingBox/ExtensionProvider.swift" => ["5d34a57ef76d904bece6462519d340c7ff217b57ff3237bb82e69d82b1a28848", "8876aae20b2e98c0cef2abf66b82080461f770e5b007d0eba9ff547e9880f4aa"],
    "ios/Runner/VPN/VPNManager.swift" => ["9f207ded470097e274e1cdb4d238fe1734d57ac4ae452e9844de0a89dfa86dff", "c3280f57717125360da2045537a95aa68a9d841e1b099809fc0d5f1648de9ae4"],
    "lib/core/analytics/analytics_controller.dart" => ["2a84ad1b04bd809c2641605c070c9c2baae0bcb67c896e02604d8c35d9d02498", "88529f0bdebb1f5e770599b08b085bafae252efb48d7740e8769392a30f70c42"],
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
  ].freeze
  DIAGNOSTIC_NEW_SHA256 = {
    "lib/core/logger/safe_log_record.dart" => "57137aee501d92bd54129bc3ce34814efabb2a96f6dd5deab5c48040019b183a",
    "lib/features/diagnostics/safe_diagnostic_event.dart" => "867a3fc3c57f729b0de11787f130e18ed2cabc66cbfd36a3344a3a9f1e7a66a6",
    "lib/features/diagnostics/safe_diagnostic_journal.dart" => "3de4fcbb9856734766436b743717fc5be19b14a9da142f94d680ea1106773c85",
    "lib/features/diagnostics/home_presentation_snapshot.dart" => "2e816bf1093b990599747c3860138d489f1a520667c0bbb093ca930289913ded",
    "lib/features/diagnostics/home_presentation_providers.dart" => "43cb56211b4055a2ebf41abb2097d754be3f589d56b377f06c3450b6f3433602",
    "lib/features/diagnostics/home_presentation_probe.dart" => "f51164d3f3433f0ff3c9ebffdc82de291cc38382f93e7200c28f938bec5bc728",
    "lib/features/diagnostics/observed_connection_repository.dart" => "8bd1bdcc05099863f93641b08a16a21e3d3b209f0736ea1cb9df35fc922e8cb1",
    "lib/features/diagnostics/diagnostic_providers.dart" => "b8757034cb108efe7be93b1f1eabf46b5be89a0e725653c82294b3d7ba9144d4",
    "lib/features/diagnostics/safe_diagnostics_page.dart" => "c1604dd46656c39a8c38e5b3cf5b5d9ed343a08c41f23c9133c75aa5ac093d9c",
  }.freeze

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
         approved_diagnostic_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path)))
    end
    assert_empty changed, "Protected runtime/native/dependency/identity files changed: #{changed.join(', ')}"
  end

  # Test hosts are created outside the repository; only their reviewed runners
  # and integration entry point may be added here. No blanket scripts allowance.
  NEW_TOOL_FILES = %w[scripts/blizzard_prepare_test_host.py scripts/blizzard_simulator_run.py
                     scripts/ui_test_simulator_id.py integration_test/blizzard_preservation_test.dart].freeze

  def allowed_addition?(path)
    path.start_with?("test/", "docs/") || NEW_TOOL_FILES.include?(path) ||
      DIAGNOSTIC_NEW_FILES.include?(path) || NEW_UI_FILES.include?(path) || NEW_UI_PREFIXES.any? { |prefix| path.start_with?(prefix) }
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
    assert_equal before.fetch("flutter"), after.fetch("flutter"), "Assets/fonts require an explicit reviewed allowance"
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
