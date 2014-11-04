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
#  * `connect_timeout` (integer; optional; default `60`)
#
#     How long, in seconds, to wait to make a connection to the backend.
#
#  * `read_timeout` (integer; optional; default `60`)
#
#     How long, in seconds, to wait between receiving a portion of the
#     response from the backend.  Note that this is not a timeout on the
#     *entire* request or response, merely the maximum time between received
#     packets.
#
#  * `send_timeout` (integer; optional; default `60`)
#
#     How long, in seconds, to wait between sending a portion of the request
#     to the backend.  Note that this is not a timeout on the *entire*
#     request or response, merely the maximum time between sent packets.
#
define nginx::http_proxy(
		$site,
		$location,
		$destination,
		$connect_timeout = 60,
		$read_timeout    = 60,
		$send_timeout    = 60,
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
		"http/site_${site}/location_${location}/proxy_set_header_x_forwarded_proto":
			param => "proxy_set_header",
			value => "X-Forwarded-Proto \$scheme";
		"http/site_${site}/location_${location}/proxy_connect_timeout":
			value => "${connect_timeout}s";
		"http/site_${site}/location_${location}/proxy_read_timeout":
			value => "${read_timeout}s";
		"http/site_${site}/location_${location}/proxy_send_timeout":
			value => "${send_timeout}s";
	}
}
