voter-reg
=========

Bulk Voter registeration application

This is a web app using the perl Dancer Framework.
To use this you need to latest version of perl (5.14)
The following CPAN modules are required for the application to work.
 Dancer, Dancer::Plugin::Database, CGI::FormBuilder, Data::Dump Spreadsheet:XLSX, Text::Iconv
 
Usage:
======
run smartVote/bin/app.pl

This will start a webserver on localhost:3000

The URL's supported are

localhost:3000/newdb            | This will create a new database instance

localhost:3000                  | This will bringup a form to enter the common data once this is submitted the page redirects to 

localhost:3000/rwa              | where you can upload the excel sheet received from RWA (Sample format at smartvote/voter.xlsx )

This will parse the excel sheet and display the contents of all rows in a single page.

localhost:3000/voter/           | List of all voters in the database

localhost:3000/voter/edit/<id>  | Edit voter details

localhost:3000/voter/print/<id> | Voter details in printable format

Currently data validation checks are not present these may throwup 500 script violation for undefined values. in case you want to avoid it
run app.pl with the option --environment=production