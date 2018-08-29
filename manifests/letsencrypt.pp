define nginx::letsencrypt($ctx, $names_array) {
	nginx::site::location { "${name}/acme-challenge":
		site => $name,
		path => "/.well-known/acme-challenge"
	}

	# Can't just notify the nginx service here, because it won't accept
	# being reloaded multiple times in a single Puppet run
	exec { "reload nginx for ${name} validation config":
		command     => "/usr/sbin/service nginx reload",
		refreshonly => true,
	}

	letsencrypt::certificate { $name:
		names   => $names_array,
		require => Exec["reload nginx for ${name} validation config"],
	}

	nginx::config::parameter {
		"${ctx}/location_acme-challenge/alias":
			value   => "/var/lib/letsencrypt/acme-challenge",
			require => Nginx::Site::Location["${name}/acme-challenge"],
			notify  => Exec["reload nginx for ${name} validation config"];
		"${ctx}/ssl_certificate":
			value   => "/var/lib/letsencrypt/certs/${name}.pem",
			require => Letsencrypt::Certificate[$name];
		"${ctx}/ssl_certificate_key":
			value   => "/var/lib/letsencrypt/keys/${name}.pem",
			require => Letsencrypt::Certificate[$name];
	}
}
