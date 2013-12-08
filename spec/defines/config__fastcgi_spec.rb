require 'spec_helper'

describe "nginx::config::fastcgi" do
	let(:title) { "rspec" }

	context "with no params" do
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass site to Nginx::Config::Fastcgi\[rspec\]/
			     )
		end
	end

	context "with just site" do
		let(:params) { { :site => "example" } }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass location to Nginx::Config::Fastcgi\[rspec\]/
			     )
		end
	end

	context "with just site/location" do
		let(:params) { { :site     => "example",
		                 :location => "root"
		             } }
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass target to Nginx::Config::Fastcgi\[rspec\]/
			     )
		end
	end
	
	context "with all params" do
		let(:params) { { :site     => "example",
		                 :location => "root",
		                 :target   => "unix:/var/run/example.sock"
		             } }
		
		{ 'QUERY_STRING'      => '$query_string',
		  'REQUEST_METHOD'    => '$request_method',
		  'CONTENT_TYPE'      => '$content_type',
		  'CONTENT_LENGTH'    => '$content_length',
		  'SCRIPT_FILENAME'   => '$request_filename',
		  'SCRIPT_NAME'       => '$fastcgi_script_name',
		  'REQUEST_URI'       => '$request_uri',
		  'DOCUMENT_URI'      => '$document_uri',
		  'DOCUMENT_ROOT'     => '$document_root',
		  'SERVER_PROTOCOL'   => '$server_protocol',
		  'GATEWAY_INTERFACE' => 'CGI/1.1',
		  'SERVER_SOFTWARE'   => 'nginx/$nginx_version',
		  'REMOTE_ADDR'       => '$remote_addr',
		  'REMOTE_PORT'       => '$remote_port',
		  'SERVER_ADDR'       => '$server_addr',
		  'SERVER_PORT'       => '$server_port',
		  'SERVER_NAME'       => '$server_name',
		  'HTTPS'             => '$https',
		  'REDIRECT_STATUS'   => '200'
		}.each do |k, v|
			it "contains fastcgi_param #{k}" do
				expect(subject).
				  to contain_nginx__config__parameter("http/site_example/location_root/fastcgi_param_#{k}").
				  with_param("fastcgi_param").
				  with_value(v)
			end
		end
		
		it "contains fastcgi_pass" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_example/location_root/fastcgi_pass").
			  with_value("unix:/var/run/example.sock")
		end
	end
end
