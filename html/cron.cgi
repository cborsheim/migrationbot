#!/usr/bin/perl 

use lib "../private/";
use warnings;
use strict;
use cPmigbot::Cron;

my $app = cPmigbot::Cron->new( PARAM => 'client' );
$app->run();
