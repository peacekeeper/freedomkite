#!/usr/bin/perl -w

use strict;
use Sys::Syslog;
use Redis;
use CGI;

openlog('freedomkite', 'ndelay.pid', 'local1');

my $authdomain = "freedombox.me";
my $redis = Redis->new( server => 'localhost:6379' );
my $cgi = CGI->new;

$|=1;
my $code = $cgi->param('code');
my $domain = $cgi->param('domain');

if ($ENV{'REQUEST_METHOD'} eq "GET") {

	if (defined $code) {

		my $existingdomain = $redis->get('pagekite-code-' . $code);

		if (defined $existingdomain) {

			print $cgi->header(-status=>'200','Access-Control-Allow-Origin'=>'*',-type=>'application/json');
			$existingdomain = ($existingdomain eq '') ? 'null' : "\"$existingdomain\"";
			print "{\"domain\":$existingdomain}";
		} else {

			print $cgi->header(-status=>'200','Access-Control-Allow-Origin'=>'*',-type=>'application/json');
			print "{}";
		}
	} elsif (defined $domain) {

		my $existingcode = $redis->get('pagekite-domain-' . $domain);

		if (defined $existingcode) {

			print $cgi->header(-status=>'200','Access-Control-Allow-Origin'=>'*',-type=>'application/json');
			print "{\"domain\":\"$domain\"}";
		} else {

			print $cgi->header(-status=>'200','Access-Control-Allow-Origin'=>'*',-type=>'application/json');
			print "{\"domain\":null}";
		}
	}
} elsif ($ENV{'REQUEST_METHOD'} eq "POST") {

	if ((defined $code) && (defined $domain)) {

		$redis->set('pagekite-code-' . $code, $domain);
		$redis->set('pagekite-domain-' . $domain, $code);

		print $cgi->header(-status=>'200 OK','Access-Control-Allow-Origin'=>'*');
		print '200 OK';
		exit;
	} else {

		print $cgi->header(-status=>'400 Missing parameter(s)','Access-Control-Allow-Origin'=>'*');
		print '400 Missing parameters(s)';
		exit;
	}
}

