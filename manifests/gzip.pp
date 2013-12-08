# Sets up gzip response content compression.
#
# Specify either a site name in `site` to apply this configuration to only a single
# site, or else leave it out to have it apply to all vhosts.
#
# Available attributes:
#
#  * `site` (string; optional; default `undef`)
#
#     If you want a single site's content to be compressed, then you should
#     set this attribute to the name of the site whose content should be
#     compressed.  Otherwise, leave it as the default (ie don't specify it
#     at all) to have the config apply to all sites on the system.
#
define nginx::gzip(
	$site = undef
) {
	if $site {
		$ctx = "http/site_${site}"
	} else {
		$ctx = "http"
	}
	
	nginx::config::parameter {
		"${ctx}/gzip":
			value => "on";
		"${ctx}/gzip_min_length":
			value => "1000";
		"${ctx}/gzip_comp_level":
			value => "6";
		"${ctx}/gzip_proxied":
			value => "expired no-cache no-store private auth";
		"${ctx}/gzip_types":
			value => "text/plain application/xml text/xml image/x-icon image/gif text/css application/javascript application/x-javascript";
		"${ctx}/gzip_disable":
			value => "\"MSIE [1-6]\\.\"";
		"${ctx}/default_type":
			value => "text/html";
	}
}
