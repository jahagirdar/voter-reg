use Dancer::Plugin::Database;
use DBI;
my $dbfile='existing_voters.sqlite';
         my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

	 my $sth=$dbh->prepare('CREATE TABLE [registered_voters](
		 [ACPart]       TEXT NULL,
		 [Section]      TEXT NULL,
		 [Status]       TEXT NULL,
		 [Serial]       TEXT NULL,
		 [House]        TEXT NULL,
		 [Voter_ID]     TEXT NULL,
		 [Voter_Name]   TEXT NULL,
		 [Sex]          TEXT NULL,
		 [Age]          TEXT NULL,
		 [Relative]     TEXT NULL,
		 [Relation]     TEXT NULL)
		 ');
	 $sth->execute();
$sth = $dbh->prepare("INSERT INTO registered_voters(ACPart, Section, Status, Serial, House, Voter_ID, Voter_Name, Sex, Age, Relative, Relation) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
  
         $rc  = $dbh->begin_work   or die $dbh->errstr;


while (<>){
	my (   $ACPart, #                the first 3 digits indicate the constituency and the last 3 the part number
		$Section,#                each section maps to an address
		$Status, #                Valid Voters: ‘O’ as in original, ‘A’ additions, ‘M’ modified. Deleted Voters: ‘S’ Shifted, ‘E’ Expired, ‘Q’ Disqualified, ‘R’ Repeated
		$Serial, #                  serial number in the voter list for the part
		$House,#
		$Voter_ID,#             valid format is 3 alphabets followed by 7 digits. I have inserted ‘xxxxxxxxxx’ for blank fields
		$Voter_Name,#
		$Sex,#                      ‘M’, ‘F’, and ‘O’
		$Age,                     
		$Relative,#             
		$Relation #             ‘M’ Mother, ‘F’ Father, ‘H’ Husband, and ‘O’ Other
	)=split "\t";

$sth->execute($ACPart, $Section, $Status, $Serial, $House, $Voter_ID, $Voter_Name, $Sex, $Age, $Relative, $Relation);

		 }
		 $dbh->commit;
