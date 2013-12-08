require 'spec_helper'

describe "nginx::config::parameter" do
	context "top-level parameter" do
		let(:title) { "xyzzy" }
		let(:params) { { :value => "faffenheim" } }
	
		it "creates a config" do
			expect(subject).
			  to contain_nginx__config("xyzzy")
		end
		
		it "sets the config parameter we want" do
			expect(subject).
			  to contain_nginx__config("xyzzy").
			  with_content(/^\s*xyzzy = faffenheim;$/)
		end
	end

	context "lower-level parameter" do
		let(:title) { "foo/bar/wombat/xyzzy" }
		let(:params) { { :value => "faffenheim" } }
	
		it "creates a config" do
			expect(subject).
			  to contain_nginx__config("foo/bar/wombat/xyzzy")
		end
		
		it "says 'no-touchie'" do
			expect(subject).
			  to contain_nginx__config("foo/bar/wombat/xyzzy").
			  with_content(/THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET/)
		end

		it "sets the config parameter we want" do
			expect(subject).
			  to contain_nginx__config("foo/bar/wombat/xyzzy").
			  with_content(/^\s*xyzzy = faffenheim;$/)
		end
	end
	
	context "overridden parameter name" do
		let(:title) { "foo/bar/wombat/xyzzy" }
		let(:params) { { :param => "blargle",
		                 :value => "faffenheim"
		             } }

		it "creates a config" do
			expect(subject).
			  to contain_nginx__config("foo/bar/wombat/xyzzy")
		end
		
		it "says 'no-touchie'" do
			expect(subject).
			  to contain_nginx__config("foo/bar/wombat/xyzzy").
			  with_content(/THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET/)
		end

		it "sets the config parameter we want" do
			expect(subject).
			  to contain_nginx__config("foo/bar/wombat/xyzzy").
			  with_content(/^\s*blargle = faffenheim;$/)
		end
	end
end
