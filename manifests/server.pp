define nginx::server (
	$workers                       = $::processorcount,
	$worker_connections            = 1024,
) {
	noop {
		"nginx/installed": ;
		"nginx/configured":
			require   => Noop["nginx/installed"];
	}
	
	file {
		"/etc/nginx":
			ensure  => directory,
			mode    => 0755,
			owner   => "root",
			group   => "root",
			require => Noop["nginx/installed"],
			before  => Noop["nginx/configured"];
		"/etc/nginx/nginx.conf.d":
			ensure  => directory,
			mode    => 0755,
			owner   => "root",
			group   => "root",
			recurse => true,
			purge   => true,
			require => Noop["nginx/installed"],
			before  => Noop["nginx/configured"];
		"/etc/nginx/nginx.conf.d/README":
			ensure  => file,
			source  => "puppet:///modules/nginx/etc/nginx/nginx.conf.d/README",
			mode    => 0444,
			owner   => "root",
			group   => "root";
	}

	case $::operatingsystem {
		"RedHat","CentOS": {
			$nginx_server_package = "nginx"
			$nginx_server_reload  = "/sbin/service nginx reload"
		}
		"Debian": {
			if to_i($::operatingsystemrelease) >= 7 {
				$nginx_server_package = "nginx-full"
			} else {
				$nginx_server_package = "nginx"
			}

			$nginx_server_reload = "/usr/sbin/invoke-rc.d nginx reload"
		}
		default: {
			fail("The nginx module is not tailored for your OS; patches welcome")
		}
	}

	package { $nginx_server_package:
		before  => Noop["nginx/installed"],
	}

	service { "nginx":
		enable    => true,
		ensure    => running,
		restart   => $nginx_server_reload,
		subscribe => Noop["nginx/configured"],
	}

	case $::operatingsystem {
		RedHat,CentOS: {
			$nginx_server_user = "nginx"
		}
		Debian: {
			$nginx_server_user = "www-data"
		}
	}

	$nginx_server_worker_connections = $worker_connections

	file {
		"/etc/nginx/nginx.conf":
			source  => "puppet:///modules/nginx/etc/nginx/nginx.conf",
			mode    => 0444,
			require => Noop["nginx/installed"],
			before  => Noop["nginx/configured"],
			notify  => Noop["nginx/configured"];
		"/var/log/nginx":
			ensure  => directory,
			owner   => "root",
			group   => "root",
			mode    => 0755,
			before  => Noop["nginx/configured"];
	}
	
	if defined("logrotate::rule") {
		logrotate::rule { "nginx":
			logs              => ["/var/log/nginx/*.log",
			                      "/var/log/nginx/*_log",
			                      "/var/log/nginx/error_logs/*.log",
			                      "/var/log/nginx/error_logs/*_log",
			                      "/var/log/nginx/access_logs/*.log",
			                      "/var/log/nginx/access_logs/*_log"],
			keep              => 30,
			compress          => "delayed",
			create            => "0640 root adm",
			sharedscripts     => true,
			postrotate_script => "[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`";
		}
	}

	# Common config groups that ordinarily go in the base config file
	nginx::config::group {
		"events": context => "events";
		"http":   context => "http";
	}
	
	# Core parameters we like to set
	nginx::config::parameter {
		"worker_processes":
			value => $workers;
		"user":
			value => $nginx_server_user;
		"error_log":
			value => "/var/log/nginx/error.log";
		"pid":
			value => "/var/run/nginx.pid";

		"events/worker_connections":
			value => $worker_connections;
		
		"http/access_log":
			value => "/var/log/nginx/access.log";
		"http/sendfile":
			value => "on";
		"http/keepalive_timeout":
			value => "10";
		"http/tcp_nodelay":
			value => "on";
		"http/server_tokens":
			value => "off";
		"http/client_max_body_size":
			value => "256m";
		"http/client_body_buffer_size":
			value => "128k";
		"http/types_hash_max_size":
			value => "2048";
	}
	
	# Kinda cheating, but wotevs
	file { "/etc/nginx/nginx.conf.d/http/mime_types.conf":
		ensure => file,
		source => "puppet:///modules/nginx/etc/nginx/nginx.conf.d/mime.types",
		mode   => 0444,
		owner  => "root",
		group  => "root";
	}
}
