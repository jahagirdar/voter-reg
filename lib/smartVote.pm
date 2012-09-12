package smartVote;
use Dancer ':syntax';
use Data::Dumper;

our $VERSION = '0.1';
use Dancer::Plugin::Database;
use CGI::FormBuilder;
hook 'database_error'=>sub{
	my $msg=shift;
	debug $msg;
};
get '/excel_format' => sub {
	           use Spreadsheet::WriteExcel;
		   my $filename='voter_format.xls';
		   my $workbook = Spreadsheet::WriteExcel->new($filename);
		   my $db=database('new');

		   #Add a worksheet
		   my $worksheet = $workbook->add_worksheet();
		   # Write a formatted and unformatted string, row and column notation.
		   my $candidate=$db->quick_select('details',{});
		   my @fields=keys %$candidate;
		   debug @fields;
		   my $col;my $row;
		   $col = $row = 1;
		   foreach my $c (1 .. scalar @fields) {
			   $worksheet->write($row, $c, $fields[$c]);
			   debug $fields[$c];
		   }
		   $workbook->close();
		   return send_file ('./'.$filename,system_path=>1);
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
	return "New Db Created";

};
get '/' => sub {
	my $prefix_setting = Dancer::App->current->prefix || '';
	my $actionurl=$prefix_setting.'';
	my $defaultValues;
	my $form=CGI::FormBuilder->new(
		title=>'Association details',
		fields=>[qw(Assembly_Constituency Apartment_Name Street Town Post_office Taluka District Pincode)],
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
		   my $db=database('new');
	debug "File Upload";
	my $file = upload('filename');
	$file->copy_to('rwa'.$file->filename);
	debug "File Upload Copied";

	use Text::Iconv;
	my $converter = Text::Iconv -> new ("utf-8", "windows-1251");

	# Text::Iconv is not really required.
	# This can be any object with the convert method. Or nothing.

	use Spreadsheet::ParseExcel;

	my $dir='';
	my $filename='rwa'.$file->filename;
	my $excel = Spreadsheet::ParseExcel -> new ($filename, $converter);

	debug $filename;
	my $commonData=session 'Association details';
	debug Dumper($commonData);

	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($filename);

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

	my $candidates=$db->quick_select('details',{},[qw(id Name Middle_Name Family_Name)]);
	return template 'candidate_list' ,{cfg=>$candidates };
	##############################################
};
get '/voter/' =>sub{
		   my $db=database('new');
	my @candidates=$db->quick_select('details',{},[qw(id Name Middle_Name Family_Name)]);
	return template 'candidate_list' ,{cfg=>\@candidates };

};
get '/voter/:mode/:id'=>sub {
		   my $db=database('new');
	if (params->{mode} eq 'print'){
	my $candidate=$db->quick_select('details',{id=>params->{id}});
	return template 'candidate' ,{cfg=>[$candidate]};
	}

	my $prefix_setting = Dancer::App->current->prefix || '';
	my $actionurl=$prefix_setting.'';
		my $candidate=$db->quick_select('details',{id=>params->{id}});
		my @fields=keys %$candidate;
		my$form=CGI::FormBuilder->new(
			fields=>[@fields],
			title=>"Edit Records for ".$candidate->{'Name'},
			method=>'GET',
			action =>$actionurl,
			values=>$candidate,
			jshead=>'$("#PreviousIDNumber").autocomplete({ url: "/voter/find/", minChars: 3});'
	);
	if ($form->submitted && $form->validate) {
		my$flds=$form->fields;
	if(params->{mode} eq 'new'){
		$db->quick_insert('details',$flds);
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

true;
