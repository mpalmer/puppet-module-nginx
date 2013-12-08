require 'spec_helper'

describe "nginx::ssl::hardened" do
	let(:title) { "rspec" }
	
	context "without a site" do
		it "has the right context" do
			expect(subject).
			  to contain_nginx__config__parameter("http/ssl_prefer_server_ciphers").
			  with_value("on")
		end
	end
	
	context "with a site" do
		let(:params) { { :site => "faff" } }
		
		it "provides a site-specific context" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_faff/ssl_prefer_server_ciphers").
			  with_value("on")
		end
	end
end
