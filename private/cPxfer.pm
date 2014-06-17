package cPxfer;
use strict;

sub cPxfer_get_state {
	my $self = shift;

	# We need to pass off the server information to this function 	
	# Argument 1 is the server's IP address
	# Argument 2 is the user, ie root
	# Argument 3 is the server password. 
	
	my ($ip, $user, $pass, $xfer_id) = @_;
	
	
	if (! $ip || ! $user || ! $pass || ! $xfer_id) {
		die "cPxfer_get_state did not receave correct input data\nIP: $ip USER: $user PASS: $pass XFER_ID: $xfer_id \n";
	}
	

	#Build an WWW:mech object and request the API
	my $mech = WWW::Mechanize->new(
		autocheck => 0,
		requests_redirectable => [ 'GET', 'HEAD', 'POST' ],
		ssl_opts => {
			SSL_verify_mode => 'IO::Socket::SSL::SSL_VERIFY_NONE',
			verify_hostname => 0,}
	);
	
	# Prepare API header for login
	my $auth = "Basic " . MIME::Base64::encode( $user . ":" . $pass );
	$mech->add_header(Authorization => $auth);
	
	#Make the Request
	$mech->get("https://$ip:2087/json-api/get_transfer_session_state?api.version=1&transfer_session_id=$xfer_id" );


	#Extract the status from the returned JSON
	my $json = JSON->new;
	my $response = $json->decode($mech->content( decoded_by_headers => 1 ));


	#Handle the errors in the return
	my $return;
	if ($response->{'cpanelresult'}->{'error'}){
		$return = $response->{'cpanelresult'}->{'error'};
	}else{
		$return = $response->{'data'}->{'state_name'};
	}
	return $return;
}

1;