require 'spec_helper'

describe "nginx::config::error_page" do
	let(:title) { "rspec" }
	
	context "globally" do
		let(:params) { { :code => "404",
		                 :dest => "/404.html"
		             } }
		
		it "has the right context" do
			expect(subject).
			  to contain_nginx__config__parameter("http/error_page_404").
			  with_param("error_page").
			  with_value("404 /404.html")
		end
	end
	
	context "with a site" do
		let(:params) { { :code => "404",
		                 :dest => "/404.html",
		                 :site => "faff"
		             } }
		
		it "provides a site-specific context" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_faff/error_page_404").
			  with_param("error_page").
			  with_value("404 /404.html")
		end
	end
	
	context "with a site and location" do
		let(:params) { { :code     => "404",
		                 :dest     => "/404.html",
		                 :site     => "faff",
		                 :location => "root"
		             } }
		
		it "provides a site- and location-specific context" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_faff/location_root/error_page_404").
			  with_param("error_page").
			  with_value("404 /404.html")
		end
	end
	
	context "with a location but no site" do
		let(:params) { { :code     => "404",
		                 :dest     => "/404.html",
		                 :location => "root"
		             } }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must provide a site when providing a location in Nginx::Config::Error_page\[rspec\]/
			     )
		end
	end
end
