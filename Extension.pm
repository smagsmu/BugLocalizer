# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::BugLocalizer;
use strict;
use base qw(Bugzilla::Extension);
use Cwd;

our $VERSION = '1.0';

sub db_schema_abstract_schema {
    my ($self, $args) = @_;
    $args->{'schema'}->{'fixed_files'} = {
        FIELDS => [
            bug_id     => {TYPE => 'INT3', NOTNULL => 1,
                           REFERENCES  => {TABLE  =>  'bugs',
                                           COLUMN =>  'bug_id',
                                           DELETE => 'CASCADE'}},
            git_revision     => {TYPE => 'TEXT', NOTNULL => 1},
            filename => {TYPE => 'TEXT', NOTNULL => 1},
        ],
        INDEXES => [
            fixed_files_bug_id_idx    => ['bug_id'],
        ],
    };
    $args->{'schema'}->{'git_info'} = {
        FIELDS => [
            git_id     => {TYPE => 'INT3', NOTNULL => 1,
                           REFERENCES  => {TABLE  =>  'products',
                                           COLUMN =>  'id',
                                           DELETE => 'CASCADE'}},
            repository_url     => {TYPE => 'TEXT', NOTNULL => 1},
	    public     => {TYPE => 'BOOLEAN', NOTNULL => 1},
	    username     => {TYPE => 'TEXT'},
	    password     => {TYPE => 'TEXT'},
        ],
        INDEXES => [
            git_id_idx    => ['git_id'],
        ],
    };
}

sub template_before_process {
    my ($self, $args) = @_;
    my ($vars, $file) = @$args{qw(vars file)};
    if ($file eq 'bug/edit.html.tmpl') {
    	$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin:';
	my $pwd = getcwd;
	$pwd =~ m|([^\0]+)|;
	$pwd = $1;
	chdir 'extensions/BugLocalizer/repository/'.$vars->{bugs}[0]->product;
        my $result = `git tag`;
        $result =~ s/refs\/tags\///g;
        my @tags  = sort {$b cmp $a} split('\s',$result);
	$result = `git log --pretty=%H`;
        my @all_git_hash  = sort split('\s',$result);
        $vars->{'git_tags'} = \@tags;
        $vars->{'all_git_hash'} = \@all_git_hash;

	$all_git_hash[0] =~ m|([A-Za-z0-9]+)|;
	my $first_hash = $1;
        my $stdout = `git diff --name-only $first_hash^ $first_hash`;
	my @filelist = split('\s+',$stdout);
	my @filenames = sort grep(/\.java$/,@filelist);
	chdir $pwd;
	if (@filenames) {
            $vars->{filenames} = \@filenames;
        }
    }

    if ($file eq 'bug/process/results.html.tmpl') {
	my $dbh = Bugzilla->dbh;
        my $input = Bugzilla->input_params;
	my $rev = $input->{fixed_files_revision};
	my $bugid = $input->{id};
	$input->{fixed_files} =~ m/([A-Za-z0-9.\/, ]+)/;
	my $safe_fixed_files = $1;
	my @fixed_files = split(',', $safe_fixed_files);
	foreach my $fixed_file (@fixed_files){
		$dbh->do('INSERT INTO fixed_files (bug_id, filename) 
                      VALUES (?, ?)', undef, ($bugid, $fixed_file));
	}
    }
}

sub page_before_template {
    my ($self, $args) = @_;
    my $page = $args->{page_id};
    my $vars = $args->{vars};
    if ($page =~ m{^buglocalizer/git\.}) {
        $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin:';
        _page_git($vars);
    }
}

sub _page_git {
    my ($vars) = @_;
    my $dbh = Bugzilla->dbh;
    my $user = Bugzilla->user;
    my $input = Bugzilla->input_params;
    $input->{product} =~ m|([A-Za-z0-9_]+)|;
    $vars->{'product'} = $1;
    my $local_path = 'extensions/BugLocalizer/repository/'.$1;
    $input->{url} =~ m|([A-Za-z]+://[A-Za-z0-9.\/]+)|;
    my $safe_url = $1;
    $vars->{'url'} = $safe_url;
    $input->{access_type} =~ m|(Public\|Private)|;
    $vars->{'access_type'} = $1;
    #my $result = `rm -r $local_path`;
    my $result = `git clone $safe_url $local_path`;
    my $products = $user->get_selectable_products;
    unless ($user->in_group('editcomponents')) {
        $products = $user->get_products_by_permission('editcomponents');
    }
    $vars->{'products'} = $products;
}

sub webservice {
    my ($self, $args) = @_;
    my $dispatch = $args->{dispatch};
    $dispatch->{'BugLocalizer'} = "Bugzilla::Extension::BugLocalizer::WebService::BugLocalizer";
    $dispatch->{'Repository'} = "Bugzilla::Extension::BugLocalizer::WebService::Repository";
}

__PACKAGE__->NAME;
