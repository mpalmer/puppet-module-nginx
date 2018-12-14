class nginx::ssl::dhparams {
	file { "/etc/nginx/dhparams":
		ensure => file,
		source => "puppet:///modules/nginx/etc/nginx/dhparams",
		owner  => "root",
		group  => "root",
		mode   => "0444",
	}
}
