# Configure a location to proxy traffic to a FastCGI server.
#
# This sounds like it should be simple, but it gets real ugly, real fast.

# Attributes available are:
#
#  * `title` (required; *namevar*)
#
#     Sets the "short name" for the fcgi proxy.  This namevar is significant,
#     in that it will be used to construct the name of the file in which the
#     configuration is written.  In the general case, you'll want to set
#     this to something like "sitename/rewritename", so as to make the
#     resource globally unique within Puppet.  Everything after the last
#     forward-slash in the title will be used as the filename; the rest is
#     discarded.
#
#  * `site` (string; required)
#
#     The name of the site in which to add this rewrite.  This should be the
#     namevar of a separate `nginx::site` resource (although this isn't
#     *enforced*, just in case you're up to some serious shenanigans).
#
#  * `location` (string; required)
#
#     The name of the location in the site to place the proxy configuration. 
#     This should be the part after the last forward slash namevar of an
#     `nginx::location` resource which has been defined as being a part of
#     the site named in the `site` attribute.
#
#  * `target` (string; required)
#
#     The location to which FastCGI requests should be sent.  This can be
#     one of:
#
#     * `unix:<path>` -- connect to the FastCGI server listening on a Unix
#       socket located in the local filesystem at `<path>`; or
#
#     * `<address>:<port>` -- connect to the FastCGI server listening on the
#       specified address and port.  An address can be an IPv4 literal, an
#       IPv6 literal enclosed in square brackets, or a name which is
#       resolvable to and IPv4 or IPv6 address.
#
define nginx::config::fastcgi(
	$site,
	$location,
	$target
) {
	$ctx = "http/site_${site}/location_${location}"
	
	nginx::config::parameter {
		"${ctx}/fastcgi_param_QUERY_STRING":
			param => "fastcgi_param",
			value => '$query_string';
		"${ctx}/fastcgi_param_REQUEST_METHOD":
			param => "fastcgi_param",
			value => '$request_method';
		"${ctx}/fastcgi_param_CONTENT_TYPE":
			param => "fastcgi_param",
			value => '$content_type';
		"${ctx}/fastcgi_param_CONTENT_LENGTH":
			param => "fastcgi_param",
			value => '$content_length';
		"${ctx}/fastcgi_param_SCRIPT_FILENAME":
			param => "fastcgi_param",
			value => '$request_filename';
		"${ctx}/fastcgi_param_SCRIPT_NAME":
			param => "fastcgi_param",
			value => '$fastcgi_script_name';
		"${ctx}/fastcgi_param_REQUEST_URI":
			param => "fastcgi_param",
			value => '$request_uri';
		"${ctx}/fastcgi_param_DOCUMENT_URI":
			param => "fastcgi_param",
			value => '$document_uri';
		"${ctx}/fastcgi_param_DOCUMENT_ROOT":
			param => "fastcgi_param",
			value => '$document_root';
		"${ctx}/fastcgi_param_SERVER_PROTOCOL":
			param => "fastcgi_param",
			value => '$server_protocol';
		"${ctx}/fastcgi_param_GATEWAY_INTERFACE":
			param => "fastcgi_param",
			value => 'CGI/1.1';
		"${ctx}/fastcgi_param_SERVER_SOFTWARE":
			param => "fastcgi_param",
			value => 'nginx/$nginx_version';
		"${ctx}/fastcgi_param_REMOTE_ADDR":
			param => "fastcgi_param",
			value => '$remote_addr';
		"${ctx}/fastcgi_param_REMOTE_PORT":
			param => "fastcgi_param",
			value => '$remote_port';
		"${ctx}/fastcgi_param_SERVER_ADDR":
			param => "fastcgi_param",
			value => '$server_addr';
		"${ctx}/fastcgi_param_SERVER_PORT":
			param => "fastcgi_param",
			value => '$server_port';
		"${ctx}/fastcgi_param_SERVER_NAME":
			param => "fastcgi_param",
			value => '$server_name';
		"${ctx}/fastcgi_param_HTTPS":
			param => "fastcgi_param",
			value => '$https';
		"${ctx}/fastcgi_param_REDIRECT_STATUS":
			param => "fastcgi_param",
			value => '200';
		"${ctx}/fastcgi_pass":
			value => $target;
	}
}
