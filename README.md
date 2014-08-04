freedomkite
===========

Provides PageKite frontend services for FreedomBoxes

Prerequisites
=============

aptitude install libdata-gui-perl
aptitude install libredis-perl

Redis
=====

FreedomKite uses Redis for storing voucher codes and registered domains.

If a voucher code does not exist:
	pagekite-code-84c95ef5-7690  =>  null

If a voucher code exists, but no domain has been registered with it:
	pagekite-code-84c95ef5-7690  =>  ''

If a voucher code exists, and a domain has been registered with it:
	pagekite-code-84c95ef5-7690  =>  'my.freedombox.me'

cgi-bin/freedomkite.pl
======================

This is a simple Perl CGI script that can be used to query and redeem voucher codes.

The API is as follows:

Query by voucher code:

	GET -> https://freedombox.me/cgi-bin/freedomkite.pl?code=1234
	RESPONSE -> 200 
		BODY: {} if voucher code does not exist
		BODY: {'domain':null} if voucher code exists, but no domain name has been registered
		BODY: {'domain':'test.freedombox.me'} if voucher code exists, and a domain name has been registered

Query by domain name:

	GET -> https://freedombox.me/cgi-bin/freedomkite.pl?domain=test.freedombox.me
	RESPONSE -> 200 
		BODY: {'domain':null} if domain name has not been registered
		BODY: {'domain':'test.freedombox.me'} if domain name has been registered

Register domain name using voucher code:

	POST -> https://freedombox.me/cgi-bin/freedomkite.pl?code=1234&domain=test.freedombox.me
	RESPONSE -> 400
	RESPONSE -> 200

PageKite front-end
==================

freedomkite-pipe.pl
===================

This is a pipe backend for PowerDNS, which can dynamically answer requests

