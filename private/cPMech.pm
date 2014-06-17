package cPMech;
use Data::Dumper;



sub set_emg {
	my $self = shift;
	
	# Get the ticket ID
	my $ticket_id = $_[0];
	
	# Build the Mech object 
	my ($mech, $tree) = $self->build_connection( $self->config_param('cPTKTS.ticket_uri') . "emg.cgi?" . $ticket_id );

	# Return	
	return 1;
}

sub set_noemg {
	my $self = shift;

	# Get the ticket ID
	my $ticket_id = $_[0];

	# Build the Mech object 
	my ($mech, $tree) = $self->build_connection( $self->config_param('cPTKTS.ticket_uri') . "noemg.cgi?" . $ticket_id );

	# Return	
	return 1;
}



sub update_ticket{
	my $self = shift;
	
	# Get the ticket ID as well as the reply
	my $ticket_id = $_[0];
	my $reply = $_[1];

	if (! $ticket || ! $reply) {
		die "update_ticket called for '$ticket' with reply '$reply', but was missing values";
	}

	# Build the tree
	my ($mech, $tree) = $self->build_connection( $self->config_param('cPTKTS.ticket_uri') . $self->config_param('cPTKTS.ticket_reply_script') );

	# Get the server information and more importantly the csrf_token
	my %ticket = $self->get_server_details($ticket_id);
	
	# Create the hash to for the post 
	my %post = (subject => $ticket{'subject'},
		ticket_id => $ticket_id,
		response => $reply,
		signature_id => $self->config_param('cPTKTS.ticket_reply_signature_id'),
		leave_waiting_on_cpanel => $self->config_param('cPTKTS.ticket_leave_waiting_on_cpanel'),
		reassign => 'true',
		csrf_token => "$ticket{'csrf'}");
	
	# Submit the Post 
	my $post = $mech->post( $self->config_param('cPTKTS.ticket_uri') . $self->config_param('cPTKTS.ticket_reply_script'), \%post );


    #Check for success 
   	$json = JSON->new;
   	my $response = $json->decode($mech->content( decoded_by_headers => 1 ));
	
	if ( $response->{'error'} =! 0 ) {
		die "Failed to post reply  ". $mech->content( decoded_by_headers => 1 );
	}
	return;
}




# Function: get_server_details
#
# Description: Takes an ticket number and returns back ticket information. 
#
# Usage: $mech=$self->get_server_details($ticket_id);
# Returns: Hash with ticket information. 

sub get_server_details{
	my $self = shift;
	
	#Create the ticket hash where the ticket data will be stored
	my %ticket;
	
	#Set the ticket ID
	$ticket{'id'} = $_[0];
	
	# Build the tree
	my ($mech, $tree) = $self->build_connection( $self->config_param('cPTKTS.ticket_uri') . $self->config_param('cPTKTS.ticket_view_script') . $ticket{'id'} );

	# Fetch the Ticket Server
	$ticket{'tix_srv'} = $tree->findvalue( '//*[@id="session_details"]/span[2]' );
	$ticket{'tix_srv'} =~ s/Server\:\ //g;
	
	#Fetch the Ticket Subject
	$ticket{'subject'} = $tree->findvalue( '//*[@id="subject_display_top"]' );
	
	# Fetch the database status
	
	$ticket{'db_status'} = $self->get_tixdb_status($ticket{'id'});
	
	
	#Fetch the Ticket Status
	$ticket{'status'} = $tree->findvalue( '//span[@class="ticket_status_open" or @class="ticket_status_closed"]' );

	#Fetch the server information
	my @document = split /\n/, $mech->content( decoded_by_headers => 1 );
	
	#	#Create the JSON object to decode the jason server information 
	$json = JSON->new;
	
	# Loop through the document looking for the server information.
	foreach my $line (@document) {
		
		# Locate the html line with the auth data. 
		if ( $line =~ m/auth_data_from_template/ ) {

			# Remove the javascript leaving only the JSON Array
			$line =~ s/[ ]+var auth_data_from_template[ ]+=//;
			
			#Remove the trailing semicolon left over from the Javascript
			chop $line;
			
			# Parce the JSON into the Ticket hash to be returned.
			$ticket{'auth'} = $json->decode($line);
			
			# Get rid of the pesky cpwhm container 
			$ticket{'auth'} = $ticket{'auth'}{'cpwhm'};
		}
		
		# Locate the html line with the auth data. 
		if ( $line =~ m/csrf_token/ ) {

			# Remove the javascript leaving only the JSON Array
			$line =~ s/[ ]+var csrf_token[ ]+=//;
			
			# Remove the single ticks containing the token. 
			$line =~ s/\'//g;
						
			# Remove the trailing semicolon left over from the Javascript
			chop $line;
			
			# Ensure that theres no pesky spaces left in the token mucking up the works.
			$line =~ s/ //g;
			
			# Parce the JSON into the Ticket hash to be returned.
			$ticket{'csrf'} = $line;
		}	
	}
	return %ticket;
}



#
#  Below are the suport functions for Mech
#


# Function: mech_ensure_login
#
# Description: Takes an $mech object and ensures that we are logged in.
#
# Usage: $mech=$self->mech_ensure_login($mech);
# Returns: Mech Object
sub mech_ensure_login{
	my $self = shift;
	my $mech = $_[0];
	# Verify that we are loged in and if not log us in. 
	if ($mech->title() =~ /cPTKTS/){

		# Select the login Form
		$mech->form_id('login_form');
		# Set the login values
		$mech->set_visible($self->config_param('cPTKTS.user'), $self->config_param('cPTKTS.pass'));
		# Submit the form
		$mech->submit();
	}
	return $mech;
}



# Function: build_connection
#
# Description: Build an Mech and tree objects for an requested page
#
# Usage: my ($mech, $tree) = $self->build_connection( $self->config_param('cPTKTS.ticket_uri') . $self->config_param('cPTKTS.ticket_view_script') . $ticket{'number'} );
# Returns: ($mech, $tree)	

sub build_connection{
	my $self=shift;
	my $url = $_[0];
	
	# Set up cookies to resume the session
	my $cookie_jar = HTTP::Cookies->new(file => $self->config_param('mech.cookies'), autosave => 1, ignore_discard => 1);

	# Create the mech object
	my $mech = WWW::Mechanize->new(cookie_jar => $cookie_jar, autocheck => 0, requests_redirectable => [ 'GET', 'HEAD', 'POST' ]);

	# Use WWW-Mechanize-TreeBuilder to access the xpath of the DOM tree
	WWW::Mechanize::TreeBuilder->meta->apply($mech,
		tree_class => 'HTML::TreeBuilder::XPath',
	);

	# Request desired page
	$mech->get( $url );
	# Ensure that a login page was not returned, if so login, and after login the desired page will be loaded
	$mech = $self->mech_ensure_login($mech);

	# Create tree builder 	
	$tree=HTML::TreeBuilder::XPath->new();
	
	#Populate the tree with the page contents.
	$tree->parse($mech->content);

	#return tree
	return ($mech, $tree);
}


# Ensure a true value is returned
1;
