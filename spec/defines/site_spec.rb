require 'spec_helper'

describe "nginx::site" do
	let(:title) { "rspec" }
	
	context "no options" do
		it "bombs out" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass base_dir to Nginx::Site\[rspec\]/
			     )
		end
	end

	context "with just a base_dir" do
		let(:params) { { :base_dir => "/home/rspec/sites/rspec" } }
		
		it "bombs out" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass server_name to Nginx::Site\[rspec\]/
			     )
		end
	end
	
	context "with just a server name" do
		let(:params) { { :server_name => "example.com"
		             } }
		
		it "bombs out" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass base_dir to Nginx::Site\[rspec\]/
			     )
		end
	end
	
	context "with all required parameters" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com"
		             } }

		it "creates a server-oriented config group" do
			expect(subject).
			  to contain_nginx__config__group("http/site_rspec").
			  with_context("server")
		end
		
		it "configures the server name" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/server_name").
			  with_value("rspec.example.com")
		end
		
		it "creates a logs directory" do
			expect(subject).
			  to contain_file("/home/rspec/sites/rspec/logs").
			  with_ensure("directory").
			  with_owner("root").
			  with_group("root").
			  with_mode("0755")
		end
		
		it "logs errors" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/error_log").
			  with_value("/home/rspec/sites/rspec/logs/error.log info")
		end

		it "logs access" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/access_log").
			  with_value("/home/rspec/sites/rspec/logs/access.log combined")
		end
		
		it "rotates the logs" do
			expect(subject).
			  to contain_file("/etc/logrotate.d/nginx-rspec").
			  with_ensure("file").
			  with_content(/THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET/).
			  with_content(%r{^\s*/home/rspec/sites/rspec/logs/\*.log\s+\{$}).
			  with_content(%r{^\s*daily$}).
			  with_content(%r{^\s*rotate 90$}).
			  with_content(%r{^\s*delaycompress$}).
			  with_content(%r{^\s*create 640 root root$})
		end
		
		it "listens on port 80" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/listen").
			  with_value("80")
		end
		
		it "sets the rootdir" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/root").
			  with_value("/home/rspec/sites/rspec/htdocs")
		end
	end

	context "with an array of alt names" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :alt_names   => ["foo.example.com", "bar.example.com"]
		             } }

		it "lists the server primary name" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/server_name").
			  with_value("rspec.example.com")
		end
		
		it "lists the server's alternate names" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/server_alt_names").
			  with_param("server_name").
			  with_value("foo.example.com bar.example.com")
		end
	end
	
	context "with a string of alt names" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :alt_names   => "foo.example.com bar.example.com"
		             } }

		it "lists the server primary name" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/server_name").
			  with_value("rspec.example.com")
		end
		
		it "lists the server's alternate names" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/server_alt_names").
			  with_param("server_name").
			  with_value("foo.example.com bar.example.com")
		end
	end
	
	context "with 'ssl_redirect => true' but no ssl_cert/ssl_key" do
		let(:params) { { :base_dir     => "/home/rspec/sites/rspec",
		                 :server_name  => "rspec.example.com",
		                 :ssl_redirect => true
		             } }
		
		it "bombs out" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must pass ssl_cert and ssl_key to Nginx::Site\[rspec\] when ssl_redirect => true/
			     )
		end
	end

	context "with 'ssl_redirect => true'" do
		let(:params) { { :base_dir     => "/home/rspec/sites/rspec",
		                 :server_name  => "rspec.example.com",
		                 :ssl_redirect => true,
		                 :ssl_cert     => "x",
		                 :ssl_key      => "y"
		             } }
			
		it "sets up an sslredir server config group" do
			expect(subject).
			  to contain_nginx__config__group("http/site_sslredir_rspec").
			  with_context("server")
		end
		
		it "listens on port 80 in the sslredir server config" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_sslredir_rspec/listen").
			  with_value("80")
		end
		
		it "doesn't listen on port 80 in the main vhost" do
			expect(subject).
			  to_not contain_nginx__config__parameter("http/site_rspec/listen")
		end
		
		it "configures the sslredir vhost with the server names" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_sslredir_rspec/server_name").
			  with_value("rspec.example.com")
		end
		
		it "has an empty rootdir" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_sslredir_rspec/root").
			  with_value("/usr/share/empty")
		end
		
		it "actually redirects the traffic" do
			expect(subject).
			  to contain_nginx__config__rewrite("http/site_sslredir_rspec/ssl_redirect").
			  with_from("^(.*)$").
			  with_to("https://rspec.example.com$1").
			  with_permanent(true)
		end
	end

	context "with ssl_cert but no ssl_key" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :ssl_cert    => "x"
		             } }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must specify both ssl_cert and ssl_key in Nginx::Site\[rspec\]/
			     )
		end
	end

	context "with ssl_key but no ssl_cert" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :ssl_key     => "y"
		             } }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must specify both ssl_cert and ssl_key in Nginx::Site\[rspec\]/
			     )
		end
	end
	
	context "with ssl_ip but no ssl_cert/ssl_key" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :ssl_ip      => "192.0.2.42"
		             } }
		
		it "bombs" do
			expect { should contain_file('/error') }.
			  to raise_error(Puppet::Error,
			       /Must specify ssl_cert and ssl_key in Nginx::Site\[rspec\] when ssl_ip is set/
			     )
		end
	end

	context "with ssl_key and ssl_cert" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :ssl_cert    => "x",
		                 :ssl_key     => "y"
		             } }
		
		it "listens on 443 with SSL" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/listen_ssl").
			  with_param("listen").
			  with_value("443 ssl")
		end
		
		it "configures the SSL cert" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/ssl_certificate").
			  with_value("x")
		end
		
		it "configures the SSL key" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/ssl_certificate_key").
			  with_value("y")
		end
	end
	
	context "with ssl_cert, ssl_key, and ssl_ip" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :ssl_cert    => "x",
		                 :ssl_key     => "y",
		                 :ssl_ip      => "192.0.2.42"
		             } }
		
		it "listens on 192.0.2.42:443 with SSL" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/listen_ssl").
			  with_param("listen").
			  with_value("192.0.2.42:443 ssl")
		end
	end
	
	context "with default => true" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :default     => true
		             } }
		
		it "listens on port 80 default" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/listen").
			  with_value("80 default")
		end
	end

	context "with ssl_default => true" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :ssl_cert    => "x",
		                 :ssl_key     => "y",
		                 :ssl_default => true
		             } }
		
		it "listens on port 443 ssl default" do
			expect(subject).
			  to contain_nginx__config__parameter("http/site_rspec/listen_ssl").
			  with_param("listen").
			  with_value("443 ssl default")
		end
	end
	
	context "with custom user" do
		let(:params) { { :base_dir    => "/home/rspec/sites/rspec",
		                 :server_name => "rspec.example.com",
		                 :user        => "fred",
		                 :group       => "fred"
		             } }
		
		it "makes .../logs owned by fred" do
			expect(subject).
			  to contain_file("/home/rspec/sites/rspec/logs").
			  with_owner("fred").
			  with_group("fred")
		end
		
		it "makes the logfiles owned by fred" do
			expect(subject).
			  to contain_file("/etc/logrotate.d/nginx-rspec").
			  with_content(/create 640 fred root/)
		end
	end
end
