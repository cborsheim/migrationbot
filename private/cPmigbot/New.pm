package cPmigbot::New;
use base qw(cPmigbot_Super Common cPMech);

use strict;
use warnings;
use CGI::Application;
use Switch;
use Data::Dumper;


#--- SETUP Run modes

sub setup {
   my $self = shift;
   $self->start_mode('display_form');
   $self->mode_param('do');
   $self->run_modes(
      'display_form'  => 'display_form',
      'confirm'       => 'confirm',
      'create'        => 'create',
   );
}

# Main New ticket Form 
sub display_form {
	my $self = shift;
	my %tmpl_options = (
		TMPL => 'New-display_form.tmpl',
	);
	return $self->processtmpl(%tmpl_options);
}

# Confirmation page
sub confirm {
	my $self = shift;
	#Create an array for the loop of 
	my @warn = ( );

	my $ticketid = $self->query->param('ticketid');

	if ( $ticketid !~ /[0-9]+/ ) {
		die "Invalid data inputed for ticket number";
	}
	
	# Verify that ticket is new and does not already exist.
	my $verify_sql = "SELECT `ticket_id`  FROM `tickets` WHERE `ticket_id` = '$ticketid' LIMIT 1";
	my $verify_check = $self->dbh->selectrow_array($verify_sql);
	
	if ( $verify_check ) {
		die "   ticket $ticketid allready exists in the database    ";
	}

	my %ticket = $self->get_server_details($ticketid);
	$ticket{'xfer_id'} = $self->query->param('xfer_id');

	my @servers = ();
	for ( my $i=0; $i<=9; $i++ ){
	    my %row_data;      # get a fresh hash for the row data
		if ($ticket{'auth'}{$i}{'ssh_ip'}){
			$row_data{IP} = $ticket{'auth'}{$i}{'ssh_ip'};
			$row_data{NUMBER} =$i;
			push(@servers, \%row_data);
		}
	}
	
	
	# Set up the hash to send back to the processtmpl function
	# Values here will be sent back to the template
	my %tmpl_options = (
		TMPL => 'New-confirm.tmpl',
		TICKET_SUBJECT => $ticket{'subject'},
		TICKET_ID => $ticket{'id'},
		STATUS => $ticket{'status'},
		TICKET_SERVER => $ticket{'tix_srv'},
		XFER_ID => $ticket{'xfer_id'},
		AUTH => Dumper($ticket{'auth'}),
		SERVERS => \@servers,
		WARN => \@warn,
	);
	
	# Push the closed ticket waring to the templatre system
	# ToDo, convert this function to an more robust and dynamic warning system 
	if ( $ticket{'status'} == 'closed' ) {
		$tmpl_options{'closed'} = 1 ;
	}
	
#	if ( $warn ) {
#		$tmpl_options{'warn'} = $warn;
#	}
	#Process the template with the returned data. 
	return $self->processtmpl(%tmpl_options);
}



sub create {
	my $self = shift;
	my %sql;
	
	# Set the ticket number 
	my $ticketid = $self->query->param('ticketid');
	
	if ( $ticketid !~ /[0-9]+/ ) {
		die "Invalid data inputed for ticket number";
	}
	$sql{'ticket_id'} = $ticketid;

	my %ticket = $self->get_server_details($ticketid);
	
	if ($self->query->param('xfer_id')){
		$sql{'xfer_id'} = $self->query->param('xfer_id');
	}else{ 
		die "Transfer ID not provided";
	}
		
	if ($self->query->param('src_server') =~ m/[0-9]/  && $self->query->param('dest_server') =~ m/[0-9]/ ){
		$sql{'src'} = $self->query->param('src_server');
		$sql{'dest'} = $self->query->param('dest_server');
	}
	$sql{'subject'} = $ticket{'subject'};
	$sql{'status'} = "pending";

	$self->record_ticket(\%sql);

	my $raw = 'hi';

	my %tmpl_options = (
		TMPL => 'raw.tmpl',
		RAW => $raw,
	);
	return $self->processtmpl(%tmpl_options);
}




#
# Support Functions
#

sub record_ticket{
	my $self = shift;
        my $sql  = shift;
        my %sql  = %{ $sql };
        #we use CAP::DBH to connect to the DB and execute our SQL statement
        my $stmt = 'INSERT INTO tickets (' . join(',', keys %sql) . ')
              VALUES (' . join(',', ('?') x keys %sql) . ')';
        $self->dbh->do($stmt, undef, values %sql);
        return;
}


1;
