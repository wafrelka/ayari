$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'app'))
require 'rspec'

RSpec.configure do |c|
	c.filter_run_excluding internet_required: true
end

RSpec::Matchers.define :eq_path do |expected|
	match do |actual|
		expected.is_a?(String) && actual.is_a?(String) && File.absolute_path(expected) == File.absolute_path(actual)
	end
	description do
		"be the same path as '#{expected}'"
	end
end
