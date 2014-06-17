package Common;


sub get_tixdb_status {
	my $self=shift;
	my $ticket= $_[0];
	
	my $statment = "select `status` from `tickets` where `ticket_id` = $ticket LIMIT 1";
	my $status = $self->dbh->selectrow_array($statment);
	
	return $status;
}


sub save_tixdb_status {
	my $self=shift;

	# We need to pass off the server information to this function 	
	# Argument 1 is the server's IP address
	# Argument 2 is the user, ie root
	# Argument 3 is the server password. 
	# Argument 4 is the ticket id 
	
	my $ip      = $_[0];
	my $user    = $_[1];
	my $pass    = $_[2];
	my $xfer_id = $_[3];
	my $tiket   = $_[4];

	# Now were ready to get the sate of the stats of the transfer
	my $state = $self->cPxfer_get_state(
		$ip,
		$user,
		$pass,
		$xfer_id);

	my $statment = "UPDATE tickets SET `status` = '$state' where `ticket_id` = 4804479";
	$self->dbh->do($statment);
		
	return;
}

# Ensure a true value is returned
1;
