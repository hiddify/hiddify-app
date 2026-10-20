# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class IosSourceCiScopeTest < Minitest::Test
  def test_generic_matrix_is_disabled_while_full_source_tests_remain_enabled
    workflow = YAML.safe_load(File.read(File.expand_path("../../.github/workflows/build.yml", __dir__)))
    jobs = workflow.fetch("jobs")
    assert_equal "${{ false }}", jobs.fetch("build")["if"],
                 "The iOS-only source PR must not trigger Android, desktop or Linux builds"
    source_tests = jobs.fetch("test")
    refute source_tests.key?("if"), "Full source tests must remain unconditional"
    assert source_tests.fetch("steps").any? { |step| step["run"] == "flutter test" }
    assert_equal "test", jobs.fetch("build").fetch("needs")
  end
end
