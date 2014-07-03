package Bugzilla::Extension::BugLocalizer::WebService::Repository;

use strict;
use warnings;
use base qw(Bugzilla::WebService);
use Bugzilla::Constants;
use Bugzilla::Error;


sub getFileList {
    my ($self, $params) = @_;
    my @results;
    $params->{product} =~ m|([A-Za-z0-9]+)|;
    my $product = $1;
    $params->{git_revision} =~ m|([A-Za-z0-9._]+)|;
    my $git_revision = $1;
    $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin:';
    chdir 'extensions/BugLocalizer/repository/'.$product;
    if ($git_revision eq 'Latest Commit'){
        $git_revision = 'HEAD';
    }
    my $stdout = `git diff --name-only $git_revision^ $git_revision`;
    my @filelist = split('\s+',$stdout);
    my @filteredList = sort grep(/\.java$/,@filelist);
    chdir '/var/www/bugzilla-4.4.4/';
    return {filelist => \@filteredList};
}

1;
