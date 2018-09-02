# Define a location within a configured site
#
# This type is quite simple -- it just creates a new configuration group in
# which location-specific configuration parameters can be placed.
#
# Available attributes are:
#
#  * `title` (string; *namevar*)
#
#     The resource name.  The namevar is significant insofar as the "name" of
#     the location, when specified in other types, is only the part after the
#     last forward slash in the title.  For example, if you want to have
#     a location named `root` in every one of your sites (for the root directory),
#     you can't say:
#
#         nginx::site::location { "site": ... }
#
#     for every site you've got, because Puppet will complain about the
#     resource already being defined.  Instead, for each site, you'll want
#     to name it something like `"sitename/root"`, and then the type will
#     make the location name (as used by types like
#     `nginx::config::rewrite`) `root`.
#
#  * `site` (string; required)
#
#     The name of the site you wish this location block to appear in.
#
#  * `path` (string; required)
#
#     The path that this location belongs to.  It can be anything that nginx's
#     `location` directive will accept as the second argument -- so that means
#     it can be a literal path (eg `"/foo"`), a regex (`"^/foo/[a-q]{27}$"`), or
#     an exact path (`"= /foo"`).
#
#  * `root` (string; optional)
#
#     If set, defines a `root` directive for the location, pointing to the directory
#     specified.
#
define nginx::site::location(
	$site,
	$path,
	$root = undef,
) {
	$name_parts = split($name, "/")
	$short_name = $name_parts[-1]
	
	nginx::config::group { "http/site_${site}/location_${short_name}":
		context => "location ${path}"
	}

	if $root {
		nginx::config::parameter { "http/site_${site}/location_${short_name}/root":
			param => "root",
			value => $root,
		}
	}
}
