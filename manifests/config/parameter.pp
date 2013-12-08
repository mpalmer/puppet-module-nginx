# Sets a single nginx configuration parameter
#
# If you want to just set a single config parameter in some context, this is
# the way to do it.  This type only takes one attribute other than the
# namevar, and that's `value` -- what you want to set the config parameter
# to (basically, any string you like).  The namevar itself is special, and
# provides both the context in which you wish to set the configuration
# parameter, and also the name of the config parameter itself.
#
# For parameters you might set in the top-level, "global" context, the
# namevar should be just the parameter name, like this:
#
#     nginx::config::parameter {
#       "user"      => "...";
#       "pid"       => "...";
#       "error_log" => "...";
#     }
#
# That's easy -- we'll just get a config snippet that contains something like
# `user ...;`.
#
# For config parameters within a context, things are *slightly* more
# difficult.  In this case, the namevar consists of a forward
# slash-separated list of strings (for example,
# `http/site_example.com/access_log`).  The name of the configuration
# parameter to be set is the last element of this list (in this case,
# `acces_log`), while the rest of the string is the context for the
# configuration parameter (`http/site_example.com` in our example).
#
# You're responsible for setting up the configuration groups that make the
# context portion of the namevar valid.
#
# Available attributes are:
#
#  * `title` (string; *namevar*)
#
#     The name of the resource, and also the configuration parameter name
#     (and optionally the context in which to place the parameter).  See the
#     introduction, above, for more details on how this works.
#
#  * `value` (string; required)
#
#     The value to set the configuration parameter to.  What might be valid
#     for any given configuration parameter is determined by nginx, and we
#     don't do any useful error checking in this type.  The value is placed
#     in the nginx configuration file without any quoting or escaping -- if
#     you want any of that sort of thing, you'll have to do it yourself.
#
#  * `param` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, the name of the parameter which is written
#     to the configuration file will be taken from `param`, rather than
#     parsed out of the `namevar`.
#
define nginx::config::parameter(
	$param = undef,
	$value
) {
	if $param {
		$nginx_config_parameter_name = $param
	} else {
		$parts = split($name, "/")
		$nginx_config_parameter_name  = $parts[-1]
	}
	$nginx_config_parameter_value = $value
	
	nginx::config { $name:
		content => template("nginx/etc/nginx/config-parameter");
	}
}
