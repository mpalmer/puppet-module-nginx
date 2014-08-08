# Configure a "config group" in the nginx config tree
#
# A "config group", in this case, is what I'm using to refer to a bundle of
# configuration files all contained within a common wrapper element.  A simple
# example of this is the `http` block that's pretty much standard in every
# nginx configuration.  Traditionally, it would look something like this
# inside `nginx.conf`:
#
#     http {
#       include /etc/nginx/mime.types;
#       access_log /var/log/nginx/access.log;
#       sendfile on;
#       ...
#     }
#
# Now, in *our* world view, all nginx configuration is specified via
# include files; in that case, we want the `http` block to look like this:
#
#     http {
#       include /etc/nginx/nginx.conf.d/http/*.conf;
#     }
#
# And, because this is a "top-level" configuration, we'd put this little
# snippet into `/etc/nginx/nginx.conf.d/http.conf`, so it would be read at
# the top-level.  Also, we want to create the `/etc/nginx/nginx.conf.d/http`
# directory, so that any configuration that gets dropped into place will
# have somewhere to go.
#
# In a nutshell, that's what `nginx::config::group` is all about -- we
# create the directory and the snippet to include everything *in* the
# directory.  Pretty simple, huh?
#
# You are free to "nest" configuration groups as you see fit, although you
# will have to manually create the enclosing groups.  So, for instance, you
# could have the following tree if you so chose (and if some of these levels
# weren't automagically setup for you by `nginx::server`):
#
#     nginx::config::group {
#       "http": context => "http";
#       "http/site_example.com": context => "server";
#       "http/site_example.com/location_root": context => "location";
#     }
#
# This would setup a tree that might "flatten out" to look something like
# this:
#
#     http {
#       server {
#         location {
#           # tralala
#         }
#       }
#     }
#
# ... with the added bonus that *anything* could adjust the configuration of
# any of those levels by dropping their own configuration snippets in at any
# of those levels.
# 
# The configuration options you can use are:
#
#  * `title` (string; *namevar*)
#
#     This specifies the directory -- and config filename -- which will be
#     created for this config group, relative to `/etc/nginx/nginx.conf.d`.
#     Keep it simple.
#
#  * `context` (string; required)
#
#     What type of group this is.  It is used to construct the "top level"
#     configuration file; for example, in the example given in the
#     introduction, `context` would be set to `"http"`.
#
define nginx::config::group(
	$context
) {
	# The directory in which things can be put
	file { "/etc/nginx/nginx.conf.d/${name}":
		ensure  => directory,
		mode    => 0755,
		owner   => "root",
		group   => "root",
		purge   => true,
		recurse => true,
		force   => true,
	}

	# Template variables
	$nginx_config_group_context = $context
	$nginx_config_group_name    = $name
	
	# The config that includes things in the directory in which things can be
	# put
	nginx::config { $name:
		content => template("nginx/etc/nginx/config-group")
	}
}
		
