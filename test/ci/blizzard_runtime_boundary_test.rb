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

  def git(*args)
    output, status = Open3.capture2("git", "-C", ROOT, *args)
    assert status.success?, "Git read failed: #{args.first}"
    output
  end

  def allowed_ui?(path)
    UI_FILES.include?(path) || UI_PREFIXES.any? { |prefix| path.start_with?(prefix) }
  end

  def approved_protected_change?(path, trusted_source, current_source)
    path == PROFILE_DETAILS_NOTIFIER &&
      trusted_source.scan(APPROVED_RAW_LOG_LINE).length == 1 &&
      current_source == trusted_source.sub(APPROVED_RAW_LOG_LINE, "")
  end

  def trusted_profile_details_notifier
    git("show", "#{BASELINE}:#{PROFILE_DETAILS_NOTIFIER}")
  end

  def approved_profile_details_notifier
    trusted_profile_details_notifier.sub(APPROVED_RAW_LOG_LINE, "")
  end

  def test_exact_profile_raw_log_removal_is_approved
    assert approved_protected_change?(
      PROFILE_DETAILS_NOTIFIER,
      trusted_profile_details_notifier,
      approved_profile_details_notifier,
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

  def test_changed_trusted_raw_log_multiplicity_is_rejected
    changed_trusted_source = trusted_profile_details_notifier.sub(
      APPROVED_RAW_LOG_LINE,
      APPROVED_RAW_LOG_LINE * 2,
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
        approved_protected_change?(path, git("show", "#{BASELINE}:#{path}"), File.binread(current_path))
    end
    assert_empty changed, "Protected runtime/native/dependency/identity files changed: #{changed.join(', ')}"
  end

  # Test hosts are created outside the repository; only their reviewed runners
  # and integration entry point may be added here. No blanket scripts allowance.
  NEW_TOOL_FILES = %w[scripts/blizzard_prepare_test_host.py scripts/blizzard_simulator_run.py
                     scripts/ui_test_simulator_id.py integration_test/blizzard_preservation_test.dart].freeze

  def allowed_addition?(path)
    path.start_with?("test/", "docs/") || NEW_TOOL_FILES.include?(path) ||
      NEW_UI_FILES.include?(path) || NEW_UI_PREFIXES.any? { |prefix| path.start_with?(prefix) }
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
