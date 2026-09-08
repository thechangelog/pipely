# frozen_string_literal: true

# Scheduling-policy tests only: no jobs, provider calls or release commands run.
require 'yaml'

root = File.expand_path('..', __dir__)
parent = YAML.safe_load(File.read(File.join(root, '.github/workflows/ship_it.yml')))
children = %w[_namespace.yml _github.yml].map do |name|
  YAML.safe_load(File.read(File.join(root, '.github/workflows', name)))
end
jobs = parent.fetch('jobs')

# Evaluate only the boolean subset used by these workflow guards. Reject unknown
# syntax rather than silently modeling a changed policy as the old policy.
def evaluate(expression, event:, ref:, result:, runners:)
  value = expression.delete_prefix('${{').delete_suffix('}}').strip
  value = value.gsub('failure()', (result == 'failure').to_s)
  value = value.gsub(/startsWith\(github.ref, '([^']*)'\)/) { ref.downcase.start_with?(Regexp.last_match(1).downcase).to_s }
  value = value.gsub(/contains\(vars.RUNS_ON, '([^']*)'\)/) { runners.downcase.include?(Regexp.last_match(1).downcase).to_s }
  value = value.gsub(/github.event_name == '([^']*)'/) { (event.downcase == Regexp.last_match(1).downcase).to_s }
  raise "Unsupported guard: #{expression}" unless value.gsub(/true|false|&&|\|\||[\s()!]/, '').empty?

  # Only boolean literals/operators remain, never arbitrary workflow code.
  eval(value) # rubocop:disable Security/Eval
end

checks = 0
check = lambda do |condition, message|
  raise message unless condition

  checks += 1
end

context = { event: 'push', ref: 'refs/heads/main', result: 'success', runners: '' }
{
  'true && false' => false,
  'true || false' => true,
  '!(true && false) && (false || true)' => true
}.each do |expression, expected|
  check.call(evaluate(expression, **context) == expected, "Logical operator evaluation failed: #{expression}")
end

['true & false', 'true | false', 'true &&& false', 'true ||| false'].each do |expression|
  rejected = false
  begin
    evaluate(expression, **context)
  rescue RuntimeError => error
    rejected = error.message == "Unsupported guard: #{expression}"
  end
  check.call(rejected, "Unsupported operator accepted: #{expression}")
end

fallback = jobs.fetch('on-github-fallback')
check.call(fallback.fetch('needs') == 'on-namespace', 'Fallback must depend on Namespace')
check.call(fallback.fetch('uses') == './.github/workflows/_github.yml', 'Unexpected fallback child')

contexts = [
  ['push', 'refs/tags/v1.3.0', true],
  ['push', 'refs/tags/v', true],
  ['push', 'refs/tags/vnext/test', true],
  ['push', 'refs/tags/V1.3.0', true],
  ['push', 'refs/heads/main', false],
  ['push', 'refs/heads/vnext', false],
  ['push', 'refs/tags/test', false],
  ['pull_request', 'refs/pull/60/merge', false],
  ['workflow_dispatch', 'refs/tags/v1.3.0', false]
]

contexts.each do |event, ref, release|
  %w[success failure skipped cancelled].each do |result|
    context = { event: event, ref: ref, result: result, runners: 'namespace' }
    actual = evaluate(fallback.fetch('if'), **context)
    check.call(actual == (result == 'failure' && !release), "Unexpected fallback: #{context}")
  end

  children.each do |child|
    steps = child.fetch('jobs').fetch('run').fetch('steps')
    effectful = steps.select { |step| step['run'].to_s.match?(/just (publish|deploy|test-acceptance-production)\b/) }
    check.call(effectful.length == 2, 'Review policy coverage when release steps change')
    effectful.each do |step|
      context = { event: event, ref: ref, result: 'success', runners: '' }
      check.call(evaluate(step.fetch('if'), **context) == release, "Child release predicate changed: #{step['name']}")
    end
  end
end

# Inject failure at each boundary. Record only synthetic activation counts;
# acceptance includes PURGE in the real workflow, so it must never run here.
%w[before_build after_publish after_deploy production_acceptance report_upload].each do |stage|
  context = { event: 'push', ref: 'refs/tags/v1.3.0', result: 'failure', runners: 'namespace' }
  fallback_runs = evaluate(fallback.fetch('if'), **context)
  already_deployed = %w[after_deploy production_acceptance report_upload].include?(stage)
  activations = (already_deployed ? 1 : 0) + (fallback_runs ? 1 : 0)
  check.call(!fallback_runs && activations <= 1, "Automatic release replay after #{stage}")
end

['namespace', 'NAMESPACE', ''].each do |runners|
  context = { event: 'push', ref: 'refs/tags/v1.3.0', result: 'success', runners: runners }
  namespace = evaluate(jobs.fetch('on-namespace').fetch('if'), **context)
  github = evaluate(jobs.fetch('on-github').fetch('if'), **context)
  check.call(namespace == !runners.empty? && github == runners.empty?, 'Primary runner selection changed')
end

puts "#{checks} workflow policy checks passed (no release commands executed)"
