package cPmigbot::Home;
use base qw(cPmigbot_Super Common);

use strict;
use warnings;
use CGI::Application;
use Data::Dumper;

#--- SETUP Run modes

sub setup {
   my $self = shift;
   $self->start_mode('home');
   $self->mode_param('do');
   $self->run_modes(
      'home'    => 'home_page',
   );
}


sub home_page{
	my $self = shift;

	# Fetch the pending tickets	
	my $pending_sql = "SELECT * FROM  `tickets` WHERE  `status` ='pending'";
	my $pending_results = $self->dbh->selectall_hashref($pending_sql, "ticket_id" );

	#Create the pending loop 
	my @pending_loop = ( );
	
	for my $ticket (keys %$pending_results){
		my %ticket_data;
		$ticket_data{'TICKET_ID'} = $pending_results->{$ticket}->{'ticket_id'};
		$ticket_data{'TICKET_SUBJECT'} = $pending_results->{$ticket}->{'subject'};
		push(@pending_loop, \%ticket_data)
	}

	#Prep content for render 
	my %tmpl_options = (
		TMPL => 'home.tmpl',
		TITLE => "cPmigbot Central",
		PENDING => \@pending_loop,
	);
	return $self->processtmpl(%tmpl_options);
}
1;
