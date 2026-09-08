package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Problems;

# Copyright ByWater Solutions 2026
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <https://www.gnu.org/licenses>.
# Data access for entry problems.
#
# Functions take the qualified table names rather than a plugin object, so
# the SQL lives in one place and the plugin stays a thin wrapper.

use Modern::Perl;

use C4::Context;

use Exporter 'import';
our @EXPORT_OK = qw(
    problem_columns
    search_problems create_problem update_problem
);

my %PROBLEM_COLUMNS = (
    entry_id            => 'integer',
    status              => 'string',
    problem_type        => 'string',
    problem_description => 'string',
    reported_by         => 'integer',
    problem_date        => 'string',
    solution_owner      => 'integer',
    solution            => 'string',
    solution_date       => 'string',
    fixed_by            => 'integer',
);

sub problem_columns { return \%PROBLEM_COLUMNS }


sub search_problems {
    my ( $tables, $filters, $opts ) = @_;
    $filters //= {};
    $opts    //= {};

    my $problems_table = $tables->{problems};
    my $entries_table  = $tables->{entries};

    my $page     = $opts->{page}     || 1;
    my $per_page = $opts->{per_page} || 50;
    $per_page = 100 if $per_page > 100;
    $page     = 1   if $page < 1;

    my $dbh            = C4::Context->dbh;

    my %columns = (
        problem_id   => 'p.problem_id',
        entry_id     => 'p.entry_id',
        status       => 'p.status',
        problem_type => 'p.problem_type',
    );

    my %sortable = (
        problem_id          => 'p.problem_id',
        biblionumber        => 'e.biblionumber',
        dtn                 => 'e.dtn',
        title               => 'b.title',
        status              => 'p.status',
        problem_type        => 'p.problem_type',
        problem_date        => 'p.problem_date',
        solution_date       => 'p.solution_date',
    );

    my $sort_col = $sortable{ $opts->{sort_by} // '' } || 'p.problem_id';
    my $sort_dir = ( lc( $opts->{sort_dir} // '' ) eq 'asc' ) ? 'ASC' : 'DESC';

    my ( @where, @binds );
    for my $key ( keys %columns ) {
        next unless defined $filters->{$key};
        push @where, "$columns{$key} = ?";
        push @binds, $filters->{$key};
    }

    if ( defined $filters->{q} && length $filters->{q} ) {
        my @search_columns = (
            'p.status',
            'p.problem_type',
            'e.dtn',
            'b.title',
            'CAST(e.biblionumber AS CHAR)',
        );

        my $like = '%' . $filters->{q} . '%';
        push @where, '(' . join( ' OR ', map { "$_ LIKE ?" } @search_columns ) . ')';
        push @binds, ($like) x scalar(@search_columns);
    }

    my $where = @where ? 'WHERE ' . join( ' AND ', @where ) : '';

    my $from = qq{
        FROM `$problems_table` p
        JOIN `$entries_table` e ON e.entry_id = p.entry_id
        JOIN biblio b ON b.biblionumber = e.biblionumber
        $where
    };

    my ($total) = $dbh->selectrow_array( "SELECT COUNT(*) $from", undef, @binds );

    my $offset = ( $page - 1 ) * $per_page;
    my $rows   = $dbh->selectall_arrayref(
        qq{
            SELECT p.*,
                   e.dtn,
                   e.biblionumber,
                   e.ocr_site,
                   e.scan_date,
                   b.title,
                   b.author
            $from
            ORDER BY $sort_col $sort_dir
            LIMIT ? OFFSET ?
        },
        { Slice => {} },
        @binds, $per_page, $offset
    );

    return { problems => $rows, total => $total };
}

sub create_problem {
    my ( $tables, $params ) = @_;

    my $table = $tables->{problems};

    my $dbh   = C4::Context->dbh;

    my $userenv = C4::Context->userenv;
    my $user_id = $userenv ? $userenv->{number} : undef;

    my ( @names, @placeholders, @binds );
    for my $col ( keys %PROBLEM_COLUMNS ) {
        next unless exists $params->{$col};
        push @names,        $col;
        push @placeholders, '?';
        push @binds,        $params->{$col};
    }

    push @names, 'created_user', 'updated_user';
    push @placeholders, '?', '?';
    push @binds, $user_id, $user_id;

    my $sql = sprintf(
        "INSERT INTO `%s` (%s) VALUES (%s)",
        $table, join( ', ', @names ), join( ', ', @placeholders )
    );

    $dbh->do( $sql, undef, @binds );

    return $dbh->last_insert_id( undef, undef, $table, undef );
}

sub update_problem {
    my ( $tables, $problem_id, $params ) = @_;

    my $table = $tables->{problems};
    my $dbh   = C4::Context->dbh;

    my $userenv = C4::Context->userenv;
    my $user_id = $userenv ? $userenv->{number} : undef;

    my ( @sets, @binds );
    for my $col ( keys %PROBLEM_COLUMNS ) {
        next if $col eq 'entry_id';          # auto-incremented, skip it
        next unless exists $params->{$col};
        push @sets,  "$col = ?";
        push @binds, $params->{$col};
    }

    return 0 unless @sets;

    push @sets,  'updated_user = ?';
    push @binds, $user_id;

    my $sql = sprintf( "UPDATE `%s` SET %s WHERE problem_id = ?", $table, join( ', ', @sets ) );

    return $dbh->do( $sql, undef, @binds, $problem_id );
}

1;
