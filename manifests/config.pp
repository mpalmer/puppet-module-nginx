# The master type for setting up nginx configuration snippets.
#
# **Introductory warning**: this type is not designed to fulfill all of your
# nginx configuration needs.  For the vast majority of your configuration,
# you should be using some *other* type to do your configuration for you. 
# If you find yourself using this type a lot in your end manifests, either
# you're doing it *way* wrong, or you should be writing some new convenience
# types to abstract away the low-level detail that is this type.
#
# This type's purpose is to serve as the "catch-all" for adding
# configuration to an nginx config tree.  It's usage is simple, but subtle.
#
# It only takes a few configuration parameters:
#
#  * `title` (string; *namevar*)
#
#     This is the path (relative to `/etc/nginx/nginx.conf.d`) to the file
#     which will contain the configuration data you provide, without the
#     trailing `.conf`.
#
#     Any containing subdirectories you specify must be created separately,
#     by you (or a helper type, like nginx::config::group).
#
#  * `source` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, this will be used as a source path to
#     copy a complete configuration file from.
#
#     Note that *exactly one* of `source` or `content` must be specified in
#     every `nginx::config` resource.
#
#  * `content` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, this attribute will be interpreted as a
#     string which will be the content of the configuration file in the
#     tree.  The `template()` function is your best friend here.
#
#     Note that *exactly one* of `source` or `content` must be specified in
#     every `nginx::config` resource.
#
define nginx::config(
	$source  = undef,
	$content = undef
) {
	if (!$source and !$content) or ($source and $content) {
		fail("Must pass exactly one of source or content to Nginx::Config[${name}]")
	}
	
	file { "/etc/nginx/nginx.conf.d/${name}.conf":
		ensure  => file,
		source  => $source,
		content => $content,
		owner   => "root",
		group   => "root",
		mode    => 0444,
		notify  => Noop["nginx/configured"]
	}
}
