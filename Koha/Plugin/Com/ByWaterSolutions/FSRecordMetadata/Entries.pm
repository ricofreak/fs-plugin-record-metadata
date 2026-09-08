package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Entries;

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

use Modern::Perl;
use Try::Tiny;

use C4::Context;
use Koha::Biblios;
use Koha::Items;

use Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::AccessLevel
    qw( resolve_access_level access_control_fields );

use Exporter 'import';
our @EXPORT_OK = qw(
    entry_columns create_only_columns
    search_entries create_entry update_entry create_entries preview_entries
);

our %ENTRY_COLUMNS = (
    secondary_identifier => 'string',
    owning_institution   => 'string',
    volume_description   => 'string',
    number_of_pages      => 'integer',

    md_date              => 'string',
    md_by                => 'integer',

    scan_site            => 'string',
    scan_operator_by     => 'integer',
    scan_machine         => 'string',
    scan_date            => 'string',
    scan_site_notes      => 'string',
    scanned_image_count  => 'integer',

    image_auditor_1_by   => 'integer',
    audit_date_1         => 'string',
    image_auditor_2_by   => 'integer',
    audit_date_2         => 'string',

    images_sent_by       => 'integer',
    images_sent_date     => 'string',

    new_scanned_image_count => 'integer',
    images_resent_by        => 'integer',
    images_resent_date      => 'string',

    ocr_site             => 'string',
    ocr_date             => 'string',

    pdf_ready_for_review => 'string',
    review_by            => 'integer',
    review_start_date    => 'string',
    review_complete_date => 'string',
    image_review_notes   => 'string',

    pdf_sent_to          => 'string',
    pdf_loaded_date      => 'string',
    pages_online         => 'integer',

    pdf_orem_archived_date   => 'string',
    pdf_orem_drive_name      => 'string',
    pdf_copy2_archived_date  => 'string',
    pdf_copy2_drive_name     => 'string',
    tiff_orem_archived_date  => 'string',
    tiff_orem_drive_name     => 'string',
    tiff_copy2_archived_date => 'string',
    tiff_copy2_drive_name    => 'string',

    images_removed_by    => 'integer',
    images_removed_date  => 'string',
    images_removed_notes => 'string',
);

my %CREATE_ONLY_COLUMNS = (
    biblionumber => 'integer',
    itemnumber   => 'integer',
    dtn          => 'string',
);

sub entry_columns       { return \%ENTRY_COLUMNS }
sub create_only_columns { return \%CREATE_ONLY_COLUMNS }

sub search_entries {
    my ( $tables, $filters, $opts ) = @_;
    $filters //= {};
    $opts    //= {};

    my $table          = $tables->{entries};
    my $problems_table = $tables->{problems};

    my $page     = $opts->{page}     || 1;
    my $per_page = $opts->{per_page} || 50;
    $per_page = 100 if $per_page > 100;
    $page     = 1   if $page < 1;

    my $dbh   = C4::Context->dbh;

    my %columns = (
        entry_id     => 'e.entry_id',
        biblionumber => 'e.biblionumber',
        dtn          => 'e.dtn',
    );

    my ( @where, @binds );
    for my $key ( keys %columns ) {
        next unless defined $filters->{$key};
        push @where, "$columns{$key} = ?";
        push @binds, $filters->{$key};
    }

    if ( defined $filters->{barcode} ) {
        push @where,
            'e.biblionumber IN (SELECT i.biblionumber FROM items i WHERE i.barcode = ?)';
        push @binds, $filters->{barcode};
    }

    my $where = @where ? 'WHERE ' . join( ' AND ', @where ) : '';

    my $from = qq{
        FROM `$table` e
        JOIN biblio b ON b.biblionumber = e.biblionumber
        $where
    };

    my ($total) = $dbh->selectrow_array( "SELECT COUNT(*) $from", undef, @binds );

    my $offset = ( $page - 1 ) * $per_page;
    my $rows = $dbh->selectall_arrayref(
        qq{
            SELECT e.*,
                   b.title,
                   b.author,
                   e.md_date              IS NOT NULL AS md,
                   e.audit_date_1         IS NOT NULL AS audit1,
                   e.audit_date_2         IS NOT NULL AS audit2,
                   e.ocr_date             IS NOT NULL AS ocr,
                   e.pdf_loaded_date      IS NOT NULL AS published,
                   e.review_complete_date IS NOT NULL AS online_review,
                   IF(e.itemnumber IS NULL,
                      (SELECT GROUP_CONCAT(i.barcode ORDER BY i.barcode SEPARATOR ', ')
                       FROM items i WHERE i.biblionumber = e.biblionumber),
                      (SELECT i.barcode FROM items i WHERE i.itemnumber = e.itemnumber)
                   ) AS barcodes,
                   IF(e.itemnumber IS NULL,
                      (SELECT GROUP_CONCAT(DISTINCT i.itemcallnumber SEPARATOR ', ')
                       FROM items i WHERE i.biblionumber = e.biblionumber),
                      (SELECT i.itemcallnumber FROM items i WHERE i.itemnumber = e.itemnumber)
                   ) AS callnumbers,
                   IF(e.itemnumber IS NULL,
                      (SELECT GROUP_CONCAT(DISTINCT i.itype SEPARATOR ', ')
                       FROM items i WHERE i.biblionumber = e.biblionumber),
                      (SELECT i.itype FROM items i WHERE i.itemnumber = e.itemnumber)
                   ) AS itypes,
                   (SELECT GROUP_CONCAT(
                        CONCAT(p.problem_id, ':', IF(p.solution_date IS NULL, '1', '0'))
                        ORDER BY p.problem_id SEPARATOR ',')
                    FROM `$problems_table` p
                    WHERE p.entry_id = e.entry_id) AS problem_numbers
            $from
            ORDER BY e.entry_id DESC
            LIMIT ? OFFSET ?
        },
        { Slice => {} },
        @binds, $per_page, $offset
    );

    return { entries => $rows, total => $total };
}

sub create_entry {
    my ( $tables, $params ) = @_;

    my $table = $tables->{entries};

    my $dbh   = C4::Context->dbh;

    my $biblio   = Koha::Biblios->find( $params->{biblionumber} );

    #compute and store the access level for MARC 
    my $resolved = resolve_access_level({ biblio => $biblio });

    $params->{access}        = $resolved->{value};
    $params->{access_source} = $resolved->{source};

    my $userenv = C4::Context->userenv;
    my $user_id = $userenv ? $userenv->{number} : undef;

    my @cols = ( keys %CREATE_ONLY_COLUMNS, keys %ENTRY_COLUMNS );

    my ( @names, @placeholders, @binds );
    for my $col (@cols) {
        next unless exists $params->{$col};
        push @names,        $col;
        push @placeholders, '?';
        push @binds,        $params->{$col};
    }

    for my $col (qw( access access_source )) {
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

sub create_entries {
    my ( $tables, $params ) = @_;

    my $shared = $params->{shared} // {};
    my @results;
    my %seen;

    for my $item ( @{ $params->{items} || [] } ) {
        my $value = $item->{value};
        my $type  = $item->{type} // 'biblionumber';
        my $itemnumber = $item->{itemnumber};

        my $result = { input => $value, type => $type };

        my $biblio;
        if ( $type eq 'barcode' ) {
            my $koha_item = Koha::Items->find( { barcode => $value } );
            if ($koha_item) {
                $biblio = $koha_item->biblio;
                $itemnumber = $koha_item->itemnumber;
                $result->{itemnumber} = $itemnumber;
            }
            else {
                $result->{status}  = 'not_found';
                $result->{message} = 'No item with that barcode';
                push @results, $result;
                next;
            }
        }
        else {
            $biblio = Koha::Biblios->find($value);
        }

        unless ($biblio) {
            $result->{status}  = 'not_found';
            $result->{message} = 'No record found';
            push @results, $result;
            next;
        }

        my $biblionumber = $biblio->biblionumber;
        $result->{biblionumber} = $biblionumber;

        if ( $seen{$biblionumber}++ ) {
            $result->{status}  = 'duplicate';
            $result->{message} = 'Repeated in this batch';
            push @results, $result;
            next;
        }

        my $dtn = $biblionumber;
        $result->{dtn} = $dtn;

        my $existing = search_entries( $tables, { dtn => $dtn } );
        if ( $existing->{total} ) {
            $result->{status}  = 'dtn_taken';
            $result->{message} = "An entry with DTN $dtn already exists";
            push @results, $result;
            next;
        }

        my $entry_id = eval {
            create_entry( $tables, {
                biblionumber       => $biblionumber,
                itemnumber         => $itemnumber,
                dtn                => $dtn,
                owning_institution => $shared->{owning_institution},
                scan_site          => $shared->{scan_site},
            });
        };

        if ($@) {
            my $err = $@;
            $err =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*$//;
            $result->{status}  = 'error';
            $result->{message} = $err;
        }
        else {
            $result->{status}   = 'created';
            $result->{entry_id} = $entry_id;
        }

        push @results, $result;
    }

    return \@results;
}

sub preview_entries {
    my ( $tables, $params ) = @_;

    my @results;
    my %seen;

    for my $item ( @{ $params->{items} || [] } ) {
        my $value = $item->{value};
        my $type  = $item->{type} // 'biblionumber';
        my $itemnumber = $item->{itemnumber};

        my $result = { input => $value, type => $type };

        my $biblio;
        if ( $type eq 'barcode' ) {
            my $koha_item = Koha::Items->find( { barcode => $value } );
            if ( $koha_item ) { 
                $biblio = $koha_item->biblio;
                $itemnumber = $koha_item->itemnumber;
                $result->{itemnumber} = $koha_item->itemnumber;
            }
            else {
                $result->{status}     = 'not_found';
                $result->{message}    = 'No item with that barcode';
                $result->{selectable} = \0;
                push @results, $result;
                next;
            }
        }
        else {
            $biblio = Koha::Biblios->find($value);
        }

        unless ($biblio) {
            $result->{status}     = 'not_found';
            $result->{message}    = 'No record found';
            $result->{selectable} = \0;
            push @results, $result;
            next;
        }

        my $biblionumber = $biblio->biblionumber;
        my $dtn          = $biblionumber;

        $result->{biblionumber} = $biblionumber;
        $result->{dtn}          = $dtn;
        $result->{title}        = $biblio->title;
        $result->{author}       = $biblio->author;

        my $resolved = resolve_access_level({ biblio => $biblio });
        $result->{access} = $resolved->{value};

        if ( $seen{$biblionumber}++ ) {
            $result->{status}     = 'duplicate';
            $result->{message}    = 'Repeated in this batch';
            $result->{selectable} = \0;
            push @results, $result;
            next;
        }

        my $existing = search_entries( $tables, { dtn => $dtn } );

        if ( $existing->{total} ) {
            $result->{status}     = 'dtn_taken';
            $result->{message}    = "An entry with DTN $dtn already exists";
            $result->{selectable} = \0;
            push @results, $result;
            next;
        }

        my $rights = access_control_fields($biblio);
        $result->{$_} = $rights->{$_} for keys %$rights;

        $result->{status}     = 'ready';
        $result->{selectable} = \1;
        push @results, $result;
    }

    return \@results;
}

sub update_entry {
    my ( $tables, $entry_id, $params ) = @_;

    my $table = $tables->{entries};
    my $dbh   = C4::Context->dbh;

    my $userenv = C4::Context->userenv;
    my $user_id = $userenv ? $userenv->{number} : undef;

    my ( @sets, @binds );
    for my $col ( keys %ENTRY_COLUMNS ) {
        next unless exists $params->{$col};
        push @sets,  "$col = ?";
        push @binds, $params->{$col};
    }

    return 0 unless @sets;

    push @sets,  'updated_user = ?';
    push @binds, $user_id;

    my $sql = sprintf( "UPDATE `%s` SET %s WHERE entry_id = ?", $table, join( ', ', @sets ) );

    return $dbh->do( $sql, undef, @binds, $entry_id );
}
