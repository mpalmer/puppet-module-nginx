require 'rake'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |t|
	t.pattern = 'spec/*/*_spec.rb'
end

desc "Run guard"
task :guard do
	require 'guard'
	::Guard.start(:clear => true, :no_interactions => true)
	while ::Guard.running do
		sleep 0.5
	end
end
