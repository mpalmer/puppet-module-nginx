# Provide the specified site (or set the defaults) to an SSL configuration
# that is more secure than the default.
#
# Specifically, we:
#
#  * Disable SSLv2 and SSLv3, for they are old and crappy;
#
#  * Prefer our provided list of ciphers, instead of letting the client dictate
#    terms; and
#
#  * Prefer ciphers which provide perfect forward secrecy over those that don't,
#    and disable entirely algorithms which are known to be somewhat compromised
#    (RC4 and MD5, primarily).
#
# The namevar of this type is insignificant.  The only attribute we have is:
#
#  * `site` (string; optional; default `undef`)
#
#     If set to something other thant `undef` (the default), then the
#     hardened SSL configuration will be applied to the site with the
#     specified name.  Otherwise, the configuration will be applied to the
#     "default" context.
#
define nginx::ssl::hardened(
	$site = undef
) {
	if $site {
		$ctx = "http/site_${site}"
	} else {
		$ctx = "http"
	}
	
	nginx::config::parameter {
		"${ctx}/ssl_ciphers":
			value => "ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!AECDH:!MD5:!DSS";
		"${ctx}/ssl_prefer_server_ciphers":
			value => "on";
		"${ctx}/ssl_protocols":
			value => "TLSv1 TLSv1.1 TLSv1.2";
	}
}
