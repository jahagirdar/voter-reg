use WWW::Mechanize::Firefox;
use strict;

  my $mech = WWW::Mechanize::Firefox->new(      activate => 1);
  $mech->autoclose_tab( 0 );
    $mech->events( ['load'] );
  $mech->get('file:///home/compilers/test/smartVote/bin/a.html');
  
  sleep 1;

  #$mech->eval_in_page("alert = function(val){console.log(val+' (alert disabled)');};");
  #$mech->eval_in_page("alert = function(val){console.log(val+' (alert disabled)');};");
  #$mech->eval_in_page('alert("Hello");', { alert => sub { print "Captured alert: '@_'\n" } });
   $mech->eval_in_page('', { alert => sub { print "Captured alert: '@_'\n" } });

print ("Triggering Alert");
	       $mech->click({xpath => '//*[@id="btnSignUp"]'});
