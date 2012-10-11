use WWW::Mechanize::Firefox;
use strict;
my @voters=(
	{	fn => 'James', ln => 'Bond', mob   => "9986854998", sex => 'M', ques => '1', ans => 'ak47', email => 'dt.siindia@gmail.com' },
	{	fn => 'Harry', ln => 'potter', mob => "9880123369", sex => 'M', ques => '1', ans => 'Anna', email => 'd.tsiindia@gmail.com' }
);
  my $mech = WWW::Mechanize::Firefox->new();
   $mech->autoclose_tab( 0 );
  foreach my $voter (@voters){
	  $mech->get('http://www.voterreg.kar.nic.in/Signup.aspx');
	  $mech->clear_current_form;
	  $mech->form_name( 'form1' );
	  print "You could click on\n";
	  for my $el ($mech->clickables) {
	          print $el->{innerHTML}, "\n";
	  };
	  print "\nmobile$voter->{mob}:";
	  $mech->field  ( txtMobile  => $voter->{mob}   ); 
	  print "\nsex";
	  $mech->select ( ddlSex     => $voter->{sex}   ); 
	  print "\nfn";
	  $mech->field  ( txtFstName => $voter->{fn}    ); 
	  $mech->field  ( txtLstName => $voter->{ln}    ); 
	  $mech->field  ( txtEmailID => $voter->{email} ); 
	  $mech->select ( ddlHidden  => $voter->{ques}  ); 
	  $mech->field  ( txtAnswer  => $voter->{ans}   ); 
	  print "about to click";
	  my $retries = 10;
	  while ($retries-- and ! $mech->is_visible( xpath => '//*[@id="btnSignUp"]' )) {
		  sleep 1;
	  };
	  die "Timeout" if 0 > $retries;

	  # Now the element exists
	       $mech->click({xpath => '//*[@id="btnSignUp"]'});
	       #$mech->click('btnSignUp');
	               print "Added account for $voter->{fn}" if $mech->success();
	  #$mech->submit;
	  print "Clicked";
	  sleep 10; #allow me to see the form results.
  }
