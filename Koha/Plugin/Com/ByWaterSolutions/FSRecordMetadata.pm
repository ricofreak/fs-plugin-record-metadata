package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata;

use Modern::Perl;

use base qw(Koha::Plugins::Base);
use JSON;

use C4::Installer qw(TableExists);
use C4::Auth   qw( haspermission );

use Koha::AuthorisedValueCategories;

our $VERSION = "0.0.1";

our $metadata = {
    name             => 'Family Search Record Metadata Plugin',
    author           => 'ByWater Solutions',
    description      => 'Family Search Koha Record Metadata plugin',
    date_authored    => '2026-07-13',
    date_updated     => '2026-07-13',
    minimum_version  => '25.1100000',
    maximum_version  => '28.1199000',
    version          => $VERSION,
};

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

our %PROBLEM_COLUMNS = (
    entry_id       => 'integer',
    step           => 'string',
    reason         => 'string',
    description    => 'string',
    problem_date   => 'string',
    reported_by    => 'integer',
    initials       => 'string',
    solution_owner => 'integer',
    resolved_on    => 'string',
);

our %CREATE_ONLY_COLUMNS = (
    biblionumber => 'integer',
    dtn          => 'string',
);

#fields that will be tied to an AV
our %AV_FIELDS = (
    owning_institution => 'Owning institution',
    scan_site          => 'Scan site',
    scan_machine       => 'Scan machine',
    ocr_site           => 'OCR site',
    problem_step       => 'Problem step',
    problem_reason     => 'Problem reason',
);

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my ( $self, $args ) = @_;
    my $dbh = C4::Context->dbh;

    my $entries_table  = $self->get_qualified_table_name('entries');
    my $problems_table = $self->get_qualified_table_name('problems');

    unless ( TableExists($entries_table) ) {
        $dbh->do("
            CREATE TABLE `$entries_table` (
                entry_id             INT(11) NOT NULL AUTO_INCREMENT,
                biblionumber         INT(11) NOT NULL,
                dtn                  VARCHAR(64) NULL,
                secondary_identifier VARCHAR(64) NULL,
                owning_institution   VARCHAR(80) NULL,
                volume_description   VARCHAR(255) NULL,
                access               VARCHAR(80) NULL,
                access_source        VARCHAR(20) NULL,
                number_of_pages      INT(11) NULL,

                md_date              DATE NULL,
                md_by                INT(11) NULL,

                scan_site            VARCHAR(80) NULL,
                scan_operator_by     INT(11) NULL,
                scan_machine         VARCHAR(80) NULL,
                scan_date            DATE NULL,
                scan_site_notes      TEXT NULL,
                scanned_image_count  INT(11) NULL,

                image_auditor_1_by   INT(11) NULL,
                audit_date_1         DATE NULL,
                image_auditor_2_by   INT(11) NULL,
                audit_date_2         DATE NULL,

                images_sent_by       INT(11) NULL,
                images_sent_date     DATE NULL,

                ocr_site             VARCHAR(80) NULL,
                ocr_date             DATE NULL,

                pdf_ready_for_review DATE NULL,
                review_by            INT(11) NULL,
                review_start_date    DATE NULL,
                review_complete_date DATE NULL,
                image_review_notes   TEXT NULL,

                pdf_sent_to          VARCHAR(80) NULL,
                pdf_loaded_date      DATE NULL,
                pages_online         INT(11) NULL,

                pdf_orem_archived_date   DATE NULL,
                pdf_orem_drive_name      VARCHAR(80) NULL,
                pdf_copy2_archived_date  DATE NULL,
                pdf_copy2_drive_name     VARCHAR(80) NULL,
                tiff_orem_archived_date  DATE NULL,
                tiff_orem_drive_name     VARCHAR(80) NULL,
                tiff_copy2_archived_date DATE NULL,
                tiff_copy2_drive_name    VARCHAR(80) NULL,

                images_removed_by    INT(11) NULL,
                images_removed_date  DATE NULL,
                images_removed_notes TEXT NULL,

                created_on   TIMESTAMP NOT NULL DEFAULT current_timestamp(),
                created_user INT(11) NULL,
                updated_on   TIMESTAMP NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                updated_user INT(11) NULL,

                PRIMARY KEY (`entry_id`),
                UNIQUE KEY `dtn_uniq` (`dtn`),
                INDEX (`biblionumber`),
                INDEX (`scan_date`),
                INDEX (`access`),
                INDEX (`pdf_loaded_date`),
                CONSTRAINT `fs_record_metadata_entries_ibfk_1` FOREIGN KEY (`biblionumber`)
                    REFERENCES `biblio` (`biblionumber`) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE = INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
    }

    unless ( TableExists($problems_table) ) {
        $dbh->do("
            CREATE TABLE `$problems_table` (
                problem_id     INT(11) NOT NULL AUTO_INCREMENT,
                entry_id       INT(11) NOT NULL,
                step           VARCHAR(80) NULL,
                reason         VARCHAR(80) NULL,
                description    TEXT NULL,
                problem_date   DATE NULL,
                reported_by    INT(11) NULL,
                initials       VARCHAR(16) NULL,
                solution_owner INT(11) NULL,
                resolved_on    DATE NULL,
                created_on     TIMESTAMP NOT NULL DEFAULT current_timestamp(),
                created_user   INT(11) NULL,
                updated_on     TIMESTAMP NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                updated_user   INT(11) NULL,
                PRIMARY KEY (`problem_id`),
                INDEX (`entry_id`),
                INDEX (`problem_date`),
                CONSTRAINT `fs_record_metadata_problems_ibfk_1` FOREIGN KEY (`entry_id`)
                    REFERENCES `$entries_table` (`entry_id`) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE = INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
    }

    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

sub uninstall {
    my ( $self, $args ) = @_;

    return 1;
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{cgi};

    my $template = $self->get_template({ file => 'tool.tt' });
    my $userenv = C4::Context->userenv;
    warn 'CHECKING BORROWERNUMBER: ' . Data::Dumper::Dumper( $userenv->{number} );
    $template->param(
        current_user_id   => $userenv->{number},
        current_user_name => $userenv ? ( $userenv->{firstname} . ' ' . $userenv->{surname} ) : '',
        av_json => to_json( $self->authorised_values_for_fields ),
    );
    $self->output_html( $template->output() );
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{cgi};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        my @categories = map { $_->category_name }
            Koha::AuthorisedValueCategories->search( {}, { order_by => 'category_name' } )->as_list;

        my @fields;
        for my $field ( sort keys %AV_FIELDS ) {
            push @fields, {
                name    => $field,
                label   => $AV_FIELDS{$field},
                current => $self->av_category_for($field) // '',
            };
        }

        $template->param(
            av_fields  => \@fields,
            categories => \@categories,
        );

        $self->output_html( $template->output() );
    }
    else {
        my %data;
        for my $field ( keys %AV_FIELDS ) {
            my $chosen = scalar $cgi->param("av_category_$field") // '';
            $data{"av_category_$field"} = $chosen;
        }
        $self->store_data( \%data );
        $self->go_home();
    }
}

sub search_entries {
    my ( $self, $filters, $opts ) = @_;
    $opts //= {};

    my $page     = $opts->{page}     || 1;
    my $per_page = $opts->{per_page} || 50;
    $per_page = 100 if $per_page > 100;
    $page     = 1   if $page < 1;

    my $table = $self->get_qualified_table_name('entries');
    my $problems_table = $self->get_qualified_table_name('problems');
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
                   (SELECT GROUP_CONCAT(i.barcode ORDER BY i.barcode SEPARATOR ', ')
                    FROM items i WHERE i.biblionumber = e.biblionumber) AS barcodes,
                   (SELECT GROUP_CONCAT(DISTINCT i.itemcallnumber SEPARATOR ', ')
                    FROM items i WHERE i.biblionumber = e.biblionumber) AS callnumbers,
                   (SELECT GROUP_CONCAT(DISTINCT i.itype SEPARATOR ', ')
                    FROM items i WHERE i.biblionumber = e.biblionumber) AS itypes,
                   (SELECT GROUP_CONCAT(
                        CONCAT(p.problem_id, ':', IF(p.resolved_on IS NULL, '1', '0'))
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
    my ( $self, $params ) = @_;

    my $table = $self->get_qualified_table_name('entries');
    my $dbh   = C4::Context->dbh;

    my $biblio   = Koha::Biblios->find( $params->{biblionumber} );
    my $resolved = $self->resolve_access_level({ biblio => $biblio });
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
    my ( $self, $params ) = @_;

    my $shared = $params->{shared} // {};
    my @results;
    my %seen;

    for my $item ( @{ $params->{items} || [] } ) {
        my $value = $item->{value};
        my $type  = $item->{type} // 'biblionumber';

        my $result = { input => $value, type => $type };

        my $biblio;
        if ( $type eq 'barcode' ) {
            my $koha_item = Koha::Items->find( { barcode => $value } );
            if ($koha_item) {
                $biblio = $koha_item->biblio;
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

        my $existing = $self->search_entries( { dtn => $dtn } );
        if ( $existing->{total} ) {
            $result->{status}  = 'dtn_taken';
            $result->{message} = "An entry with DTN $dtn already exists";
            push @results, $result;
            next;
        }

        my $entry_id = eval {
            $self->create_entry({
                biblionumber       => $biblionumber,
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
    my ( $self, $params ) = @_;

    my @results;
    my %seen;

    for my $item ( @{ $params->{items} || [] } ) {
        my $value = $item->{value};
        my $type  = $item->{type} // 'biblionumber';

        my $result = { input => $value, type => $type };

        my $biblio;
        if ( $type eq 'barcode' ) {
            my $koha_item = Koha::Items->find( { barcode => $value } );
            if ($koha_item) {
                $biblio = $koha_item->biblio;
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

        my $resolved = $self->resolve_access_level({ biblio => $biblio });
        $result->{access} = $resolved->{value};

        if ( $seen{$biblionumber}++ ) {
            $result->{status}     = 'duplicate';
            $result->{message}    = 'Repeated in this batch';
            $result->{selectable} = \0;
            push @results, $result;
            next;
        }

        my $existing = $self->search_entries( { dtn => $dtn } );
        if ( $existing->{total} ) {
            $result->{status}     = 'dtn_taken';
            $result->{message}    = "An entry with DTN $dtn already exists";
            $result->{selectable} = \0;
            push @results, $result;
            next;
        }

        my $rights = $self->_access_control($biblio);
        $result->{$_} = $rights->{$_} for keys %$rights;

        $result->{status}     = 'ready';
        $result->{selectable} = \1;
        push @results, $result;
    }

    return \@results;
}

sub update_entry {
    my ( $self, $entry_id, $params ) = @_;

    my $table = $self->get_qualified_table_name('entries');
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

sub search_problems {
    my ( $self, $filters, $opts ) = @_;
    $filters //= {};
    $opts    //= {};

    my $page     = $opts->{page}     || 1;
    my $per_page = $opts->{per_page} || 50;
    $per_page = 100 if $per_page > 100;
    $page     = 1   if $page < 1;

    my $problems_table = $self->get_qualified_table_name('problems');
    my $entries_table  = $self->get_qualified_table_name('entries');
    my $dbh            = C4::Context->dbh;

    my %columns = (
        problem_id => 'p.problem_id',
        entry_id   => 'p.entry_id',
        status     => 'p.status',
        step       => 'p.step',
    );

    my ( @where, @binds );
    for my $key ( keys %columns ) {
        next unless defined $filters->{$key};
        push @where, "$columns{$key} = ?";
        push @binds, $filters->{$key};
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
                   b.author,
                   IF(p.resolved_on IS NULL, 'Open', 'Closed') AS status
            $from
            ORDER BY p.problem_id DESC
            LIMIT ? OFFSET ?
        },
        { Slice => {} },
        @binds, $per_page, $offset
    );

    return { problems => $rows, total => $total };
}

sub create_problem {
    my ( $self, $params ) = @_;

    my $table = $self->get_qualified_table_name('problems');
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
    my ( $self, $problem_id, $params ) = @_;

    my $table = $self->get_qualified_table_name('problems');
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

sub get_record_details {
    my ( $self, $params ) = @_;

    my $biblio;

    if ( $params->{barcode} ) {
        my $item = Koha::Items->find( { barcode => $params->{barcode} } );
        return unless $item;
        $biblio = $item->biblio;
    }
    elsif ( $params->{biblionumber} ) {
        $biblio = Koha::Biblios->find( $params->{biblionumber} );
    }
    
    return unless $biblio;

    my @items = $biblio->items->as_list;
    my $record = $biblio->metadata->record;

   my $title = join ' ', grep { defined && length }
   ( $biblio->title, $biblio->medium, $biblio->subtitle,
     $biblio->part_number, $biblio->part_name );

    my $author = $biblio->author;

    my $pub_date = '';
    for my $tag (qw( 260 264 )) {
        for my $field ( $record->field($tag) ) {
            my $c = $field->subfield('c');
            if ( defined $c && length $c ) { $pub_date = $c; last; }
        }
        last if length $pub_date;
    }

    my @online_links;
    for my $field ( $record->field('856') ) {
        my $url = $field->subfield('u');
        next unless defined $url && length $url;
        my $label = $field->subfield('y')      # link text
                 // $field->subfield('3')      # materials specified
                 // $field->subfield('z');     # public note
        push @online_links, {
            url   => $url,
            label => ( defined $label && length $label ) ? $label : $url,
        };
    }

    my %marc_fields = (
        privacy_998f      => [ '998', 'f' ],
        contract_542r  => [ '542', 'r' ],
        ex_108    => [ '506', 'a' ],
        copyright_542l  => [ '542', 'l' ],
    );

    my %extra;
    for my $key ( keys %marc_fields ) {
        my ( $tag, $sub ) = @{ $marc_fields{$key} };
        my @values;
        for my $field ( $record->field($tag) ) {
            for my $value ( $field->subfield($sub) ) {
                push @values, $value if defined $value && length $value;
            }
        }
        $extra{$key} = join '; ', @values;
    }

    return {
        biblionumber     => $biblio->biblionumber,
        title            => $title,
        author           => $author,
        publication_date => $pub_date,
        online_links     => \@online_links,
        items            => [
            map {
                {
                    itemnumber => $_->itemnumber,
                    barcode    => $_->barcode,
                    callnumber => $_->itemcallnumber,
                    itemtype   => $_->effective_itemtype,
                    homebranch => $_->homebranch,
                    branchname => $_->home_branch ? $_->home_branch->branchname : undef,
                }
            } @items
        ],
        %extra,
    };
}

sub resolve_access_level {
    my ( $self, $args ) = @_;

    my $biblio = $args->{biblio};
    return { value => 'Undetermined', source => 'none' } unless $biblio;

    my $record = eval { $biblio->metadata->record };
    return { value => 'Undetermined', source => 'none' } unless $record;

    # 1. Look at 998f first, if it exists check for term like ADULT CHILD DECEASED
    for my $field ( $record->field('998') ) {
        my $f = $field->subfield('f');
        next unless defined $f && length $f;
        return { value => 'Privacy Restricted', source => '998f' }
            if $self->_is_term_in_998f($f);
    }

    #2. Now look for particular codes in the 542r 
    for my $field ( $record->field('542') ) {
        my $r = $field->subfield('r');
        next unless defined $r && length $r;
        my $access = $self->_access_from_contract_code($r);
        return { value => $access, source => '542r' } if defined $access;
    }

    # 3. Now check the 506a text for  
    for my $field ( $record->field('506') ) {
        my $a = $field->subfield('a');
        next unless defined $a && length $a;
        my $access = $self->_access_from_section_108($a);
        return { value => $access, source => '506a' } if defined $access;
    }

    #4 check the 542l 
    for my $field ( $record->field('542') ) {
        my $l = $field->subfield('l');
        next unless defined $l && length $l;
        my $access = $self->_access_from_copyright_status($l);
        return { value => $access, source => '542l' } if defined $access;
    }

    # 5. Set to UNDETERMINED 
    return { value => 'Undetermined', source => 'none' };
}

our %ACCESS_CONTROL_FIELDS = (
    privacy_998f   => [ '998', 'f' ],
    contract_542r  => [ '542', 'r' ],
    ex_108         => [ '506', 'a' ],
    copyright_542l => [ '542', 'l' ],
);

sub _access_control {
    my ( $self, $biblio ) = @_;

    my %out = map { $_ => '' } keys %ACCESS_CONTROL_FIELDS;
    return \%out unless $biblio;

    my $record = eval { $biblio->metadata->record };
    return \%out unless $record;

    for my $key ( keys %ACCESS_CONTROL_FIELDS ) {
        my ( $tag, $sub ) = @{ $ACCESS_CONTROL_FIELDS{$key} };
        my @values;
        for my $field ( $record->field($tag) ) {
            for my $value ( $field->subfield($sub) ) {
                push @values, $value if defined $value && length $value;
            }
        }
        $out{$key} = join '; ', @values;
    }

    return \%out;
}

sub search_staff {
    my ( $self, $params ) = @_;

    my $term = $params->{q} // '';
    return [] unless length($term) >= 2;

    my $like = $term . '%';

    my $patrons = Koha::Patrons->search(
        {
            'category.category_type' => 'S',
            -or                      => [
                surname   => { -like => $like },
                firstname => { -like => $like },
                userid    => { -like => $like },
            ],
        },
        {
            join     => 'category',
            order_by => [ 'surname', 'firstname' ],
            rows     => 20,
        }
    );

    return [
        map {
            {
                borrowernumber => $_->borrowernumber,
                surname        => $_->surname,
                firstname      => $_->firstname,
                userid         => $_->userid,
            }
        } $patrons->as_list
    ];
}

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('staticapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;
    return 'fsrecordmetadata';
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec = decode_json( $self->mbf_read('openapi.json') );

    my %create_props;
    my %update_props;

    for my $col ( keys %ENTRY_COLUMNS ) {
        my $type = $ENTRY_COLUMNS{$col};
        my $prop = { type => [ $type, 'null' ] };
        $create_props{$col} = $prop;
        $update_props{$col} = { %$prop };
    }

    for my $col ( keys %CREATE_ONLY_COLUMNS ) {
        $create_props{$col} = { type => [ $CREATE_ONLY_COLUMNS{$col}, 'null' ] };
    }

    $create_props{biblionumber} = { type => 'integer' };

    _inject_body_properties( $spec, '/entries',            'post', \%create_props );
    _inject_body_properties( $spec, '/entries/{entry_id}', 'put',  \%update_props );

    return $spec;
}

sub av_category_for {
    my ( $self, $field ) = @_;

    my $category = $self->retrieve_data("av_category_$field");
    return ( defined $category && length $category ) ? $category : undef;
}

sub authorised_values_for_fields {
    my ($self) = @_;

    my %out;
    for my $field ( keys %AV_FIELDS ) {
        my $category = $self->av_category_for($field);
        next unless $category;

        $out{$field} = [
            map { { value => $_->authorised_value, label => $_->lib } }
                Koha::AuthorisedValues->search(
                    { category => $category },
                    { order_by => 'lib' }
                )->as_list
        ];
    }

    return \%out;
}

#match strings in 998f to certain terms defined here  
sub _is_term_in_998f {
    my ( $self, $value ) = @_;
    return 0 unless defined $value && length $value;

    my @terms = qw( ADULT CHILD DECEASED );
    for my $term (@terms) {
        return 1 if $value =~ /\b\Q$term\E\b/i;
    }
    return 0;
}

our @CONTRACT_CODE_RULES = (
    { j => 'J9', k => [],               access => 'Denied' },
    { j => 'J1', k => [ 'K2a', 'K2q' ], access => 'FSL Purchase' },
    { j => 'J1', k => [ 'K2a', 'K6'  ], access => 'Purchase' },
    { j => 'J1', k => [ 'K1'  ],        access => 'Public' },
    { j => 'J1', k => [ 'K3'  ],        access => 'Full Permission' },
    { j => 'J1', k => [ 'K3a' ],        access => 'Limited Permission' },
    { j => 'J1', k => [ 'K2j' ],        access => 'Protected' },
    { j => 'J1', k => [ 'K2a' ],        access => 'Logged in Permission' },
    { j => 'J1', k => [ 'K2h' ],        access => 'Denied' },
);

sub _access_from_contract_code {
    my ( $self, $value ) = @_;
    return undef unless defined $value && length $value;
    
    #splitting each set in to it's own token for examining 
    my @tokens = split /\s+/, $value;
    
    #looking at the contracts containing 'J', if we don't have this we move on 
    my ($j) = grep { /^J\d+[a-z]*$/i } @tokens;
    return undef unless $j;

    #find 'K' contracts, and match them 
    my @k = grep { /^K\d+[a-z]*$/i } @tokens;
    
    #CONTRACT_CODE_RULES defined by our @CONTRACT_CODE_RULES
    for my $rule (@CONTRACT_CODE_RULES) {
        next unless uc($j) eq uc( $rule->{j} );

        my @want = @{ $rule->{k} };
        next unless scalar(@k) == scalar(@want);

        my %have = map { uc($_) => 1 } @k;
        my $matched = 1;
        for my $code (@want) {
            unless ( $have{ uc($code) } ) { $matched = 0; last }
        }

        return $rule->{access} if $matched;
    }

    #if we return undef, its time to  move on, time to get going, what lies ahead we have no way of knowing  
    return undef;
}

my @SECTION_108_RULES = (
    { subsection => 'h', access => '108h Exception' },
    { subsection => 'c', access => '108c Exception' },
);

sub _access_from_section_108 {
    my ( $self, $value ) = @_;
    return undef unless defined $value && length $value;
    
    #look at the 506a for either 108h or 108c in the text, if so match 
    #SECTION_108_RULES defined by my @SECTION_108_RULES
    for my $rule (@SECTION_108_RULES) {
        return $rule->{access}
            if $value =~ /108\s*\(\s*\Q$rule->{subsection}\E\s*\)/i;
    }

    #if we return undef, its time to  move on, time to get going
    return undef;
}

my %COPYRIGHT_STATUS_ACCESS = (
    PD => 'Public',
    IC => 'Protected',
);

sub _access_from_copyright_status {
    my ( $self, $value ) = @_;
    return undef unless defined $value && length $value;

    my ($token) = split /\s+/, $value;
    return undef unless defined $token;

    my ($prefix) = $token =~ /^(PD|IC)\b/i;
    return undef unless $prefix;

    return $COPYRIGHT_STATUS_ACCESS{ uc($prefix) };
}

sub _inject_body_properties {
    my ( $spec, $path, $method, $props ) = @_;

    my $op = $spec->{$path}{$method} or return;

    for my $param ( @{ $op->{parameters} || [] } ) {
        next unless ( $param->{in} // '' ) eq 'body';
        $param->{schema}{properties} = $props;
        return;
    }
}
