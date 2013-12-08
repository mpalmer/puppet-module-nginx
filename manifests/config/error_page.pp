# Configures an error page for a site, location, or globally
#
# Not much to say, really.  Just a readable shim around nginx's `error_page`
# directive.
#
# Available attributes:
#
#  * `code` (string; required)
#
#     The error code (or codes, as a space-separated string) to configure the
#     error page for.  Anything in the 4xx or 5xx range should do nicely.
#
#  * `dest` (string; required)
#
#    Where to point the error page to.  Can be a path within the current
#    site (eg `/404.html`), an external URL (eg
#    `http://example.com/forbidden.html`), or a named location (eg
#    `@fallback`).
#    
#  * `site` (string; optional; default `undef`)
#
#     If you want this error page to apply to a given site, specify its name
#     here.
#
#  * `location` (string; optional; default `undef`)
#
#     If the error page should only apply within a specific location, provide
#     its name here.  Note that in order to use this attribute, you must also
#     specify a site name.
#
define nginx::config::error_page(
	$code,
	$dest,
	$site     = undef,
	$location = undef
) {
	# Error handling first
	if $location and !$site {
		fail("Must provide a site when providing a location in Nginx::Config::Error_page[${name}]")
	}
	
	# Now, where's our context?
	if $site {
		if $location {
			$ctx = "http/site_${site}/location_${location}"
		} else {
			$ctx = "http/site_${site}"
		}
	} else {
		$ctx = "http"
	}
	
	nginx::config::parameter {
		"${ctx}/error_page_${code}":
			param => "error_page",
			value => "${code} ${dest}";
	}
}
