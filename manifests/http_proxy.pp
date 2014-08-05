# Setup a location as an HTTP proxy to another server.
#
# Attributes:
#
#  * `site` (string; required)
#
#     The name of the site in which the location you wish to proxy from is
#     defined.
#
#  * `location` (string; required)
#
#     The name of the location which you wish to proxy.
#
#  * `destination` (string; required)
#
#     The URL to which you wish to proxy.  This can either be a direct URL,
#     or an upstream name.
#
define nginx::http_proxy(
		$site,
		$location,
		$destination
) {
	nginx::config::parameter {
		"http/site_${site}/location_${location}/proxy_pass":
			value => $destination;
		"http/site_${site}/location_${location}/proxy_set_header_host":
			param => "proxy_set_header",
			value => "Host \$host";
		"http/site_${site}/location_${location}/proxy_set_header_x_real_ip":
			param => "proxy_set_header",
			value => "X-Real-IP \$remote_addr";
		"http/site_${site}/location_${location}/proxy_read_timeout":
			value => "600";
		"http/site_${site}/location_${location}/proxy_send_timeout":
			value => "600";
	}
}
