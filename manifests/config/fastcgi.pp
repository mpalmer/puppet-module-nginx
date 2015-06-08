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
#  * `captured_path` (boolean; optional; default `false`)
#
#     If set to `true`, then the location in which this configuration
#     appears has a regexp which captures the filename to process, relative
#     to `$document_root`.  This is required in certain odd-ball
#     circumstances, where `$request_filename` does not contain the
#     filename, as you'd think it would.
#
define nginx::config::fastcgi(
	$site,
	$location,
	$target,
	$captured_path = false,
) {
	$ctx = "http/site_${site}/location_${location}"
	
	nginx::config::parameter {
		"${ctx}/fastcgi_param_QUERY_STRING":
			param => "fastcgi_param",
			value => 'QUERY_STRING $query_string';
		"${ctx}/fastcgi_param_REQUEST_METHOD":
			param => "fastcgi_param",
			value => 'REQUEST_METHOD $request_method';
		"${ctx}/fastcgi_param_CONTENT_TYPE":
			param => "fastcgi_param",
			value => 'CONTENT_TYPE $content_type';
		"${ctx}/fastcgi_param_CONTENT_LENGTH":
			param => "fastcgi_param",
			value => 'CONTENT_LENGTH $content_length';
		"${ctx}/fastcgi_param_SCRIPT_FILENAME":
			param => "fastcgi_param",
			value => $captured_path ? {
				false => 'SCRIPT_FILENAME $request_filename',
				true  => 'SCRIPT_FILENAME $document_root$1',
			};
		"${ctx}/fastcgi_param_SCRIPT_NAME":
			param => "fastcgi_param",
			value => 'SCRIPT_NAME $fastcgi_script_name';
		"${ctx}/fastcgi_param_REQUEST_URI":
			param => "fastcgi_param",
			value => 'REQUEST_URI $request_uri';
		"${ctx}/fastcgi_param_DOCUMENT_URI":
			param => "fastcgi_param",
			value => 'DOCUMENT_URI $document_uri';
		"${ctx}/fastcgi_param_DOCUMENT_ROOT":
			param => "fastcgi_param",
			value => 'DOCUMENT_ROOT $document_root';
		"${ctx}/fastcgi_param_SERVER_PROTOCOL":
			param => "fastcgi_param",
			value => 'SERVER_PROTOCOL $server_protocol';
		"${ctx}/fastcgi_param_GATEWAY_INTERFACE":
			param => "fastcgi_param",
			value => 'GATEWAY_INTERFACE CGI/1.1';
		"${ctx}/fastcgi_param_SERVER_SOFTWARE":
			param => "fastcgi_param",
			value => 'SERVER_SOFTWARE nginx/$nginx_version';
		"${ctx}/fastcgi_param_REMOTE_ADDR":
			param => "fastcgi_param",
			value => 'REMOTE_ADDR $remote_addr';
		"${ctx}/fastcgi_param_REMOTE_PORT":
			param => "fastcgi_param",
			value => 'REMOTE_PORT $remote_port';
		"${ctx}/fastcgi_param_SERVER_ADDR":
			param => "fastcgi_param",
			value => 'SERVER_ADDR $server_addr';
		"${ctx}/fastcgi_param_SERVER_PORT":
			param => "fastcgi_param",
			value => 'SERVER_PORT $server_port';
		"${ctx}/fastcgi_param_SERVER_NAME":
			param => "fastcgi_param",
			value => 'SERVER_NAME $server_name';
		"${ctx}/fastcgi_param_HTTPS":
			param => "fastcgi_param",
			value => 'HTTPS $https';
		"${ctx}/fastcgi_param_REDIRECT_STATUS":
			param => "fastcgi_param",
			value => 'REDIRECT_STATUS 200';
		"${ctx}/fastcgi_pass":
			value => $target;
	}
}
