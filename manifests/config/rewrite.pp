# Configure an nginx rewrite.
#
# This is a very simple, thin wrapper around `nginx::config::parameter` that
# makes it a little easier to see exactly what a rewrite rule is doing. 
# Effectively, all it does is write `rewrite $from $to [permanent|last];` to
# the configuration; the interesting bits are the ability to specify the
# site and (optionally) location in which the rewrite will be effective.  Thus,
# in order to use this type properly, you should make yourself familiar with
# the nginx documentation on the nginx `rewrite` directive.
#
# Attributes available are:
#
#  * `title` (required; *namevar*)
#
#     Sets the "short name" for the rewrite.  This namevar is significant,
#     in that it will be used to construct the name of the file in which the
#     configuration is written.  In the general case, you'll want to set
#     this to something like "sitename/rewritename", so as to make the
#     resource globally unique within Puppet.  Everything after the last
#     forward-slash in the title will be used as the filename; the rest is
#     discarded.
#
#  * `from` (string; required)
#
#     This is the first parameter in the `rewrite` nginx directive.  It
#     should be a regular expression which will match the paths you wish to
#     rewrite.  Parentheses can be used to collect substrings for
#     substitution into the `to` attribute.
#
#     When constructing your regular expressions, remember that `$` is a
#     special character in double-quoted Puppet strings; it is recommended
#     that you single quotes (or escape your `$`).
#     
#  * `to` (string; required)
#
#     This is the URL or path to rewrite *to*.  It can incorporate the
#     substitution variables `$1`, `$2`, etc as required.  Remember that `$`
#     is a special character in double-quoted Puppet strings; you'll need to
#     either escape them or use single quotes.
#
#  * `site` (string; required)
#
#     The name of the site in which to add this rewrite.  This should be the
#     namevar of a separate `nginx::site` resource (although this isn't
#     *enforced*, just in case you're up to some serious shenanigans).
#
#  * `location` (string; optional; default `undef`)
#
#     If set to a non-`undef` value, this will be taken as a location within
#     the specified site in which to place the rewrite.  If set to `undef`,
#     then the rewrite will be placed in the global scope, and apply to all
#     requests.
#
#  * `permanent` (boolean; optional; default `false`)
#
#     Whether or not to mark this rewrite as permanent.  If set to `true`,
#     then the keyword `permanent` will be added to the end of the rewrite
#     rule.  Only one of `permanent` or `last` may be `true` in the one
#     rewrite rule.
#
#  * `last` (boolean; optional; default `false`)
#
#     If set to `true`, the keyword `last` will be added to the end of the
#     rewrite rule.  Only one of `permanent` or `last` may be `true` in the
#     one rewrite rule.
#
define nginx::config::rewrite(
	$from,
	$to,
	$site,
	$location  = undef,
	$permanent = false,
	$last      = false
) {
	$name_parts = split($name, "/")
	$short_name = $name_parts[-1]
	
	if $location {
		$resource_name = "http/site_${site}/location_${location}/${short_name}"
	} else {
		$resource_name = "http/site_${site}/${short_name}"
	}
	
	if $permanent and $last {
		fail("No more than one of last or permanent can be specified in Nginx::Config::Rewrite[${name}]")
	}
	
	if $permanent {
		$suffix = " permanent"
	}
	
	if $last {
		$suffix = " last"
	}
	
	nginx::config::parameter { $resource_name:
		param => "rewrite",
		value => "${from} ${to}${suffix}";
	}
}
