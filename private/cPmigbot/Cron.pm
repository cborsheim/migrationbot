package cPmigbot::Cron;
use base qw(cPmigbot_Super Common cPMech cPxfer);
use strict;

#--- SETUP Run modes

sub setup {
   my $self = shift;
   $self->start_mode('automatic_mode');
   $self->mode_param('do');
   $self->run_modes(
      'automatic_mode'  => 'public_automatic_mode',
      'process_pending' => 'process_pending',
   );
}

sub public_automatic_mode{
	my $self = shift;
	
	#Process the Pending tickets
	$self->process_pending();
	return;
}



# Function: process_pending
#
# Description: Kicks off processing of pending servers
#
# Usage: 
# Returns: 

#
# This function may be to be updated to include in the mysql select
# in progress and other ticket statues that need updating. 

sub process_pending{
	my $self = shift;
	my $pending_results;
	
	# Detect specific ticket number to process
	if ( $_[0] ){
		our $ticket = $_[0];
		my $pending_sql = "SELECT * FROM `tickets` WHERE  `ticket_id`=$ticket;";
		$pending_results = $self->dbh->selectall_hashref($pending_sql, "ticket_id" );
	}else{
		# Fetch the pending tickets	
		my $pending_sql = "SELECT * FROM  `tickets` WHERE  `status`='pending';";
		$pending_results = $self->dbh->selectall_hashref($pending_sql, "ticket_id" );
	}

	# Loop Though all of the pending tickets.
	for my $id (keys %$pending_results){
	
		# Send each ticket number found to the process server function. 
		my $xfer_id = $pending_results->{$id}->{'xfer_id'};
		my $dest_srv = $pending_results->{$id}->{'dest'};
		my $ticketid = $pending_results->{$id}->{'ticket_id'};


		
		
		$self->process_server($ticketid, $dest_srv, $xfer_id);
	}
	return;
}

# Function: process_server
#
# Description: This function process the server, gets the state from the server and database, updating them as needed
#
# Usage: process_server($ticketid, $dest_srv, $xfer_id)
# Returns: TBD
sub process_server {
	my $self = shift;
	
	# Inherit the function's arguments 
	my ($ticketid, $dest_srv, $xfer_id) = @_;

	# Verify all required options are meet
	if (! $ticketid || ! $dest_srv || ! $xfer_id ) {
		die "process_server did not receave correct input data\nTIX: $ticketid Dest_ser: $dest_srv XFER_ID: $xfer_id \n";
	}
	
	# Populate this hash with the server auth details from the ticket system
	my %ticket_auth = $self->get_server_details($ticketid);
	my $ticket_auth = \%ticket_auth;
	
	# Lets find the destination server 
	my $destnation = $dest_srv;

	# If theres an wheal user, lets use that, however if theres no wheel user
	# lets default to root
	my $user;
	if ( $ticket_auth{$destnation}{'wheel_user'}){
		$user =  $ticket_auth{$destnation}{'wheel_user'};
	}else{
		$user = 'root';
	}

	# Now were ready to get the sate of the stats of the transfer
	#                                             from the server
	my $state = $self->cPxfer_get_state(
		$ticket_auth{'auth'}{$destnation}{'ssh_ip'},
		$user,
		$ticket_auth{'auth'}{$destnation}{'root_pass'},
		$xfer_id);




	
	
	# Here we detect if the state has changed.
	if ( $state ne $ticket_auth{'db_status'} ) {
	
		
		
		# This section has been moved to update_based_on_status
		$self->update_based_on_status($ticketid, $ticket_auth{'db_status'}, $state);
		
		
		
	
		#Save new state
		$self->save_tixdb_status(
			$ticket_auth{'auth'}{$destnation}{'ssh_ip'},
			$user,
			$ticket_auth{'auth'}{$destnation}{'root_pass'},
			$xfer_id,
			$ticketid);
	}else{
		# State is the same.
		# Need last update check so every X hours we can send an update regardless 
		# of the status
		die "Incomplete section of code encountered";
	}
	
	return;
}



# Function: update_based_on_status
#
# Description: This function updates the client based on a set of rules
#
# Usage: updaet_based_on_status($ticketid, $dbstatus, $newstatus)
# Returns: TBD
sub update_based_on_status {
	my $self = shift;
	my ($ticketid, $dbstatus, $newstatus) = @_;

	# It appears the state has changed, update client
	# Because case and switch appeared to have issues
	# were doing sequential if statements
	
	
	# It should be noted I dislike sequential if statements
	# Maybe abstract this into it's own function
	
	# Also we need to update the templates to use Text::Template
		
	if ($newstatus = "COMPLETED" ) {
		$self->update_ticket($ticketid, "COMPLETED PREDEFINED");
		$self->set_emg($ticketid);
	}
	
	#STATUS RUNNING
	
	if ($newstatus = "Access denied" ) {
		$self->update_ticket($ticketid, "Access denied PREDEFINED");
		$self->set_emg($ticketid);
	}
	
	
	# END SEQUENCIAL IF STATEMENTS 
	return;
}





# Ensure an exit code, or else the mosters come to visit.
1;
