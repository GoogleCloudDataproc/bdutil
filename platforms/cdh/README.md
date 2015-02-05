Deploying Cloudera Data Hub (CDH) on Google Compute Engine
==========================================================

Basic Usage
-----------

This plugin replaces the vanilla Apache binary tarballs with [Cloudera Data Hub](http://www.cloudera.com/content/cloudera/en/products-and-services/cdh.html) packages. Cluster configuration is the same as in core bdutil.

    ./bdutil -e platforms/cdh/cdh_env.sh deploy

Or alternatively, using shorthand syntax:

    ./bdutil -e cdh deploy

Status
------

This plugin is currently considered experimental and not officially supported.
Contributions are welcome.
