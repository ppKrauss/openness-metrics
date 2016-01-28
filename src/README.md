# Implementations
Different servers and languages can be used as "*proxy* to the SQL resolution core". The reference-implementation is *PostgreSQL 9.4 [database](https://en.wikipedia.org/wiki/Relational_database_management_system) + PHP5 [proxy](https://en.wikipedia.org/wiki/Proxy_pattern) + Apache2 [webserver](https://en.wikipedia.org/wiki/Web_server) and [rewrite engine](https://en.wikipedia.org/wiki/Rewrite_engine)*, but we can replace any of this three components by other preferred ones.
The ideal (consume dream) is *PostgreSQL 9.5 + Nginx + NodeJS*.

# endpoints
There are two approaches to handle methods at endpoints,

  1. *one for each method*: pretty, but need a HTTP configuration, and this configs depends on server.
  2. *one for all methods*: ugly but works fine and most simple!

For the approach-2, Apache and Nginx are the two most common open source web servers in the world (together they are serving over 50% of traffic on the Internet).

Syntax for basic GET usage: `endpoint_method/outmode/param1=val1;param2=val2;...` or `endpoint_method?param1=val1&param2=val2&...` Main endpoints and its (GET or JSON POST) parameters,

* License resolution endpoints (cmd):

 * licname_format:
 * licname_to_name:
 * licname_to_info:
 * licqts_calc:

* Family resolution endpoints (cmd):

 * famname_format:
 * famname_to_name:
 * famname_to_id:
 * famname_to_info:
 * famqts_calc:

* Output variation by endpoint (outmode)

  * *js*: JSON default
  * *htm*: for jQuery (load) response.

## Apache server
Apache2 `.htaccess`, on the VirtualHost's `DocumentRoot` directory of the mapped `ServerName` (`<subdomain>.<domain>`), add the folowing `.htaccess` file, for an endpoint syntax option:

```
RewriteEngine on

# If requested url is an existing file or folder, don't touch it
RewriteCond %{REQUEST_FILENAME} -d [OR]
RewriteCond %{REQUEST_FILENAME} -f
RewriteRule . - [L]

# If we reach here, this means it's not a file or folder, we can rewrite...
RewriteRule ^((?:lic|fam)(?:name_format|name_to_name|name_to_info|qts_calc)|famname_to_id)(?:/(.+))?(?:\?(.+))?$     index.php?cmd=$1&$2&params=$3 [L]
```

## Nginx server
?

## PostgreSQL 9.4+ database ##
The [ini.sql](ini.sql) and database behaviour was tunned to pg9.4+, so, **no other option in mind**.

## PHP proxy ##
The referemce-implementation, for use with Apache2.

## Python proxy ##
... another taste ...

## NodeJS proxy ##
... a good option...
