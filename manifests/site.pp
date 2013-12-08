# Configures an nginx vhost.
#
# This rather behemothic type does a lot of the standard configuration
# required for some common patterns of nginx vhost.  At its most basic
# level, it configures an HTTP site which serves purely static content out
# of `${base_dir}/htdocs`, and writes access/error logs into
# `${base_dir}/logs/{access,error}.log`.
#
# However, it can do a fair bit more than that.  The alternate "deployment
# patterns" that are currently supported are:
#
#  * **SSL-enabled vhost**: If you want to serve the same content and
#    configuration over both HTTP and HTTPS for the same set of names, you
#    can simply set `ssl_cert` and `ssl_key` (and optionally `ssl_ip`) to
#    get a vhost that will serve both protocols simultaneously.
#
#  * **Redirect to SSL**: If you want a particular site to be "SSL only",
#    set `ssl_redirect` (as well as `ssl_cert`, `ssl_key`, and optionally
#    `ssl_ip`) and we'll configure a separate vhost that responds to HTTP
#    requests with a 301 permanent redirect to the equivalent HTTPS URL.
#
# The full set of available configuration attributes are:
#
#  * `title` (string; *namevar*)
#
#     A unique name for the vhost.  It has no particular meaning for the
#     `nginx::site` type, other than being used in the filenames that define
#     the configuration parameters (so you *probably* want to stick to
#     alpha-numerics, periods, dashes, underscores, that sort of thing --
#     forward slashes are pretty much Right Out).
#
#  * `base_dir` (string; required)
#
#     The directory from which all other locations for the vhost are
#     derived.  Special subdirectories in here are `logs` (where all the
#     logs live), and `htdocs` (the "document root", files within which are
#     directly accessable from the Internet).
#
#  * `user` (string; optional; default `"root"`)
#
#     This tells Puppet to configure the site to be manageable by the
#     specified user.
#
#  * `server_name` (string; required)
#
#     An FQDN which is the "canonical" name for the vhost.  You can have as
#     many names as you like be associated with a single vhost (see the
#     `alt_names` parameter, below), but a single name is needed for SSL
#     redirections, and this is the name that will be used.
#
#  * `alt_names` (array of strings; optional; default `[]`)
#
#     An array of zero or more other FQDNs for which this vhost will
#     also respond, in addition to the FQDN provided in `server_name`.
#
#  * `default` (boolean; optional; default `false`)
#
#     Whether or not this site is the default for HTTP requests whose
#     `Host:` header doesn't match any specific site.  Note that setting
#     more than one site to be the default will likely make nginx very
#     unhappy.
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
#  * `ssl-default` (boolean; optional; default `false`)
#
#     Whether or not this site is the default for HTTPS requests to this server
#     (or at least to the IP address specified in `ssl_ip`, if set).
#
define nginx::site(
	$base_dir,
	$user         = "root",
	$server_name,
	$alt_names    = [],
	$default      = false,
	$ssl_cert     = undef,
	$ssl_key      = undef,
	$ssl_ip       = undef,
	$ssl_redirect = false,
	$ssl_default  = false
) {
	# Template variables
	$nginx_site_base_dir = $base_dir

	# Where we stick all our config goodies
	$ctx = "http/site_${name}"
	nginx::config::group { $ctx:
		context => "server";
	}
	
	if $default {
		$default_opt = " default"
	} else {
		$default_opt = ""
	}
	
	if $ssl_default {
		$ssl_default_opt = " default"
	} else {
		$ssl_default_opt = ""
	}
	
	##########################################################################
	# A vhost by any other name would not serve traffic...
	
	nginx::config::parameter {
		"${ctx}/server_name":
			value => $server_name;
		"${ctx}/root":
			value => "${base_dir}/htdocs";
	}

	if !empty($alt_names) {
		# We let people specify alt_names as a string if they want, but join
		# will get mighty pissy if it doesn't get an array, so let's use the magic
		# of maybe_split to help us out
		$alt_names_array = maybe_split($alt_names, "\s+")
		
		nginx::config::parameter {
			"${ctx}/server_alt_names":
				param => "server_name",
				value => join($alt_names_array, " ");
		}
	}
	
	if !$ssl_redirect {
		nginx::config::parameter {
			"${ctx}/listen":
				value => $ssl_ip ? {
					undef   => "80${default_opt}",
					default => "${ssl_ip}:80${default_opt}"
				};
		}
	}

	##########################################################################
	# Logging and log rotation

	$nginx_site_user = $user

	file {
		"${base_dir}/logs":
			ensure  => directory,
			mode    => 0755,
			owner   => $user,
			group   => "root",
			before  => Noop["nginx/configured"];
		"/etc/logrotate.d/nginx-${name}":
			ensure  => file,
			content => template("nginx/etc/logrotate.d/nginx-site"),
			mode    => 0444,
			owner   => "root",
			group   => "root",
			before  => Noop["nginx/configured"];
	}
	
	nginx::config::parameter {
		"${ctx}/access_log":
			value => "${base_dir}/logs/access.log combined";
		"${ctx}/error_log":
			value => "${base_dir}/logs/error.log info";
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
					undef   => "443 ssl${ssl_default_opt}",
					default => "${ssl_ip}:443 ssl${ssl_default_opt}"
				};
		}
	}

	##########################################################################
	# Create a separate HTTP vhost to redirect to HTTPS if requested
	
	if $ssl_redirect {
		if !$ssl_cert or !$ssl_key {
			fail("Must pass ssl_cert and ssl_key to Nginx::Site[${name}] when ssl_redirect => true")
		}

		nginx::config::group { "http/site_sslredir_${name}":
			context => "server"
		}
			
		nginx::config::parameter {
			"http/site_sslredir_${name}/listen":
				value => $ssl_ip ? {
					undef   => "80",
					default => "${ssl_ip}:80"
				};
			"http/site_sslredir_${name}/access_log":
				value => "${base_dir}/logs/access.log combined";
			"http/site_sslredir_${name}/error_log":
				value => "${base_dir}/logs/error.log info";
			"http/site_sslredir_${name}/server_name":
				value => $server_name;
			"http/site_sslredir_${name}/root":
				value => "/usr/share/empty";
		}
		
		if !empty($alt_names) {
			$alt_names_array = maybe_split($alt_names, "\s+")
		
			nginx::config::parameter {
				"http/site_sslredir_${name}/server_alt_names":
					param => "server_name",
					value => join($alt_names_array, " ");
			}
		}
		
		nginx::config::rewrite {
			"http/site_sslredir_rspec/ssl_redirect":
				from      => '^(.*)$',
				to        => "https://${server_name}\$1",
				site      => "sslredir_${name}",
				permanent => true;
		}
	}
}
