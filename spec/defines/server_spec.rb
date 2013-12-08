require 'spec_helper'

describe "nginx::server" do
	let(:title) { "nginx" }
	let(:facts) { { :operatingsystem => 'Debian',
	                :operatingsystemrelease => 7
	            } }
	
	context "no options" do
		it "creates the root directory" do
			expect(subject).
			  to contain_file("/etc/nginx").
			  with_ensure("directory")
		end
		
		it "creates the base config directory" do
			expect(subject).
			  to contain_file("/etc/nginx/nginx.conf.d").
			  with_ensure("directory").
			  with_recurse(true).
			  with_purge(true)
		end
		
		it "puts a warning README in the base config directory" do
			expect(subject).
			  to contain_file("/etc/nginx/nginx.conf.d/README").
			  with_ensure("file").
			  with_source("puppet:///modules/nginx/etc/nginx/nginx.conf.d/README")
		end
		
		it "installs the nginx-full package" do
			expect(subject).
			  to contain_package("nginx-full")
		end
		
		it "sets up the nginx service" do
			expect(subject).
			  to contain_service("nginx").
			  with_restart("/usr/sbin/invoke-rc.d nginx reload")
		end
		
		it "installs the skeleton nginx config" do
			expect(subject).
			  to contain_file("/etc/nginx/nginx.conf")
		end
	end
	
	context "on a CentOS system" do
		let(:facts) { { :operatingsystem => 'CentOS' } }
		
		it "installs the nginx package" do
			expect(subject).
			  to contain_package("nginx")
		end
		
		it "sets up the nginx service" do
			expect(subject).
			  to contain_service("nginx").
			  with_restart("/sbin/service nginx reload")
		end
	end
end
