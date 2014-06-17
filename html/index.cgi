#!/usr/bin/perl 

use lib "../private/";
use warnings;
use strict;
use cPmigbot::Home;

my $app = cPmigbot::Home->new( PARAM => 'client' );
$app->run();
