$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'app'))

RSpec.configure do |c|
	c.filter_run_excluding internet_required: true
end
