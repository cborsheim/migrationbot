#!/usr/bin/perl 

use lib "../private/";
use warnings;
use strict;
use cPmigbot::New;

my $app = cPmigbot::New->new( PARAM => 'client' );
$app->run();
