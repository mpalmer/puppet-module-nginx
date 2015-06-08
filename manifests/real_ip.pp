# Set real IP headers / trusted sources for a site.
#
# * `site` (string; optional; default `undef`)
#
#   If set, limit the scope of the real_ip configuration to the specified
#   site.  Otherwise, it will be set server-wide.
#
# * `from` (string; optional; default `0.0.0.0/0`)
#
#   A source IP address range to trust to give us legit real IP data.
#
# * `header` (string; optional; default `X-Real-IP`)
#
#   Which header to examine to get the IP address info.
#
# * `recursive` (boolean; optional; default `false`)
#
#   Whether to keep looking through the list of IP addresses to find
#   a non-trusted one, or just take the first address that is found.
#
define nginx::real_ip(
		$site      = undef,
		$from      = "0.0.0.0/0",
		$header    = "X-Real-IP",
		$recursive = false,
) {
	if $site {
		$ctx = "http/site_${site}"
	} else {
		$ctx = "http"
	}

	nginx::config::parameter {
		"${ctx}/set_real_ip_from":
			value => $from;
		"${ctx}/real_ip_header":
			value => $header;
		"${ctx}/real_ip_recursive":
			value => $recursive ? {
				false => "off",
				true  => "on"
			};
	}
}
