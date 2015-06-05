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
define nginx::site::proxy(
	$server_names,
	$destination,
	$ssl_cert                = undef,
	$ssl_key                 = undef,
	$ssl_ip                  = undef,
) {
	# Where we stick all our config goodies
	$ctx = "http/site_${name}"

	nginx::config::group { $ctx:
		context => "server";
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

	nginx::config::parameter {
		"${ctx}/listen":
			value => $ssl_ip ? {
				undef   => "[::]:80",
				default => "${ssl_ip}:80"
			};
	}

	nginx::config::parameter {
		"${ctx}/access_log":
			value => "/var/log/nginx/${name}_access.log combined";
		"${ctx}/error_log":
			value => "/var/log/nginx/${name}_error.log info";
	}

	##########################################################################
	# Oh SSL

	if ($ssl_cert and !$ssl_key) or ($ssl_key and !$ssl_cert) {
		fail("Must specify both ssl_cert and ssl_key in Nginx::Site[${name}]")
	}

	if $ssl_ip and !$ssl_key {
		fail("Must specify ssl_cert and ssl_key in Nginx::Site[${name}] when ssl_ip is set")
	}

	if $ssl_cert and $ssl_key {
		nginx::config::parameter {
			"${ctx}/ssl_certificate":
				value => $ssl_cert;
			"${ctx}/ssl_certificate_key":
				value => $ssl_key;
			"${ctx}/listen_ssl":
				param => "listen",
				value => $ssl_ip ? {
					undef   => "[::]:443 ssl",
					default => "${ssl_ip}:443 ssl"
				};
		}
	}

	##########################################################################
	# Le proxy!

	nginx::site::location { "${name}/root":
		site => $name,
		path => "/"
	}

	nginx::http_proxy { $name:
		site        => $name,
		location    => "root",
		destination => $destination,
	}
}
