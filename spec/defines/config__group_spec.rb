require 'spec_helper'

describe "nginx::config::group" do
	let(:title) { "xyzzy" }
	let(:params) { { :context => "faffenheim" } }
	
	it "creates a config directory" do
		expect(subject).
		  to contain_file("/etc/nginx/nginx.conf.d/xyzzy").
		  with_ensure("directory").
		  with_mode("0755").
		  with_owner("root").
		  with_group("root").
		  with_recurse(true).
		  with_purge(true)
	end
	
	it "creates an includer config" do
		expect(subject).
		  to contain_nginx__config("xyzzy")
	end
	
	it "includer config has the no-touchie header" do
		expect(subject).
		  to contain_nginx__config("xyzzy").
		  with_content(/THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET/)
	end

	it "includer config has the context" do
		expect(subject).
		  to contain_nginx__config("xyzzy").
		  with_content(/^faffenheim {$/)
	end


	it "includer config actually includes things" do
		expect(subject).
		  to contain_nginx__config("xyzzy").
		  with_content(%r{^\s*include /etc/nginx/nginx.conf.d/xyzzy/\*.conf;$})
	end
end
