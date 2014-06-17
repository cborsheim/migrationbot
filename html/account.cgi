#!/usr/bin/perl 

use lib "../private/";
use warnings;
use strict;
use cPmigbot::Account;

my $app = cPmigbot::Account->new( PARAM => 'client' );
$app->run();
