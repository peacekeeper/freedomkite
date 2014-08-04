#!/usr/bin/perl -w

use strict;
use Sys::Syslog;
use Data::GUID;
use Redis;
use CGI;

openlog('freedomkite', 'ndelay.pid', 'local1');

my $redis = Redis->new( server => 'localhost:6379' );
my $cgi = CGI->new;

$|=1;

my $code = substr(Data::GUID->new, 0, 13);

$redis->set('pagekite-code-' . $code, '');

print $cgi->header(-status=>'200',-type=>'text/plain');
print "code: $code";

