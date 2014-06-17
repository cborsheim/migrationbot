package cPmigbot::Account;
use base qw(cPmigbot_Super Common);

use strict;
use warnings;

#use CGI::Application::Plugin::Redirect;
#use Carp::Assert;


sub setup {
   my $self = shift;
   $self->start_mode('logout');
   $self->mode_param('do');
   $self->run_modes(
      'logout'    => 'logout',
   );
}



sub logout {
	my $self = shift;
	$self->authen->logout();
	return $self->redirect('/');
}

1;
