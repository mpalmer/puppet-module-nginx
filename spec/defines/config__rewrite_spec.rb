require 'spec_helper'

describe "nginx::config::rewrite" do
	context "using a simple title" do
		let(:title) { "myrewrite" }
		
		context "with no params" do
			it "bombs" do
				expect { should contain_file('/error') }.
				  to raise_error(Puppet::Error,
						 %r{Must pass from to Nginx::Config::Rewrite\[myrewrite\]}
					  )
			end
		end
		
		context "with just from" do
			let(:params) { { :from => "^(.*)$" } }
			
			it "bombs" do
				expect { should contain_file('/error') }.
				  to raise_error(Puppet::Error,
						 %r{Must pass to to Nginx::Config::Rewrite\[myrewrite\]}
					  )
			end
		end
		
		context "with from/to" do
			let(:params) { { :from => "^(.*)$",
								  :to   => "https://example.com$1"
							 } }
			
			it "bombs" do
				expect { should contain_file('/error') }.
				  to raise_error(Puppet::Error,
						 %r{Must pass site to Nginx::Config::Rewrite\[myrewrite\]}
					  )
			end
		end
		
		context "with from/to/site" do
			let(:params) { { :from => "^(.*)$",
			                 :to   => "https://example.com$1",
			                 :site => "foo"
			             } }

			it "creates a temporary redirect" do
				expect(subject).
				  to contain_nginx__config__parameter("http/site_foo/myrewrite").
				  with_param("rewrite").
				  with_value("^(.*)$ https://example.com$1")
			end
		end

		context "with from/to/site/location" do
			let(:params) { { :from     => "^(.*)$",
			                 :to       => "https://example.com$1",
			                 :site     => "foo",
			                 :location => "root"
			             } }

			it "creates a temporary redirect in a location" do
				expect(subject).
				  to contain_nginx__config__parameter("http/site_foo/location_root/myrewrite").
				  with_param("rewrite").
				  with_value("^(.*)$ https://example.com$1")
			end
		end
		
		context "with from/to/site/permanent => true" do
			let(:params) { { :from      => "^(.*)$",
			                 :to        => "https://example.com$1",
			                 :site      => "foo",
			                 :permanent => true
			             } }

			it "creates a permanent redirect" do
				expect(subject).
				  to contain_nginx__config__parameter("http/site_foo/myrewrite").
				  with_param("rewrite").
				  with_value("^(.*)$ https://example.com$1 permanent")
			end
		end

		context "with from/to/site/last => true" do
			let(:params) { { :from => "^(.*)$",
			                 :to   => "https://example.com$1",
			                 :site => "foo",
			                 :last => true
			             } }

			it "creates a 'last' redirect" do
				expect(subject).
				  to contain_nginx__config__parameter("http/site_foo/myrewrite").
				  with_param("rewrite").
				  with_value("^(.*)$ https://example.com$1 last")
			end
		end

		context "with both permanent and last" do
			let(:params) { { :from      => "^(.*)$",
								  :to        => "https://example.com$1",
								  :site      => "foo",
								  :last      => true,
								  :permanent => true
							 } }

			it "bombs" do
				expect { should contain_file('/error') }.
				  to raise_error(Puppet::Error,
						 /No more than one of last or permanent can be specified in Nginx::Config::Rewrite\[myrewrite\]/
					  )
			end
		end
	end

	context "using a compound title" do
		let(:title) { "example.com/myrewrite" }
		
		context "with from/to/site" do
			let(:params) { { :from => "^(.*)$",
			                 :to   => "https://example.com$1",
			                 :site => "foo"
			             } }

			it "creates a temporary redirect" do
				expect(subject).
				  to contain_nginx__config__parameter("http/site_foo/myrewrite").
				  with_param("rewrite").
				  with_value("^(.*)$ https://example.com$1")
			end
		end
	end
end
