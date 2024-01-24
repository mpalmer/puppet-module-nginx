# Configures a mass-redirection nginx vhost.
#
# This is a very simple kind of a site: it simply redirects all requests to
# the given vhost to another.  There really isn't much to it.
#
# The full set of available configuration attributes are:
#
#  * `title` (string; *namevar*)
#
#     A unique name for the vhost.  It has no particular meaning for the
#     type, other than being used in the filenames that define the
#     configuration parameters (so you *probably* want to stick to
#     alpha-numerics, periods, dashes, underscores, that sort of thing --
#     forward slashes are pretty much Right Out).
#
#  * `server_names` (array of strings; required)
#
#     The names to which the redirection will apply.
#
#  * `target` (string; required)
#
#     The destination of the redirect.  This must be an HTTP or HTTPS
#     URL.  Note that the path of the initial request will be appended
#     to this URL unless `append_path` is set to `false`.
#
#  * `append_path` (boolean; optional; default `true`)
#
#     If set to `true` (the default), then whatever path was given to the
#     redirection vhost will be appended to the `target` parameter when
#     generating the destination of the redirect.  This is useful when you're
#     moving one site to a new name.  On the other hand, if you just want all
#     traffic to any part of a vhost to go to a single URL, then you set this
#     attribute to `false`, and the redirect will always be to the exact URL
#     specified in `target`.
#
#  * `default` (boolean; optional; default `false`)
#
#     Whether or not this site is the default for HTTP requests whose
#     `Host:` header doesn't match any specific site.  Note that setting
#     more than one site to be the default will likely make nginx very
#     unhappy.
#
#  * `letsencrypt` (boolean; optional;default `false`)
#
#     An alternative to the `ssl_cert` / `ssl_key` parameters, that causes a
#     Let's Encrypt certificate to be issued (and used for SSL) for all
#     names of the site if set to `true`.
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
#  * `ssl_default` (boolean; optional; default `false`)
#
#     Whether or not this site is the default for HTTPS requests to this server
#     (or at least to the IP address specified in `ssl_ip`, if set).
#
define nginx::site::redir(
	$server_names,
	$target,
	$append_path = true,
	$default     = false,
	$letsencrypt = false,
	$ssl_cert    = undef,
	$ssl_key     = undef,
	$ssl_ip      = undef,
	$ssl_default = false,
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
				undef   => "[::]:80${default_opt}",
				default => "${ssl_ip}:80${default_opt}"
			};
	}

	nginx::config::parameter {
		"${ctx}/access_log":
			value => "/var/log/nginx/${title}_access.log combined";
		"${ctx}/error_log":
			value => "/var/log/nginx/${title}_error.log info";
	}

	##########################################################################
	# Oh SSL

	if ($ssl_cert and !$ssl_key) or ($ssl_key and !$ssl_cert) {
		fail("Must specify both ssl_cert and ssl_key in Nginx::Site[${name}]")
	}

	if $ssl_ip and !($ssl_key or $letsencrypt) {
		fail("Must specify ssl_cert and ssl_key, or letsencrypt, in Nginx::Site[${name}] when ssl_ip is set")
	}

	if ($ssl_cert and $ssl_key) or $letsencrypt {
		nginx::config::parameter {
			"${ctx}/listen_ssl":
				param => "listen",
				value => $ssl_ip ? {
					undef   => "[::]:443 ssl${ssl_default_opt}",
					default => "${ssl_ip}:443 ssl${ssl_default_opt}"
				};
		}

		if $ssl_cert and $ssl_key {
			nginx::config::parameter {
				"${ctx}/ssl_certificate":
					value => $ssl_cert;
				"${ctx}/ssl_certificate_key":
					value => $ssl_key;
			}
		} elsif $letsencrypt {
			nginx::letsencrypt { $name:
				ctx         => $ctx,
				names_array => $names_array,
			}
		}
	}

	##########################################################################
	# The mighty redirection

	nginx::site::location { "${name}/root":
		site => $name,
		path => "/"
	}

	$target_pattern = $append_path ? {
		true  => "${target}\$1",
		false => $target,
	}

	nginx::config::rewrite {
		"${ctx}/redirect":
			from      => '^(.*)$',
			to        => $target_pattern,
			site      => $name,
			location  => "root",
			permanent => true;
	}
}
