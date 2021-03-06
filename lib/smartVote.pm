package smartVote;
#Author Vijayvithal
use Dancer ':syntax';
use Data::Dumper;
	use Time::Piece;
	use Time::Seconds;

our $VERSION = '0.1';
use Dancer::Plugin::Database;
use CGI::FormBuilder;
hook 'database_error'=>sub{
	my $msg=shift;
	debug $msg;
};
get '/excel_format' => sub {
	           use Spreadsheet::WriteExcel;
		   my $app_dir = Dancer::FileUtils::path(setting('appdir'), 'public');
		   my $filename=$app_dir.'voter_format.xls';
		   my $workbook = Spreadsheet::WriteExcel->new($filename);
		   my $db=database('new');

		   #Add a worksheet
		   my $worksheet = $workbook->add_worksheet();
		   # Write a formatted and unformatted string, row and column notation.
		   my $candidate=$db->quick_select('details',{});
		   my @fields=keys %$candidate;
		   debug @fields;
		   my $col;my $row;
		   $col = $row = 0;
		   foreach my $c (0 ..  $#fields) {
			   $worksheet->write($row, $c, $fields[$c]);
			   debug $fields[$c];
		   }
		   $workbook->close();
		   return send_file ($filename,system_path=>1);
	   };

get '/newdb' => sub{
	my $time=localtime;
	#if ( -e 'voters.sqlite'){ `mv voters.sqlite voters.sqlite.$time`;`touch voters.sqlite`;}
		   my $db=database('new');
	my $sth=$db->prepare('drop table if exists [details]');
	$sth->execute();
	my $sth=$db->prepare('CREATE TABLE [details] ( 
		[id] INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
		[Name] TEXT  NULL,
	       	[Middle_Name] TEXT  NULL, 
		[Family_Name] TEXT  NULL,
		[DOB] DATE  NULL,
		[Birth_Town] TEXT  NULL,
		[Birth_District] TEXT  NULL,
		[Birth_State] TEXT  NULL,
		[Relation_Type] TEXT NULL,
		[Relation_Name] TEXT NULL,
		[Relation_Sirname] TEXT NULL,
		[Door_number] TEXT NULL,
		[Apartment_Name] TEXT NULL,
		[Street] TEXT NULL,
		[Town] TEXT NULL,
		[Post_office] TEXT  NULL,
		[Taluka] TEXT  NULL,
		[District] TEXT  NULL,
		[Pincode] TEXT NULL,
		[Assembly_Constituency] TEXT  NULL,
		[Sex] TEXT  NULL,
		[FormType] TEXT  NULL,
		[PreviousIDNumber] TEXT  NULL,
		[email] TEXT  NULL,
		[phone] TEXT  NULL,
		[verified] Boolean  NULL
		)') or debug $?;
	debug Dumper($sth);
	$sth->execute();
	return template 'index';

};
get '/' =>sub {
	return template 'index.tt';
};
get '/rwa/add' => sub {
	my $prefix_setting = Dancer::App->current->prefix || '';
	my $actionurl=$prefix_setting.'';
	my $defaultValues;
	my $form=CGI::FormBuilder->new(
		title=>'Association details',
		fields=>[qw(Assembly_Constituency Apartment_Name Street Town Post_office Taluka District Pincode)],
		validate=>{Pincode=>'/^\d{6}/'},
		required=>[qw(Assembly_Constituency Apartment_Name Street Town Post_office Taluka District Pincode)],
		action =>$actionurl,
);
	if ($form->submitted && $form->validate) {
		my $hshref=$form->field;
		session $form->title => $hshref;
		redirect '/rwa/';
	}
	my $template_engine = engine 'template';
	$template_engine->apply_layout($form->render);
};
get '/rwa/' =>sub{
	my $prefix_setting = Dancer::App->current->prefix || '';
	my $actionurl=$prefix_setting.'';
	my $form = CGI::FormBuilder->new(
		enctype => 'multipart/form-data',
		method  => 'POST',
		action =>$actionurl,
		fields  => [qw(filename)]
	);

	$form->field(name => 'filename', type => 'file');

	my $template_engine = engine 'template';
	$template_engine->apply_layout($form->render);
};
post '/rwa/'=>sub {
	debug "File Upload";
	my $file = upload('filename');

		   my $db=database('new');
	use Text::Iconv;
	my $converter = Text::Iconv -> new ("utf-8", "windows-1251");

	# Text::Iconv is not really required.
	# This can be any object with the convert method. Or nothing.

	use Spreadsheet::ParseExcel;
	my $commonData=session 'Association details';
	debug Dumper($commonData);

	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($file->tempname);

	if ( !defined $workbook ) {
		die $parser->error(), ".\n";
	}

	for my $worksheet ( $workbook->worksheets() ) {

		my ( $row_min, $row_max ) = $worksheet->row_range();
		my ( $col_min, $col_max ) = $worksheet->col_range();

			my @fields=qw(Name Family_Name Relation_Name Relation_Sirname Relation_Type DOB Sex Birth_State Birth_Town Birth_District Door_number PreviousIDNumber FormType email phone);
		for my $row ( $row_min .. $row_max ) {
			debug 'ROW';
			my $candidate={};
			for my $col ( $col_min .. $col_max ) {

				my $cell = $worksheet->get_cell( $row, $col );
				if(!$cell){
					$candidate->{$fields[$col]}= 'NIL';
					next;
				};

				$candidate->{$fields[$col]}= $cell->value();
				debug "Row, Col    = ($row, $col)\n";
				debug "Value       = ", $cell->value(),       "\n";
				debug "Unformatted = ", $cell->unformatted(), "\n";
				debug "\n";
			}
			foreach (qw(Apartment_Name Street Town Post_office Taluka District Pincode Assembly_Constituency))
			{
				$candidate->{$_}=$commonData->{$_};
				debug "undef $_" unless ($commonData->{$_});}
			foreach (@fields)
			{debug "undef $_" unless ($candidate->{$_});
			}
			$candidate->{'Assembly_Constituency'}        = $commonData->{Assembly_Constituency};
			debug Dumper ($candidate);
			$db->quick_insert('details',$candidate);
		}
	}

	my @candidates=$db->quick_select('details',{},[qw(id Name Middle_Name Family_Name)]);
	
	return template 'candidate_list' ,{cfg=>\@candidates };
	##############################################
};
get '/voter/' =>sub{
		   my $db=database('new');
	my @candidates=$db->quick_select('details',{},[qw(id Name Middle_Name Family_Name)]);
	return template 'candidate_list' ,{cfg=>\@candidates };

};
post '/voter/edit/:mode'=>sub {
	debug params;
	my $db=database('new');
	debug "got db";
	my$f=params->{'id'};
	debug "setting $f";
	if (map {$f eq $_} qw(year month day)){
	my $candidate=$db->quick_select('details',{id=>params->{mode}});
	debug "candidate $candidate";
	   my ($yy,$mm,$dd)=split '-',$candidate->{'DOB'};
	   $yy='01' if ($yy eq '');
	   $mm='01' if ($mm eq '');
	   $dd='01' if ($dd eq '');

	   $yy=params->{value} if ($f eq 'year');
	   $mm=params->{value} if ($f eq 'month');
	   $dd=params->{value} if ($f eq 'day');
	my $now=localtime;
	 my $t = Time::Piece->strptime("$yy-$mm-$dd", "%F");
	 my $sec=$now-$t;
	debug "IN Age Check:";
	 if($sec->years<18 || $sec->years >120){return "Error age should be between 18 to 120 years you entered ". $sec->years. " Years";}
	$db->quick_update('details',{id=>params->{mode}},{DOB=>"$yy-$mm-$dd"});
}else{

	debug "IN Else:";
	$db->quick_update('details',{id=>params->{mode}},{params->{id}=>params->{value}});
}
	return params->{value};
};
get '/voter/validate/:id' => sub{
	my $where;
	if (params->{id} eq 'all') {$where={};}else {$where={id=>params->{id};}}
	my @voters=$db->quick_select('details',$where);
	foreach my $voter (@voters){
		$voter->{verified}='false' unless (
			$voter->{Name} ~=/^[a-zA-Z]{3,}/ && 
			$voter->{DOB} ~=/^\d{4}-\d{2}-\d{2}/ &&
			$voter->{phone} ~=/^\d{10,}/ &&
			$voter->{email} ~=/^.+@.+\..+/ &&
		);
	}
	return template 'candidate_list';
};

get '/voter/new/:id' =>sub{
		   my $db=database('new');
		   my $flds=$db->quick_select('details',{id=>params->{id}});
		delete $flds->{'id'};
		$flds->{'Name'}.=int rand(10000);
		$db->quick_insert('details',$flds);
		redirect '/voter/print/'.$db->quick_lookup('details',{Name=>$flds->{'Name'}},'id');
};
get '/voter/:mode/:id'=>sub {
		   my $db=database('new');
	if (params->{mode} eq 'print'){
	my $candidate=$db->quick_select('details',{id=>params->{id}});
	debug $candidate;
	my $time={yy=>'2012',mm=>'01',dd=>'01'};
	if ($candidate->{'DOB'} =~ /\d\d\d\d.\d\d.\d\d/ ){
	 my $t = Time::Piece->strptime($candidate->{'DOB'}, "%F");
	 my $now = Time::Piece->strptime("2012-01-01", "%F");
	 my $sec=$now-$t;
	 $time->{years}=int $sec->years;
	  $sec=$sec-(ONE_YEAR *$time->{years});
	   $time->{months}=int $sec->months;
	   my ($yy,$mm,$dd)=split '-',$candidate->{'DOB'};
	   $time->{yy}=$yy;
	   $time->{mm}=$mm;
	   $time->{dd}=$dd;
   }

	return template 'form6' ,{cfg=>[$candidate],sec=>$time},{layout=>0};
	}

	my $prefix_setting = Dancer::App->current->prefix || '';
	my $actionurl=$prefix_setting.'';
		my $candidate=$db->quick_select('details',{id=>params->{id}});
		my @fields=keys %$candidate;
@fields= qw(id Name Middle_Name Family_Name DOB Birth_Town Birth_District Birth_State Relation_Type Relation_Name Relation_Sirname Door_number Apartment_Name Street Town Post_office Taluka District Pincode Assembly_Constituency Sex FormType PreviousIDNumber email phone);


		if( $candidate->{Verified}){
			$candidate->{Verified}='checked';
		}else{
			$candidate->{Verified}='No';
		}
		my$form=CGI::FormBuilder->new(
			fields=>[@fields],
			title=>"Edit Records for ".$candidate->{'Name'},
			method=>'GET',
			action =>$actionurl,
			values=>$candidate#,
			#jshead=>'$("#PreviousIDNumber").autocomplete({ url: "/voter/find/", minChars: 3});',
			#template => {
			#	type => 'TT2',
			#	template => 'form.tpl',
			#	variable => 'form'
			#}
		);
	$form->field(name=>'Verified',type=>'checkbox',options=>[qw(Yes)],checked=>$candidate->{Verified});
	if ($form->submitted && $form->validate) {
		#debug params->{Verified};
		my$flds=$form->fields;
		if( params->{Verified}){
			$flds->{Verified}=1;
		}else{
			$flds->{Verified}=0;
		}
	if(params->{mode} eq 'new'){
		delete $flds->{'id'};
		$flds->{'Name'}.=int rand(10000);
		$db->quick_insert('details',$flds);
		redirect '/voter/print/'.$db->quick_lookup('details',{Name=>$flds->{'Name'}},'id');
	}elsif(params->{mode} eq 'edit') {
		$db->quick_update('details',{id=>params->{id}},$flds);
	}
		redirect '/voter/';
	}

	my $template_engine = engine 'template';
	$template_engine->apply_layout($form->render);
};
use Dancer::Plugin::Ajax;
get '/voter/find'=>sub{
	return send_file '/javascripts/autocomplete/demo/index.html';
};
ajax '/voter/find'=>sub{
		   my $db=database('existing');
		   debug Dumper(params->{'q'});
		   my @user=$db->quick_select('registered_voters',{Voter_Name=>{like=>'%'.params->{'q'}.'%'}},{limit=>10});
	debug "Ajax Called". to_json(\@user);
	return  to_json(\@user);
};
#Route to cleanup tmp area
get '/listtmp' =>sub {
	my @list=glob ("/tmp/*.xls");
	debug @list;
	foreach my$file (@list){
		`rm $file`;
	}
	my @list=glob ("/tmp/*.xls");
	my $pwd=`pwd`;
	my $ls=`ls`;
	my $PAT={pwd=>$pwd,
	ls=>$ls
};
	debug $PAT;
	my $views_dir = Dancer::FileUtils::path(setting('appdir'), 'views');
       debug "setting appdir". $views_dir ;
	return template 'index',{ENV=>$PAT};
};
true;
