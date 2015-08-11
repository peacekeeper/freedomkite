freedomkite
===========

Provides PageKite frontend services for FreedomBoxes (and other devices).

General overview:

1. A set of "voucher codes" is generated, either through the very simple **index.html** and **cgi-bin/generate.pl** files, or through some other out-of-scope mechanism. The voucher codes are stored in a Redis database.
2. Using a voucher code, the **cgi-bin/freedomkite.pl** script can be invoked through an HTTP POST call to associate the voucher code with a domain name.
3. An instance of a PageKite frontend is configured to use DNS-based authentication for determining if a kite exists or not.
4. PowerDNS is configured to use its pipe backend and invoke the **freedomkite-pipe.pl** script when a DNS request is processed.
5. The **freedomkite-pipe.pl** script uses the entries in the Redis database to answer both "regular" and "PageKite authentication" DNS requests.

In other words, a "voucher code" can be used to register a subdomain such as **my.freedombox.me**, and set up a corresponding kite.

Redis
=====

Prerequisites:

* aptitude install redis-server

Redis is used for storing voucher codes and registered domains.

If a voucher code does not exist:

	pagekite-code-12345678-90ab  =>  null

If a voucher code exists, but no domain has been registered with it:

	pagekite-code-12345678-90ab  =>  ''

If a voucher code exists, and a domain has been registered with it:

	pagekite-code-12345678-90ab  =>  'my.freedombox.me'

cgi-bin/generate.pl and index.html
==================================

Prerequisites:

* aptitude install libdata-guid-perl
* aptitude install libredis-perl

This is a simple HTML frontend that issues a new random voucher code and stores it in the Redis database.

cgi-bin/freedomkite.pl
======================

Prerequisites:

* aptitude install libredis-perl

This is a simple Perl CGI script that can be used to query voucher codes and domain names, and to register domain names, using entries in the Redis database.

The API is as follows:

Query by voucher code:

	GET -> https://freedombox.me/cgi-bin/freedomkite.pl?code=1234
	RESPONSE -> 200 
		BODY: {} if voucher code does not exist
		BODY: {'domain':null} if voucher code exists, but no domain name has been registered with it
		BODY: {'domain':'my.freedombox.me'} if voucher code exists, and a domain name has been registered with it

Query by domain name:

	GET -> https://freedombox.me/cgi-bin/freedomkite.pl?domain=test.freedombox.me
	RESPONSE -> 200 
		BODY: {'domain':null} if domain name has not been registered
		BODY: {'domain':'test.freedombox.me'} if domain name has been registered

Register domain name using voucher code:

	POST -> https://freedombox.me/cgi-bin/freedomkite.pl?code=12345678-90ab&domain=test.freedombox.me
	RESPONSE -> 400, if the voucher code does not exist
	RESPONSE -> 200, if the voucher code exists, and the domain name has been registered with it

freedomkite-pipe.pl
===================

Prerequisites:

* aptitude install libdigest-hmac-perl
* aptitude install libredis-perl

This is a pipe backend for PowerDNS, which can dynamically answer
1. "regular" DNS requests, and
1. "PageKite authentication" DNS requests.

The Redis database is used to look up voucher codes and domain names.

See [here](http://pagekite.net/wiki/Howto/DnsBasedAuthentication) for more information about PageKite's DNS-based authentication mechanism.

PowerDNS
========

Prerequisites:

* aptitude install pdns-server pdns-backend-pipe

In /etc/powerdns/pdns.d/pdns.bindbackend.conf

	launch+=bind
	bind-config=/etc/powerdns/bindbackend/named.conf

In /etc/powerdns/pdns.d/pdns.pipebackend.conf

	launch+=pipe
	pipe-command=/path-to-freedomkite/freedomkite-pipe.pl

In /etc/powerdns/bindbackend/named.conf

	zone "freedombox.me" in {
	  type master;
	  file "/etc/powerdns/bindbackend/zones/freedombox.me.zone";
	};


In /etc/powerdns/bindbackend/zones/freedombox.me.zone

	$TTL    86400 ; 24 hours could have been written as 24h or 1d
	$ORIGIN freedombox.me.
	@  1D  IN  SOA ns1.freedombox.me. hostmaster.freedombox.me. (
		2014080202 ; serial
		3H ; refresh
		15 ; retry
		1w ; expire
		3h ; minimum
	)
		IN	NS	ns1.freedombox.me.
		IN	NS	ns2.freedombox.me.
		IN	A	212.232.25.34
	ns1	IN	A	212.232.25.34
	ns2	IN	A	212.232.25.34

PageKite backend
=================

Prerequisites:

* aptitude install pagekite

In /etc/pagekite.d/10_account.rc

	kitename   = my.freedombox.me
	kitesecret = 12345678-90ab

In /etc/pagekite.d/20_frontends.rc

	frontend   = my.freedombox.me:80

In /etc/pagekite.d/80_httpd.rc (example service)

	service_on = http:@kitename : localhost:80 : @kitesecret
	service_on = http:*.@kitename : localhost:80 : @kitesecret

PageKite frontend
================

Prerequisites:

* aptitude install pagekite

In /etc/pagekite.d/20_frontends.rc

	isfrontend
	host = 212.232.25.35
	ports  = 80,443,8080,8443
	protos = http,https,raw

In /etc/pagekite.d/80_domains.rc

	authdomain = freedombox.me:freedombox.me

This **authdomain** setting specifies that the PageKite backend will use the freedombox.me domain name for DNS-based authentication requests.

See [here](https://pagekite.net/wiki/Floss/TechnicalManual/#h3fo) for more information about the **authdomain** setting.

