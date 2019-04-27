# Configures an nginx site to proxy to somewhere else.
#
# Very simply, this type listens on one or more server_names, optionally
# including some SSL, and forwards all traffic to another IP address.  All
# the usual reverse-proxy headers are set, such as `X-Real-IP` and
# `X-Forwarded-Proto`.
#
#  * `title` (string; *namevar*)
#
#     A unique name for the vhost.  It has no particular meaning for the
#     `nginx::site::proxy` type, other than being used in the filenames that
#     define the configuration parameters (so you *probably* want to stick
#     to alpha-numerics, periods, dashes, underscores, that sort of thing --
#     forward slashes are pretty much Right Out).
#
#  * `server_names` (array of strings; required)
#
#     The hostname(s) which will be proxied.
#
#  * `destination` (string; required)
#
#     The URL to send all traffic to.  If you're happy to transport
#     everything over HTTP to the backend, you can use `http://`
#     unconditionally; if you want to maintain the same protocol, you can
#     specify `'$scheme://...'` as the URL.
#
#  * `resolve_hack` (boolean; optional; default `false`)
#
#     If you are pointing the `destination` at a DNS name, and the IP
#     address behind that name could change, you want to set this option.
#     It uses the nginx-recommended approach of assigning the redirect
#     destination as a variable, and then using that variable in the
#     `proxy_pass` directive.  Sounds insane, right?  Welcome to nginx.
#
#  * `default` (boolean; optional; default `false`)
#
#     Whether you want this site to be the default for the given `ssl_ip`
#     (or the `*_ANY` address) on port 80.
#
#  * `ssl_default` (boolean; optional; default `false`)
#
#     Whether you want this site to be the default for the given `ssl_ip`
#     (or the `*_ANY` address) on port 443.
#
#  * `ssl_cert` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, this attribute is interpreted as
#     being the absolute filename of a PEM-formatted SSL certificate, which
#     will be served for SSL requests.  If this attribute is specified,
#     then the `ssl_key` attribute must also be set.
#
#  * `ssl_key` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, this attribute is interpreted as being
#     the absolute filename of a PEM-formatted SSL private key, which will
#     be served for SSL requests.  If this attribute is specified, then the
#     `ssl_cert` attribute must also be set.
#
#  * `ssl_ip` (string; optional; default `undef`)
#
#     Instruct nginx to listen for SSL connections on a single, specified IP
#     address, rather than relying on SNI to decide which vhost to serve.
#     If you need to support non-SNI-supporting web browsers (basically,
#     Internet Explorer on Windows XP), then you'll need to set this to an
#     IP address for every SSL-enabled vhost you configure.
#
#  * `ssl_redirect` (boolean; optional; default `false`)
#
#     If set to true, `nginx::site` will configure a second vhost, listening
#     for HTTP requests for the vhost's name(s), and unconditionally
#     redirect all HTTP requests to HTTPS requests to `server_name`.
#
#  * `hsts` (boolean or integer; optional; default `false`)
#
#     Useful only when `ssl_redirect` is `true`, setting this to `true` will
#     cause the HTTPS site configured by this resource to have RFC6797 HTTP
#     Strict Transport Security headers added to all responses, with a
#     `max_age` of 1 year.  If you wish to vary the `max_age` returned in
#     all responses, you can set `hsts` to a positive integer value,
#     representing the number of seconds that browsers should honour the
#     HSTS header.
#
#  * `hsts_include_subdomains (boolean; optional; default `true`)
#
#     Can be used to disable the `IncludeSubdomains` flag to the
#     `Strict-Transport-Security` HTTP response header.  Only of use if
#     `$hsts` is set to `true` or an integer.
#
#  * `letsencrypt` (boolean; optional, default `false`)
#
#     An alternative to the `ssl_cert` / `ssl_key` parameters, that causes a
#     Let's Encrypt certificate to be issued (and used) for the
#     `server_names` given if set to `true`.
#
define nginx::site::proxy(
	$server_names,
	$destination,
	$resolve_hack = false,
	$default      = false,
	$ssl_default  = false,
	$ssl_cert     = undef,
	$ssl_key      = undef,
	$ssl_ip       = undef,
	$ssl_redirect = false,
	$hsts         = false,
	$letsencrypt  = false,
) {
	# Where we stick all our config goodies
	$ctx = "http/site_${name}"

	nginx::config::group { $ctx:
		context => "server";
	}

	if $default {
		$default_opt = " default ipv6only=off"
	} else {
		$default_opt = ""
	}

	if $ssl_default {
		$ssl_default_opt = " default ipv6only=off"
	} else {
		$ssl_default_opt = ""
	}

	if $hsts and !$ssl_redirect {
		fail("HSTS is only supported when ssl_redirect => true")
	}

	##########################################################################
	# A vhost by any other name would not serve traffic...

	$names_array = maybe_split($server_names, "\s+")

	nginx::config::parameter {
		"${ctx}/server_name":
			value => join($names_array, " ");
		"${ctx}/root":
			value => "/usr/share/empty";
	}

	if !$ssl_redirect {
		nginx::config::parameter {
			"${ctx}/listen":
				value => $ssl_ip ? {
					undef   => "[::]:80 ${default_opt}",
					default => "${ssl_ip}:80${default_opt}"
				};
		}
	}

	nginx::config::parameter {
		"${ctx}/access_log":
			value => "/var/log/nginx/${name}_access.log combined";
		"${ctx}/error_log":
			value => "/var/log/nginx/${name}_error.log info";
	}

	##########################################################################
	# Oh SSL, u so lulzy

	if ($ssl_cert and !$ssl_key) or ($ssl_key and !$ssl_cert) {
		fail("Must specify both ssl_cert and ssl_key in Nginx::Site[${name}]")
	}

	if $ssl_ip and !($ssl_key or $letsencrypt) {
		fail("Must specify ssl_cert/ssl_key or enable letsencrypt in Nginx::Site[${name}] when ssl_ip is set")
	}

	if $ssl_key {
		nginx::config::parameter {
			"${ctx}/ssl_certificate":
				value => $ssl_cert;
			"${ctx}/ssl_certificate_key":
				value => $ssl_key;
		}
	}

	if $letsencrypt {
		nginx::letsencrypt { $name:
			ctx         => $ctx,
			names_array => $names_array,
		}
	}

	if $ssl_key or $letsencrypt {
		nginx::config::parameter {
			"${ctx}/listen_ssl":
				param => "listen",
				value => $ssl_ip ? {
					undef   => "[::]:443 ssl${ssl_default_opt}",
					default => "${ssl_ip}:443 ssl${ssl_default_opt}"
				};
		}
	}

	##########################################################################
	# Create a separate HTTP vhost to redirect to HTTPS if requested

	if $ssl_redirect {
		if !$ssl_key and !$letsencrypt {
			fail("Must enable SSL on Nginx::Site[${name}] when ssl_redirect => true")
		}

		nginx::config::group { "http/site_sslredir_${name}":
			context => "server"
		}

		nginx::config::parameter {
			"http/site_sslredir_${name}/listen":
				value => $ssl_ip ? {
					undef   => "[::]:80",
					default => "${ssl_ip}:80"
				};
			"http/site_sslredir_${name}/access_log":
				value => "/var/log/nginx/${title}_access.log combined";
			"http/site_sslredir_${name}/error_log":
				value => "/var/log/nginx/${title}_error.log info";
			"http/site_sslredir_${name}/server_name":
				value => join($names_array, " ");
			"http/site_sslredir_${name}/root":
				value => "/usr/share/empty";
		}

		if !empty($alt_names) {
			nginx::config::parameter {
				"http/site_sslredir_${name}/server_alt_names":
					param => "server_name",
					value => join($alt_names_array, " ");
			}
		}

		nginx::site::location { "sslredir_${name}/root":
			site => "sslredir_${name}",
			path => "/",
		}

		nginx::config::rewrite {
			"http/site_sslredir_${name}/ssl_redirect":
				from      => '^(.*)$',
				to        => "https://\$server_name\$1",
				site      => "sslredir_${name}",
				location  => "root",
				permanent => true;
		}

		if $letsencrypt {
			nginx::site::location { "sslredir_${name}/acme-challenge":
				site => "sslredir_${name}",
				path => "/.well-known/acme-challenge",
			}

			nginx::config::parameter { "http/site_sslredir_${title}/location_acme-challenge/alias":
				value   => "/var/lib/letsencrypt/acme-challenge",
			}
		}

		if $hsts {
			if "$hsts" =~ /^\d+$/ {
				$hsts_max_age = $hsts
			} else {
				$hsts_max_age = 31622400  # One year (or, more precisely,
				                          # 366 days, ignoring leap seconds)
			}

			if $hsts_include_subdomains {
				$hsts_inc_subs = "; includeSubDomains"
			} else {
				$hsts_inc_subs = ""
			}

			nginx::config { "http/site_${name}/add_header_hsts":
				content => "add_header Strict-Transport-Security \"max-age=${hsts_max_age}${hsts_inc_subs}\";"
			}
		}
	}

	##########################################################################
	# Le proxy!

	nginx::site::location { "${name}/root":
		site => $name,
		path => "/"
	}

	nginx::http_proxy { $name:
		site         => $name,
		location     => "root",
		destination  => $destination,
		resolve_hack => $resolve_hack,
	}
}
