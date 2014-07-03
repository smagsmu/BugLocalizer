package Bugzilla::Extension::BugLocalizer::WebService::BugLocalizer;

use strict;
use warnings;
use base qw(Bugzilla::WebService);
use Bugzilla::Constants;
use Bugzilla::Error;
use Cwd;
use XML::Writer;
use IO::File;

sub localize {
    my ($self, $params) = @_;
    my $dbh = Bugzilla->dbh;
    my @results;
    my $pwd = getcwd;
    $pwd =~ m|([^\0]+)|;
    $pwd = $1;
    $params->{bug_id} =~ m|([0-9]+)|;
    my $bug_id = $1;
    $params->{product} =~ m|([A-Za-z0-9]+)|;
    my $product = $1;
    $params->{git_tag_version} =~ m|([A-Za-z0-9._]+)|;
    my $git_tag = $1;
    $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin:';
    my $stdout = `git clone extensions/BugLocalizer/repository/$product extensions/BugLocalizer/repository/tmp/$product`;
    chdir 'extensions/BugLocalizer/repository/tmp/'.$product;
    if (not $git_tag eq 'Latest Commit'){
        my $stdout = `git checkout $git_tag`;
    }
    my $bug_infos = $dbh->selectall_arrayref(
        "SELECT bugs.bug_id AS bug_id, bugs.short_desc AS summary, 
		descriptions.thetext AS description, creation_ts AS opendate, delta_ts AS fixdate
	 FROM bugs  INNER JOIN 
	(SELECT * FROM bugs.longdescs ld1 WHERE bug_when = 
	(SELECT MIN(bug_when) FROM bugs.longdescs ld2 WHERE ld1.bug_id = ld2.bug_id))
	descriptions ON bugs.bug_id = descriptions.bug_id WHERE bugs.bug_id=$bug_id", {Slice=>{}});
    my $buginfo = $bug_infos->[0];
    my $output = IO::File->new(">$pwd/extensions/BugLocalizer/repository/tmp/bug_repository.xml");
    my $writer = XML::Writer->new(OUTPUT => $output);
    $writer->startTag("bugrepository", "name" => $product);
    $writer->startTag("bug", "id" => $bug_id, "opendate" => $buginfo->{opendate}, "fixdate" => $buginfo->{fixdate});
    $writer->startTag("buginformation");
    $writer->startTag("summary");
    $writer->characters($buginfo->{summary});
    $writer->endTag("summary");
    $writer->startTag("description");
    $writer->characters($buginfo->{description});
    $writer->endTag("description");
    $writer->endTag("buginformation");
    $writer->startTag("fixedFiles");
    $writer->startTag("file");
    $writer->characters("org.eclipse.swt.ole.win32.Variant.java");
    $writer->endTag("file");
    $writer->endTag("fixedFiles");
    $writer->endTag("bug");
    $writer->endTag("bugrepository");
    $writer->end();
    $output->close();

    chdir '..';
    my $stdout = `java -jar $pwd/extensions/BugLocalizer/app/FBL.jar -b $pwd/extensions/BugLocalizer/repository/tmp/bug_repository.xml -s $pwd/extensions/BugLocalizer/repository/tmp/TestProduct/ -a 0.2 -o $pwd/extensions/BugLocalizer/repository/tmp/output.txt`;
    chdir $pwd;
    open FILE, "$pwd/extensions/BugLocalizer/repository/tmp/output.txt" or die $!;
    while (<FILE>) {
        my @array = split(',',$_);
    	my %hash = (Rank => $self->type('int', @array[2]+1), Filename => $self->type('string', @array[1]),);
	push (@results, \%hash);
    }
    close(FILE);
    my $stdout = `rm -r $pwd/extensions/BugLocalizer/repository/tmp/TestProduct/`;
    my @topResults = @results[0..9];
    return {ranks => \@topResults};
}

1;
