# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "yaml"

class IOSBaselineWorkflowTest < Minitest::Test
  WORKFLOW_PATH = File.expand_path(
    ENV.fetch("IOS_BASELINE_WORKFLOW_PATH", "../../.github/workflows/ios-baseline.yml"),
    __dir__
  )
  ALLOWED_JOB_PERMISSIONS = { "contents" => "read" }.freeze
  PROTECTED_ENVIRONMENTS = %w[release-signing release-publish].freeze
  BASELINE_BUNDLE_ID = "com.womaninred.baseline"
  TEMPORARY_TRUSTED_SOURCE_SHA = "4fdbd94a6a3a4bf6bbb46e95c30d1e2ec2fc6870"
  ORIGINAL_RELEASE_SOURCE_SHA = "e53431419478359ac48d217ac6d2cbc2ddcb7b4d"
  EXPECTED_RELEASE_SOURCE_SHA = ENV.fetch("IOS_BASELINE_EXPECTED_RELEASE_SOURCE_SHA", ORIGINAL_RELEASE_SOURCE_SHA)
  EXPECTED_TRUSTED_SOURCE_SHA = ENV.fetch(
    "IOS_BASELINE_EXPECTED_TRUSTED_SOURCE_SHA",
    TEMPORARY_TRUSTED_SOURCE_SHA
  )
  FORBIDDEN_IDENTITIES = %w[
    com.womaninred.app
    apple.hiddify.com
    group.com.womaninred.app
    group.apple.hiddify.com
  ].freeze

  def setup
    unless File.file?(WORKFLOW_PATH)
      return if name == "test_dedicated_workflow_exists"

      skip "ios-baseline workflow is intentionally absent until U4"
    end

    @source = File.read(WORKFLOW_PATH)
    parsed = YAML.safe_load(
      @source,
      permitted_classes: [],
      permitted_symbols: [],
      aliases: false
    )
    @workflow = normalize_yaml_keys(parsed)
  end

  def test_dedicated_workflow_exists
    assert File.file?(WORKFLOW_PATH),
      "missing #{relative_workflow_path}; U2 expects this RED before U4 creates production workflow"
  end

  def test_is_manual_and_ios_only_with_explicit_release_inputs
    triggers = @workflow.fetch("on")
    assert_equal ["workflow_dispatch"], triggers.keys,
      "non_ios_workflow_path: baseline release must be a separate manual workflow"

    inputs = triggers.fetch("workflow_dispatch").fetch("inputs")
    assert_required_string_input(inputs, "sourceSHA")
    assert_required_string_input(inputs, "version")
    assert_required_string_input(inputs, "buildNumber")

    metadata_public_key = inputs.fetch("metadataPublicKey")
    assert_equal false, metadata_public_key.fetch("required")
    assert_equal "string", metadata_public_key.fetch("type")
    refute metadata_public_key.key?("default"),
      "metadataPublicKey must be supplied explicitly for metadata operations"

    operation = inputs.fetch("operation")
    assert_equal true, operation.fetch("required")
    assert_equal "choice", operation.fetch("type")
    assert_equal %w[upload status metadata], operation.fetch("options")
    refute inputs.key?("platform"),
      "non_ios_workflow_path: this workflow must not accept another platform"

    jobs.each_value do |job|
      next unless job.key?("runs-on")

      assert_match(/macos/, job.fetch("runs-on").to_s,
        "non_ios_workflow_path: every executable baseline job must run on macOS")
    end
  end

  def test_exact_sha_is_validated_before_checkout_and_sensitive_use
    validation_jobs = jobs.each_with_object([]) do |(job_name, job), names|
      names << job_name if steps(job).any? { |step| exact_sha_validation_step?(step) }
    end
    refute_empty validation_jobs,
      "source_sha_not_exact: validate sourceSHA as 40 lowercase hex and match the reviewed trusted SHA"

    jobs.each do |job_name, job|
      checkout_index = steps(job).index { |step| checkout_step?(step) }
      sensitive = job_uses_secrets?(job) || PROTECTED_ENVIRONMENTS.include?(environment_name(job))
      next unless checkout_index || sensitive

      local_validation_index = steps(job).index { |step| exact_sha_validation_step?(step) }
      locally_precedes = local_validation_index && (!checkout_index || local_validation_index < checkout_index)
      dependency_precedes = validation_jobs.any? { |candidate| job_depends_on?(job_name, candidate) }

      assert locally_precedes || dependency_precedes,
        "source_sha_not_exact: #{job_name} reaches checkout/secrets before exact sourceSHA validation"
    end

    validation_jobs.each do |job_name|
      refute job_uses_secrets?(jobs.fetch(job_name)),
        "source_sha_not_exact: validation job #{job_name} must not receive secrets"
    end
  end

  def test_every_checkout_uses_exact_ref_without_credentials
    checkouts = all_steps.select { |_job_name, step| checkout_step?(step) }
    refute_empty checkouts, "source_sha_not_exact: workflow must check out the requested source"

    checkouts.each do |job_name, step|
      with = step.fetch("with", {})
      assert_equal "${{ inputs.sourceSHA }}", with.fetch("ref", nil),
        "source_sha_not_exact: checkout in #{job_name} must use the exact dispatch sourceSHA"
      assert_equal false, with.fetch("persist-credentials", nil),
        "checkout_credentials_persisted: checkout in #{job_name} must disable persisted credentials"
    end
  end

  def test_sha_validation_rejects_invalid_and_unreviewed_inputs
    validations = all_steps.map(&:last).select { |step| exact_sha_validation_step?(step) }
    refute_empty validations, "reviewed source validation must exist"
    validations.each do |step|
      env = step.fetch("env")
      trusted_metadata = env.fetch("TRUSTED_SOURCE_SHA")
      trusted_release = env.fetch("TRUSTED_RELEASE_SOURCE_SHA")
      third_sha = ("a" * 40 == trusted_metadata || "a" * 40 == trusted_release) ? "b" * 40 : "a" * 40
      candidates = {
        ["metadata", trusted_metadata] => true,
        ["upload", trusted_release] => true,
        ["status", trusted_release] => true,
        ["metadata", trusted_release] => false,
        ["upload", trusted_metadata] => false,
        ["status", trusted_metadata] => false,
        ["metadata", third_sha] => false,
        ["upload", third_sha] => false,
        ["delete", trusted_metadata] => false,
        ["metadata", ""] => false,
        ["metadata", "main"] => false,
        ["metadata", trusted_metadata[0, 39]] => false,
        ["metadata", "g" * 40] => false
      }
      candidates.each do |(operation, source), accepted|
        _stdout, _stderr, status = Open3.capture3(
          {
            "PATH" => "/usr/bin:/bin",
            "SOURCE_SHA" => source,
            "OPERATION" => operation,
            "TRUSTED_SOURCE_SHA" => trusted_metadata,
            "TRUSTED_RELEASE_SOURCE_SHA" => trusted_release
          },
          "/bin/bash", "-e", "-o", "pipefail", "-c", step.fetch("run"),
          unsetenv_others: true
        )
        assert_equal accepted, status.success?,
          "validation must route #{operation.inspect} only to its exact reviewed SHA; input #{source.inspect}"
      end
    end
  end

  def test_reviewed_source_pin_is_explicit_and_test_harness_can_verify_bootstrap_workflow
    validations = all_steps.map(&:last).select { |step| exact_sha_validation_step?(step) }
    refute_empty validations
    validations.each do |step|
      env = step.fetch("env")
      assert_equal EXPECTED_TRUSTED_SOURCE_SHA, env.fetch("TRUSTED_SOURCE_SHA")
      assert_equal EXPECTED_RELEASE_SOURCE_SHA, env.fetch("TRUSTED_RELEASE_SOURCE_SHA")
      assert_equal "${{ inputs.operation }}", env.fetch("OPERATION")
    end
    assert_equal File.expand_path(ENV.fetch("IOS_BASELINE_WORKFLOW_PATH", WORKFLOW_PATH), __dir__), WORKFLOW_PATH
  end

  def test_all_external_actions_are_pinned_to_full_commit_shas
    action_uses = all_steps.each_with_object([]) do |(job_name, step), uses|
      uses << [job_name, step.fetch("uses").to_s] if step.key?("uses")
    end
    jobs.each do |job_name, job|
      action_uses << [job_name, job.fetch("uses").to_s] if job.key?("uses")
    end
    external_actions = action_uses.reject { |_job_name, action| action.start_with?("./") }
    refute_empty external_actions, "action_ref_mutable: workflow is expected to use pinned actions"

    external_actions.each do |job_name, action|
      assert_match(%r{\A[^\s@]+@[0-9a-f]{40}\z}, action,
        "action_ref_mutable: #{job_name} uses #{action.inspect} instead of a full commit SHA")
    end
  end

  def test_workflow_and_jobs_have_minimal_permissions
    assert_equal({}, @workflow.fetch("permissions", nil),
      "workflow_permissions_excessive: top-level permissions must be empty")

    jobs.each do |job_name, job|
      permissions = job.fetch("permissions", nil)
      assert_kind_of Hash, permissions,
        "workflow_permissions_excessive: #{job_name} must declare job permissions"
      permissions.each do |scope, access|
        assert_equal ALLOWED_JOB_PERMISSIONS[scope], access,
          "workflow_permissions_excessive: #{job_name} requests #{scope}: #{access}"
      end
    end
  end

  def test_signing_and_publish_secrets_are_protected_and_main_only
    secret_jobs = jobs.select { |_job_name, job| job_uses_secrets?(job) }
    refute_empty secret_jobs,
      "secret_environment_unprotected: release workflow must contain protected signing/publish work"

    secret_jobs.each do |job_name, job|
      assert_includes PROTECTED_ENVIRONMENTS, environment_name(job),
        "secret_environment_unprotected: #{job_name} exposes release secrets outside a protected environment"
      assert_includes job.fetch("if", "").to_s, "github.ref == 'refs/heads/main'",
        "secret_environment_unprotected: #{job_name} must only expose release secrets from main"
    end

    jobs.each do |job_name, job|
      next unless PROTECTED_ENVIRONMENTS.include?(environment_name(job))

      assert job_uses_secrets?(job),
        "secret_environment_unprotected: protected job #{job_name} has no narrowly scoped secret work"
    end
  end

  def test_every_credential_job_checks_environment_readiness_before_secret_work
    jobs.each do |job_name, job|
      next unless job_uses_secrets?(job)

      first = steps(job).first
      env = first.fetch("env", {})
      run = first.fetch("run", "").to_s
      expected = "RELEASE_ENVIRONMENT_READY"
      assert_equal "${{ vars.#{expected} }}", env.fetch(expected, nil),
        "#{job_name} must gate its protected environment before credential-bearing steps"
      assert_includes run, "$#{expected}"
      assert_includes run, "true"
      refute first.to_s.include?("secrets."), "#{job_name} readiness gate must not receive credentials"
    end
  end

  def test_protected_group_and_tester_secrets_are_scoped_only_to_release_helper_steps
    %w[IOS_BASELINE_TESTER_GROUP_ID IOS_BASELINE_SELF_TESTER_ID].each do |secret_name|
      jobs.each do |job_name, job|
        refute_includes job.fetch("env", {}).to_s, "secrets.#{secret_name}",
          "#{job_name} must not expose #{secret_name} to every action in the job"
        steps(job).each do |step|
          next unless step.to_s.include?("secrets.#{secret_name}")

          assert_match(%r{ruby\s+scripts/ios_baseline_release\.rb\s+(?:preflight|upload|status)\b}, step.fetch("run", ""),
            "#{secret_name} must only reach the first-party release helper")
        end
      end
    end
  end

  def test_unprotected_source_tests_precede_every_credential_job
    test_job_name, test_job = jobs.find do |_job_name, job|
      text = steps(job).map { |step| step.fetch("run", "").to_s }.join("\n")
      text.include?("ios_baseline_release_test.rb") && text.include?("flutter test")
    end
    refute_nil test_job, "trusted source must pass local contract tests before protected environments"
    assert_nil environment_name(test_job)
    refute job_uses_secrets?(test_job)
    assert job_depends_on?(test_job_name, "validate-source")

    upload_secret_jobs = jobs.select do |_job_name, job|
      steps(job).any? do |step|
        %w[preflight upload].any? { |operation| release_helper_command(step, operation) }
      end || environment_name(job) == "release-signing"
    end

    upload_secret_jobs.each do |job_name, _job|
      assert job_depends_on?(job_name, test_job_name),
        "#{job_name} must depend on the unprotected source test gate"
    end
  end

  def test_manual_vpn_policy_harness_runs_before_credentials_and_signing
    test_job_name, test_job = jobs.find do |_job_name, job|
      text = steps(job).map { |step| step.fetch("run", "").to_s }.join("\n")
      text.include?("ios_baseline_release_test.rb") && text.include?("flutter test")
    end
    refute_nil test_job, "trusted source test gate is missing"

    harness_steps = steps(test_job).select do |step|
      step.fetch("run", "").to_s.match?(%r{\bbash\s+test/ios/vpn_manager_manual_policy_test\.sh\b})
    end
    assert_equal 1, harness_steps.length,
      "test-source must run the native VPN manual-policy harness exactly once"
    assert_nil environment_name(test_job)
    refute job_uses_secrets?(test_job)

    credential_or_signing_jobs = jobs.select do |_job_name, job|
      steps(job).any? do |step|
        %w[preflight upload].any? { |operation| release_helper_command(step, operation) }
      end || environment_name(job) == "release-signing"
    end
    credential_or_signing_jobs.each_key do |job_name|
      assert job_depends_on?(job_name, test_job_name),
        "#{job_name} must depend on the native VPN manual-policy source gate"
    end
  end

  def test_full_source_tests_run_only_for_upload
    job_name, job = jobs.find do |_candidate_name, candidate|
      text = steps(candidate).map { |step| step.fetch("run", "").to_s }.join("\n")
      text.include?("flutter test") && text.include?("ios_baseline_workflow_test.rb")
    end
    refute_nil job
    assert_includes job.fetch("if", "").to_s, "inputs.operation == 'upload'",
      "full source tests in #{job_name} must not run for read-only metadata or status operations"
  end

  def test_metadata_has_an_unprotected_test_gate_before_credentials
    gate_name, gate = jobs.find do |_candidate_name, candidate|
      text = steps(candidate).map { |step| step.fetch("run", "").to_s }.join("\n")
      text.include?("ios_baseline_identity_inventory_test.rb") &&
        text.include?("ios_baseline_signed_entitlements_test.rb") &&
        text.include?("ios_baseline_release_test.rb") &&
        text.include?("ios_baseline_workflow_test.rb") &&
        !text.include?("flutter test")
    end
    refute_nil gate, "metadata must pass the four Ruby contract tests without a Flutter build"
    assert_nil environment_name(gate)
    refute job_uses_secrets?(gate)
    assert_includes gate.fetch("if", "").to_s, "inputs.operation == 'metadata'"
    assert job_depends_on?(gate_name, "validate-source")

    key_validation = steps(gate).find do |step|
      step.fetch("env", {}).fetch("METADATA_PUBLIC_KEY", nil) == "${{ inputs.metadataPublicKey }}"
    end
    refute_nil key_validation, "metadata public key must be validated before entering the protected job"
    assert_includes key_validation.fetch("run", ""), "METADATA_PUBLIC_KEY"
    assert_includes key_validation.fetch("run", ""), "3072"
    refute_includes key_validation.fetch("run", ""), "inputs.metadataPublicKey"

    metadata_job_name, metadata_job = metadata_release_job
    refute_nil metadata_job
    assert job_depends_on?(metadata_job_name, gate_name),
      "protected metadata lookup must depend on the unprotected metadata gate"
  end

  def test_each_credential_checkout_is_verified_before_first_secret_step
    jobs.each do |job_name, job|
      next unless job_uses_secrets?(job)

      checkout_index = steps(job).index { |step| checkout_step?(step) }
      secret_index = steps(job).index { |step| step.to_s.include?("secrets.") }
      verify_index = steps(job).index do |step|
        run = step.fetch("run", "").to_s
        run.include?("git rev-parse HEAD") && run.include?("SOURCE_SHA")
      end
      refute_nil checkout_index, "#{job_name} must use the reviewed checkout"
      refute_nil verify_index, "#{job_name} must verify checked-out HEAD"
      assert_operator checkout_index, :<, verify_index
      assert_operator verify_index, :<, secret_index
    end
  end

  def test_concurrency_and_artifact_names_are_baseline_specific
    concurrency = @workflow.fetch("concurrency")
    group = concurrency.is_a?(Hash) ? concurrency.fetch("group").to_s : concurrency.to_s
    assert_includes group.downcase, "ios-baseline"
    assert_includes group, "inputs.sourceSHA"
    refute_match(/release-?\$?\{?\{?\s*github\.ref/i, group,
      "baseline workflow must not share the old release concurrency key")

    artifact_steps = all_steps.select do |_job_name, step|
      step.fetch("uses", "").to_s.start_with?("actions/upload-artifact@")
    end
    refute_empty artifact_steps, "baseline workflow must retain its verified IPA as an artifact"

    artifact_steps.each do |job_name, step|
      artifact_name = step.fetch("with", {}).fetch("name", "").to_s
      assert_includes artifact_name.downcase, "ios-baseline",
        "artifact from #{job_name} must be baseline-specific"
      assert_includes artifact_name, "inputs.sourceSHA",
        "artifact from #{job_name} must identify its exact source"
      assert_includes artifact_name, "inputs.buildNumber",
        "artifact from #{job_name} must identify its explicit build number"
      refute_equal "Hiddify-iOS", artifact_name
    end
  end

  def test_version_and_build_number_are_explicit_and_never_auto_changed
    command_text = all_steps.map { |_job_name, step| step.fetch("run", "").to_s }.join("\n")
    assert_includes command_text, "--build-name \"$VERSION\""
    assert_includes command_text, "--build-number \"$BUILD_NUMBER\""

    build_step = all_steps.map(&:last).find do |step|
      step.fetch("run", "").to_s.include?("flutter build ipa")
    end
    refute_nil build_step, "workflow must create an iOS IPA explicitly"
    assert_equal "${{ inputs.version }}", build_step.fetch("env", {}).fetch("VERSION", nil)
    assert_equal "${{ inputs.buildNumber }}", build_step.fetch("env", {}).fetch("BUILD_NUMBER", nil)

    refute_match(/manageAppVersionAndBuildNumber\s*=\s*true|agvtool|increment|date\s*\+/i, command_text,
      "version/build must not be rewritten or synthesized in CI")
  end

  def test_pinned_toolchain_and_official_core_are_verified_before_build
    assert jobs.values.all? { |job| !job.key?("runs-on") || job.fetch("runs-on") == "macos-26" }
    assert_includes @source, "/Applications/Xcode_26.6.app/Contents/Developer"
    assert_includes @source, "3.38.5"
    assert_includes @source, "f6ff1529fd6d8af5f706051d9251ac9231c83407"
    assert_includes @source, "hiddify-core/releases/download/v4.1.0/hiddify-lib-ios.tar.gz"
    assert_includes @source, "31a03842df31fcebd8a1d43c883acd82f437639075815029f00859fb3470164b"
    assert_includes @source, "63496240"
    assert_includes @source, "scripts/prepare_ios_baseline_core.sh"
    assert_includes @source, "HiddifyCore.xcframework.sha256"
  end

  def test_fresh_checkout_generates_required_sources_without_lockfile_drift
    commands = all_steps.map { |_job_name, step| step.fetch("run", "").to_s }.join("\n")
    assert_includes commands, "flutter pub get --enforce-lockfile"
    assert_includes commands, "dart --suppress-analytics run build_runner build --delete-conflicting-outputs"
    assert_includes commands, "dart --suppress-analytics run slang"
    assert_includes commands, "git diff --exit-code -- lib pubspec.lock"
    refute_includes commands, "pod install --repo-update"
  end

  def test_live_collision_preflight_precedes_signing_and_upload_rechecks_it
    preflight_name, preflight_job = jobs.find do |_job_name, job|
      steps(job).any? { |step| release_helper_command(step, "preflight") }
    end
    refute_nil preflight_job, "upload must query the live app/group/build state before signing"
    assert_equal "release-publish", environment_name(preflight_job)

    signing_name, signing_job = jobs.find { |_job_name, job| environment_name(job) == "release-signing" }
    refute_nil signing_job
    assert job_depends_on?(signing_name, preflight_name), "signing must depend on live collision preflight"

    _upload_name, upload_job = jobs.find do |_job_name, job|
      steps(job).any? { |step| release_helper_command(step, "upload") }
    end
    refute_nil upload_job
    assert steps(upload_job).any? { |step| release_helper_command(step, "upload") },
      "upload helper must repeat the collision check immediately before altool"
  end

  def test_provenance_and_signed_identity_are_verified_before_upload
    job_name, job = jobs.find do |_candidate_name, candidate|
      steps(candidate).any? { |step| release_helper_command(step, "upload") }
    end
    refute_nil job
    upload_index = steps(job).index { |step| release_helper_command(step, "upload") }
    before_upload = steps(job).take(upload_index).map { |step| step.fetch("run", "").to_s }.join("\n")
    assert_includes before_upload, "SOURCE_SHA"
    assert_includes before_upload, "VERSION"
    assert_includes before_upload, "BUILD_NUMBER"
    assert_match(/shasum\s+-a\s+256/, before_upload)
    assert_includes before_upload, "scripts/verify_ios_baseline_ipa.rb"
    assert_includes before_upload, "--version \"$VERSION\""
    assert_includes before_upload, "--build-number \"$BUILD_NUMBER\""
    assert_includes before_upload, "--app-identifier com.womaninred.baseline"
    assert_includes before_upload, "--extension-identifier com.womaninred.baseline.HiddifyPacketTunnel"
    assert_includes before_upload, "--app-group group.com.womaninred.baseline"
  end

  def test_signing_commands_capture_sensitive_logs_and_fail_with_closed_codes
    signing_step = all_steps.map(&:last).find do |step|
      step.fetch("run", "").include?("xcodebuild") && step.to_s.include?("APPSTORE_API_PRIVATE_KEY")
    end
    refute_nil signing_step
    run = signing_step.fetch("run")
    assert_includes run, '"$RUNNER_TEMP/ios-baseline-signing-archive.log" 2>&1'
    assert_includes run, '"$RUNNER_TEMP/ios-baseline-signing-export.log" 2>&1'
    assert_includes run, "ERROR_CODE=SIGNING_ARCHIVE_FAILED"
    assert_includes run, "ERROR_CODE=SIGNING_EXPORT_FAILED"

    artifact_paths = all_steps.each_with_object([]) do |(_job_name, step), paths|
      paths << step.fetch("with", {})["path"] if step.fetch("uses", "").start_with?("actions/upload-artifact@")
    end.compact.join("\n")
    refute_includes artifact_paths, "signing-archive.log"
    refute_includes artifact_paths, "signing-export.log"
  end

  def test_workflow_does_not_copy_runtime_or_telemetry_policy
    refute_match(/SENTRY|telemetry|diagnostic[-_]ingest|com\.womaninred\.app/i, @source)
    assert_match(/SERVICE_IDENTIFIER:\s*com\.hiddify\.app/, @source)
  end

  def test_testflight_identity_is_separate_and_not_hardcoded_to_an_old_record
    _job_name, upload_job = jobs.find do |_candidate_name, candidate|
      steps(candidate).any? { |step| release_helper_command(step, "upload") }
    end
    refute_nil upload_job, "release workflow needs a distinct upload path"

    identity_values = [upload_job.fetch("env", {})] +
      steps(upload_job).map { |step| step.fetch("env", {}) }
    identity_values = identity_values.reduce({}) { |merged, env| merged.merge(env) }

    assert_equal BASELINE_BUNDLE_ID, identity_values.fetch("BUNDLE_ID", nil),
      "old_asc_record_reused: publish must target the baseline bundle"
    assert_equal "${{ vars.IOS_BASELINE_ASC_APP_ID }}", identity_values.fetch("ASC_APP_ID", nil),
      "old_asc_record_reused: ASC app ID must come from the baseline environment variable"
    assert_equal "${{ secrets.IOS_BASELINE_TESTER_GROUP_ID }}", identity_values.fetch("TESTER_GROUP_ID", nil),
      "old_asc_record_reused: tester group must come from the protected baseline secret"
    assert_equal "${{ secrets.IOS_BASELINE_SELF_TESTER_ID }}", identity_values.fetch("TESTER_ID", nil),
      "old_asc_record_reused: tester identity must come from the protected baseline secret"
    refute_includes @source, "vars.IOS_BASELINE_TESTER_GROUP_ID"
    refute_includes @source, "vars.IOS_BASELINE_SELF_TESTER_ID"

    FORBIDDEN_IDENTITIES.each do |identity|
      refute_includes @source, identity,
        "old_asc_record_reused: workflow contains forbidden prior identity #{identity}"
    end
    refute_match(/ASC_APP_ID:\s*["']?\d{6,}["']?\s*$/m, @source,
      "old_asc_record_reused: numeric ASC app ID must not be hardcoded")
  end

  def test_signed_ipa_is_verified_before_the_single_upload_path
    upload_jobs = jobs.select do |_job_name, job|
      steps(job).any? { |step| release_helper_command(step, "upload") }
    end
    assert_equal 1, upload_jobs.length,
      "release workflow must have exactly one explicit upload path"

    job_name, job = upload_jobs.first
    verify_index = steps(job).index do |step|
      step.fetch("run", "").to_s.match?(%r{ruby\s+scripts/verify_ios_baseline_ipa\.rb\b})
    end
    upload_index = steps(job).index { |step| release_helper_command(step, "upload") }
    refute_nil verify_index, "#{job_name} must verify signed IPA/profile provenance before upload"
    assert_operator verify_index, :<, upload_index,
      "artifact_provenance_mismatch: signed IPA verification must precede upload"
  end

  def test_status_operation_is_a_read_only_resume_path
    status_jobs = jobs.select do |_job_name, job|
      steps(job).any? { |step| release_helper_command(step, "status") }
    end
    assert_equal 1, status_jobs.length,
      "status resume must have one explicit release-helper path"

    job_name, job = status_jobs.first
    assert_includes job.fetch("if", "").to_s, "inputs.operation == 'status'"
    text = steps(job).map { |step| [step["uses"], step["run"]].compact.join(" ") }.join("\n")
    refute_match(/\b(upload|flutter build ipa|xcodebuild -exportArchive)\b/i, text,
      "status-only resume in #{job_name} must not build or upload an IPA")
    refute_match(/\.ipa\b|download-artifact|verify_ios_baseline_ipa/i, text,
      "status-only resume in #{job_name} must not consume an IPA artifact")

    upload_job_name, upload_job = jobs.find do |_candidate_name, candidate|
      steps(candidate).any? { |step| release_helper_command(step, "upload") }
    end
    refute_nil upload_job, "upload operation needs a distinct path"
    assert_includes upload_job.fetch("if", "").to_s, "inputs.operation == 'upload'",
      "upload path #{upload_job_name} must be gated to the upload operation"
  end

  def test_metadata_operation_is_read_only_and_never_consumes_an_ipa
    job_name, job = metadata_release_job
    refute_nil job, "metadata operation must have one explicit release-helper path"
    assert_equal "release-publish", environment_name(job)
    assert_includes job.fetch("if", "").to_s, "github.ref == 'refs/heads/main'"
    assert_includes job.fetch("if", "").to_s, "inputs.operation == 'metadata'"

    text = steps(job).map { |step| [step["uses"], step["run"]].compact.join(" ") }.join("\n")
    refute_match(/flutter build|xcodebuild|altool|notarytool|transporter/i, text,
      "metadata path in #{job_name} must not build, sign, or publish an app")
    refute_match(/\.ipa\b|download-artifact|verify_ios_baseline_ipa|IPA_PATH/i, text,
      "metadata path in #{job_name} must not consume an IPA artifact")
    refute_match(%r{ios_baseline_release\.rb\s+(?:preflight|upload|status)\b}, text,
      "metadata path in #{job_name} must invoke only the read-only metadata helper")
    refute_includes job.to_s, "TESTER_GROUP_ID"
    refute_includes job.to_s, "TESTER_ID"
  end

  def test_metadata_public_key_is_passed_via_env_without_shell_interpolation
    _job_name, job = metadata_release_job
    refute_nil job
    helper_step = steps(job).find { |step| release_helper_command(step, "metadata") }
    refute_nil helper_step
    env = helper_step.fetch("env", {})
    assert_equal "${{ inputs.metadataPublicKey }}", env.fetch("METADATA_PUBLIC_KEY", nil)
    assert_equal BASELINE_BUNDLE_ID, env.fetch("BUNDLE_ID", nil)
    assert_equal "${{ inputs.sourceSHA }}", env.fetch("SOURCE_SHA", nil)
    %w[APPSTORE_ISSUER_ID APPSTORE_API_KEY_ID APPSTORE_API_PRIVATE_KEY].each do |name|
      assert_equal "${{ secrets.#{name} }}", env.fetch(name, nil)
    end
    run = helper_step.fetch("run", "")
    refute_includes run, "inputs.metadataPublicKey"
    assert_match(
      %r{ruby\s+scripts/ios_baseline_release\.rb\s+metadata\s*>\s*out/ios-baseline-metadata\.json},
      run,
      "encrypted metadata must go directly to the retained file instead of the CI log"
    )
    refute_match(/\btee\b/, run, "metadata ciphertext must not be copied into the CI log")
  end

  def test_metadata_artifact_contains_only_the_encrypted_envelope
    _job_name, job = metadata_release_job
    refute_nil job
    artifact_steps = steps(job).select do |step|
      step.fetch("uses", "").to_s.start_with?("actions/upload-artifact@")
    end
    assert_equal 1, artifact_steps.length
    artifact = artifact_steps.first.fetch("with")
    assert_equal "ios-baseline-metadata-${{ inputs.sourceSHA }}-${{ inputs.buildNumber }}",
      artifact.fetch("name")
    assert_equal "out/ios-baseline-metadata.json", artifact.fetch("path")
    assert_equal 7, artifact.fetch("retention-days")
    assert_equal "error", artifact.fetch("if-no-files-found")
    refute_match(/log|uuid|email|private|\.ipa/i, artifact.fetch("path"),
      "metadata artifact must expose only the encrypted JSON envelope")
  end

  def test_workflow_never_mutates_github_settings
    command_text = all_steps.map { |_job_name, step| step.fetch("run", "").to_s }.join("\n")
    refute_match(/\bgh\s+(?:api|variable|secret)\b/i, command_text)
    refute_match(/GITHUB_TOKEN|GH_TOKEN|github\.token/i, @source)
  end

  private

  def relative_workflow_path
    ".github/workflows/ios-baseline.yml"
  end

  def normalize_yaml_keys(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested), normalized|
        normalized[key == true ? "on" : key.to_s] = normalize_yaml_keys(nested)
      end
    when Array
      value.map { |nested| normalize_yaml_keys(nested) }
    else
      value
    end
  end

  def jobs
    @workflow.fetch("jobs")
  end

  def steps(job)
    job.fetch("steps", [])
  end

  def all_steps
    jobs.flat_map { |job_name, job| steps(job).map { |step| [job_name, step] } }
  end

  def assert_required_string_input(inputs, name)
    input = inputs.fetch(name)
    assert_equal true, input.fetch("required"), "#{name} must be required"
    assert_equal "string", input.fetch("type"), "#{name} must be a string"
    refute input.key?("default"), "#{name} must be explicit, not defaulted"
  end

  def exact_sha_validation_step?(step)
    run = step.fetch("run", "").to_s
    env = step.fetch("env", {})
    source = env.fetch("SOURCE_SHA", nil)
    trusted = env.fetch("TRUSTED_SOURCE_SHA", "").to_s
    trusted_release = env.fetch("TRUSTED_RELEASE_SOURCE_SHA", "").to_s
    operation = env.fetch("OPERATION", nil)
    source == "${{ inputs.sourceSHA }}" &&
      trusted.match?(/\A[0-9a-f]{40}\z/) &&
      trusted_release.match?(/\A[0-9a-f]{40}\z/) &&
      operation == "${{ inputs.operation }}" &&
      run.include?("^[0-9a-f]{40}$") &&
      run.include?("$SOURCE_SHA") &&
      run.include?("$TRUSTED_SOURCE_SHA") &&
      run.include?("$TRUSTED_RELEASE_SOURCE_SHA") &&
      run.include?("$OPERATION")
  end

  def checkout_step?(step)
    step.fetch("uses", "").to_s.start_with?("actions/checkout@")
  end

  def job_uses_secrets?(job)
    job.to_s.include?("secrets.")
  end

  def environment_name(job)
    environment = job.fetch("environment", nil)
    environment.is_a?(Hash) ? environment.fetch("name", nil) : environment
  end

  def job_depends_on?(job_name, dependency, visited = [])
    return false if visited.include?(job_name)

    direct = Array(jobs.fetch(job_name).fetch("needs", [])).map(&:to_s)
    return true if direct.include?(dependency)

    direct.any? { |parent| job_depends_on?(parent, dependency, visited + [job_name]) }
  end

  def release_helper_command(step, operation)
    step.fetch("run", "").to_s.match?(
      %r{ruby\s+scripts/ios_baseline_release\.rb\s+#{Regexp.escape(operation)}\b}
    )
  end

  def metadata_release_job
    matches = jobs.select do |_job_name, job|
      steps(job).any? { |step| release_helper_command(step, "metadata") }
    end
    assert_operator matches.length, :<=, 1,
      "metadata operation must have at most one release-helper path"
    matches.first
  end
end
