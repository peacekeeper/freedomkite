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

if (! defined $code) { print $cgi->header(-status=>'400 Missing code'); print '400 Missing code\n'; exit; };

my $existingdomain = $redis->get('pagekite-code-' . $code);

if (! defined $existingdomain) { print $cgi->header(-status=>'404 Not found'); print '404 Not found\n'; exit; };

if (defined $domain) {

	$redis->set('pagekite-code-' . $code, $domain);
	$redis->set('pagekite-domain-' . $domain, $code);
}

print $cgi->header(-status=>'200',-type=>'text/plain');
print $existingdomain;

