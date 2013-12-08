require 'spec_helper'

describe "nginx::config" do
	context "no options" do
		let(:title) { "noopts" }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			         /Must pass exactly one of source or content to Nginx::Config\[noopts\]/
			     )
		end
	end

	context "both source and content" do
		let(:title) { "bothopts" }
		let(:params) { { :source => 'x', :content => 'y' } }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			         /Must pass exactly one of source or content to Nginx::Config\[bothopts\]/
			     )
		end
	end
	
	context "with source" do
		let(:title) { "source" }
		let(:params) { { :source => 'x' } }
		
		it "creates a file" do
			expect(subject).
			  to contain_file("/etc/nginx/nginx.conf.d/source.conf").
			  with_source("x").
			  with_notify("Noop[nginx/configured]")
		end
	end

	context "with content" do
		let(:title) { "content" }
		let(:params) { { :content => 'y' } }
		
		it "creates a file" do
			expect(subject).
			  to contain_file("/etc/nginx/nginx.conf.d/content.conf").
			  with_content("y").
			  with_notify("Noop[nginx/configured]")
		end
	end
end
