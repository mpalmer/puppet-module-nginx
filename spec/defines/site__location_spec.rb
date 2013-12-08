require 'spec_helper'

describe "nginx::site::location" do
	let(:title) { "rspec" }
	
	context "no options" do
		it "bombs out" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass site to Nginx::Site::Location\[rspec\]/
			     )
		end
	end

	context "with just a site" do
		let(:params) { { :site => "mysite" } }
		
		it "bombs out" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass path to Nginx::Site::Location\[rspec\]/
			     )
		end
	end
	
	context "with site/path" do
		let(:params) { { :site => "mysite",
		                 :path => "~ ^/s3kr1t/(.*)$"
		             } }

		it "creates a location-oriented config group in the site" do
			expect(subject).
			  to contain_nginx__config__group("http/site_mysite/location_rspec").
			  with_context("location ~ ^/s3kr1t/(.*)$")
		end
	end

	context "compound namevar" do
		let(:title) { "some/funny/little/rspec" }
		
		context "with site/path" do
			let(:params) { { :site => "mysite",
								  :path => "~ ^/s3kr1t/(.*)$"
							 } }

			it "creates a location based on the last element of the namevar" do
				expect(subject).
				  to contain_nginx__config__group("http/site_mysite/location_rspec").
				  with_context("location ~ ^/s3kr1t/(.*)$")
			end
		end
	end
end
