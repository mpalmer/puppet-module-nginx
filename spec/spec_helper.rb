require 'rspec-puppet'

RSpec.configure do |c|
	c.fail_fast = true
#	c.full_backtrace = true
	c.formatter = "Fuubar"
	
	tmpdir = File.expand_path('../../.tmp', __FILE__)

	c.module_path  = File.join(tmpdir, 'modules')
	c.manifest_dir = File.join(tmpdir, 'manifests')
	selfdir = File.join(c.module_path, 'nginx')
	
	dirs = %w{files lib manifests templates}
	
	c.before(:all) do
		[tmpdir, c.module_path, c.manifest_dir, selfdir].each do |d|
			Dir.mkdir(d) unless File.exists?(d)
		end
		
		# Touch done the Ruby way
		File.open(File.join(c.manifest_dir, 'site.pp'), 'w') { |fd| fd }
		
		dirs.each do |d|
			File.symlink("../../../#{d}", c.module_path + "/nginx/#{d}")
		end
		
		system("librarian-puppet install --path #{c.module_path}")
	end
	
	c.after(:all) do
		# We get rid of the symlinks after each run so that poor guard doesn't
		# get all confused
		dirs.each do |d|
			File.unlink(c.module_path + "/nginx/#{d}")
		end
	end
end
