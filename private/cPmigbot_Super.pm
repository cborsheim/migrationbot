package cPmigbot_Super;

use strict;
use warnings;
use base 'CGI::Application';
use CGI::Application::Plugin::Config::Simple;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Authentication;
use CGI::Application::Plugin::Authorization;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use HTML::Template;
use HTTP::Request::Common qw(POST);  
use LWP::UserAgent; 
use JSON;
use MIME::Base64;
use Data::Dumper;
use HTTP::Cookies;
use WWW::Selenium;
use Selenium::Remote::Driver;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;



#--- Start CGI::APP 
sub cgiapp_init {
	my $self = shift;
	
	#--- Set Paths
	$self->config_file( '../private/conf/MigrationBot.conf');

	$self->tmpl_path( $self->config_param('general.templates') );

	#--- Session
	$self->session_config( DEFAULT_EXPIRY => '+24h');

	#--- Contact to DB
	$self->dbh_config( $self->config_param('db.host'),
		$self->config_param('db.user'),
		$self->config_param('db.pass'),
		{RaiseError => 1}
	);

	#--- Set up user access
	$self->authen->config(
		DRIVER => [ 'DBI',
		DBH         => $self->dbh,
		TABLE       => 'users',
		CONSTRAINTS => {
			'users.username' => '__CREDENTIAL_1__',
			'MD5:users.password' => '__CREDENTIAL_2__'
			},
		],
	);
        
	#LDAP example for manage2 single sign-in
	#DRIVER => [ 'Authen::Simple::LDAP',
	#host   => 'ldap.company.com',
	#basedn => 'ou=People,dc=company,dc=net'
        
        
	# Allow for some specific functions not to require auth
	$self->authen->protected_runmodes(qr/^(?!public_)/);
	return;
}



sub processtmpl{
	my $self = shift ;

	# processes the template with parameters gathered from the application object
	my %options =  @_;
	my $template = $self->load_tmpl($options{'TMPL'}, loop_context_vars => 1, die_on_bad_params => 0);
        
	# Sets the TMPL Vars from the parent function
	foreach my $key ( keys %options )
	{
		$template->param($key => $options{$key});
	}
	# Go go Render!
	#
	return $template->output;
}
1;
