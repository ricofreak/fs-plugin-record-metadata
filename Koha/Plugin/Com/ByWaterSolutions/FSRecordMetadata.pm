package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata;

use Modern::Perl;

use base qw(Koha::Plugins::Base);
use JSON;

use C4::Installer qw(TableExists);
use C4::Auth   qw( haspermission );

use Koha::AuthorisedValueCategories;

use Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::AccessLevel
    qw( resolve_access_level access_control_fields );

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

our %CREATE_ONLY_COLUMNS = (
    biblionumber => 'integer',
    dtn          => 'string',
    itemnumber   => 'integer',
);

#fields that will be tied to an AV
our %AV_FIELDS = (
    owning_institution => 'Owning institution',
    scan_site          => 'Scan site',
    scan_machine       => 'Scan machine',
    ocr_site           => 'OCR site',
    problem_status => 'Problem status',
    problem_type   => 'Problem type',
);

#define roles a user can have
my %ROLES = (
    admin      => { label => 'Admin',      views => [qw( search new bulknew create create2 problems reports admin )] },
    metadata   => { label => 'Metadata',   views => [qw( search new bulknew create )] },
    scanning   => { label => 'Scanning',   views => [qw( search create problems reports )] },
    processing => { label => 'Processing', views => [qw( search create2 problems reports )] },
    readonly   => { label => 'Read-only',  views => [qw( search create create2 problems reports )] },
);

my @READONLY_VIEWS = qw( search new bulknew create create2 problems reports );

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
    my $users_table = $self->get_qualified_table_name('users');

    unless ( TableExists($entries_table) ) {
        $dbh->do("
            CREATE TABLE `$entries_table` (
                entry_id             INT(11) NOT NULL AUTO_INCREMENT,
                biblionumber         INT(11) NOT NULL,
                itemnumber           INT(11) NULL,
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

                new_scanned_image_count INT(11) NULL,
                images_resent_by     INT(11) NULL,
                images_resent_date   DATE NULL,

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
                INDEX (`itemnumber`),
                CONSTRAINT `fs_record_metadata_entries_ibfk_1` FOREIGN KEY (`biblionumber`)
                    REFERENCES `biblio` (`biblionumber`) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE = INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
    }

    unless ( TableExists($problems_table) ) {
        $dbh->do("
            CREATE TABLE `$problems_table` (
                problem_id          INT(11) NOT NULL AUTO_INCREMENT,
                entry_id            INT(11) NOT NULL,
                status              VARCHAR(80) NULL,
                problem_type        VARCHAR(80) NULL,
                problem_description TEXT NULL,
                reported_by         INT(11) NULL,
                problem_date        DATE NULL,
                solution_owner      INT(11) NULL,
                solution            TEXT NULL,
                solution_date       DATE NULL,
                fixed_by            INT(11) NULL,
                created_on          TIMESTAMP NOT NULL DEFAULT current_timestamp(),
                created_user        INT(11) NULL,
                updated_on          TIMESTAMP NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                updated_user        INT(11) NULL,
                PRIMARY KEY (`problem_id`),
                INDEX (`entry_id`),
                INDEX (`problem_date`),
                INDEX (`solution_date`),
                INDEX (`status`),
                CONSTRAINT `fs_record_metadata_problems_ibfk_1` FOREIGN KEY (`entry_id`)
                    REFERENCES `$entries_table` (`entry_id`) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE = INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
    }
    
    unless ( TableExists($users_table) ) {
        $dbh->do("
            CREATE TABLE `$users_table` (
                user_id        INT(11) NOT NULL AUTO_INCREMENT,
                borrowernumber INT(11) NOT NULL,
                role           VARCHAR(40) NOT NULL,
                PRIMARY KEY (`user_id`),
                UNIQUE KEY `borrower_role_uniq` (`borrowernumber`, `role`),
                INDEX (`borrowernumber`)
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
    $template->param(
        current_user_id   => $userenv->{number},
        current_user_name => $userenv ? ( $userenv->{firstname} . ' ' . $userenv->{surname} ) : '',
        av_json => to_json( $self->authorised_values_for_fields ),
        access_json => to_json( $self->access_for_current_user ),
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
    my ( $self, $params ) = @_;

    my $table = $self->get_qualified_table_name('entries');
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
    my ( $self, $params ) = @_;

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
    my ( $self, $params ) = @_;

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

        my $existing = $self->search_entries( { dtn => $dtn } );
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
    my $itemnumber;
    my @items;
    if ( $params->{barcode} ) {
        my $item = Koha::Items->find( { barcode => $params->{barcode} } );
        return unless $item;
        $biblio = $item->biblio;
        $itemnumber = $item->itemnumber;
        @items  = ($item);
    }
    elsif ( $params->{biblionumber} ) {
        $biblio = Koha::Biblios->find( $params->{biblionumber} );
        @items  = $biblio ? $biblio->items->as_list : ();
    }

    return unless $biblio;

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

    #get the language either from the 008, or the 041$a
    my $lang = '';

    if ( my $f008 = $record->field('008') ) {
        my $data = $f008->data // '';
        $lang = substr( $data, 35, 3 ) if length($data) >= 38;
    }

    unless ( length $lang ) {
        for my $field ( $record->field('041') ) {
            my $a = $field->subfield('a');
            next unless defined $a && length $a;
            $lang = $a;
            last;
        }
    }

    my $access_control = access_control_fields($biblio);

    return {
        biblionumber     => $biblio->biblionumber,
        itemnumber       => $itemnumber,
        title            => $title,
        author           => $author,
        publication_date => $pub_date,
        lang             => $lang,
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
        %$access_control,
    };
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

sub roles_for_borrower {
    my ( $self, $borrowernumber ) = @_;
    return [] unless $borrowernumber;

    my $table = $self->get_qualified_table_name('users');
    return C4::Context->dbh->selectcol_arrayref(
        "SELECT role FROM `$table` WHERE borrowernumber = ?",
        undef, $borrowernumber
    );
}

sub access_for_current_user {
    my ($self) = @_;

    my $userenv = C4::Context->userenv;
    return { roles => [], views => [], can_write => 0, is_admin => 0 } unless $userenv;

    my $superlibrarian = haspermission( $userenv->{id}, { superlibrarian => 1 } ) ? 1 : 0;
    my $roles          = $self->roles_for_borrower( $userenv->{number} );

    my $is_admin = ( $superlibrarian || grep { $_ eq 'admin' } @$roles ) ? 1 : 0;

    my %views;
    if (@$roles) {
        for my $role (@$roles) {
            next unless $ROLES{$role};
            $views{$_} = 1 for @{ $ROLES{$role}->{views} };
        }
    }
    else {
        $views{$_} = 1 for @READONLY_VIEWS;
    }

    $views{admin} = 1 if $is_admin;

    my $can_write = ( grep { $_ ne 'readonly' && $ROLES{$_} } @$roles ) ? 1 : 0;

    return {
        roles     => $roles,
        views     => [ sort keys %views ],
        can_write => $can_write,
        is_admin  => $is_admin,
    };
}

sub list_users {
    my ($self) = @_;

    my $table = $self->get_qualified_table_name('users');
    my $rows  = C4::Context->dbh->selectall_arrayref(
        "SELECT borrowernumber, role FROM `$table` ORDER BY role, borrowernumber",
        { Slice => {} }
    );

    my %by_role;
    push @{ $by_role{ $_->{role} } }, $_->{borrowernumber} for @$rows;
    return \%by_role;
}

sub save_users {
    my ( $self, $params ) = @_;

    my $table = $self->get_qualified_table_name('users');
    my $dbh   = C4::Context->dbh;

    $dbh->do("DELETE FROM `$table`");

    my $sth = $dbh->prepare("INSERT IGNORE INTO `$table` ( borrowernumber, role ) VALUES ( ?, ? )");
    for my $role ( keys %ROLES ) {
        for my $bn ( @{ $params->{$role} || [] } ) {
            next unless $bn =~ /^\d+$/;
            $sth->execute( $bn, $role );
        }
    }

    return 1;
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

    my %problem_props;
    for my $col ( keys %PROBLEM_COLUMNS ) {
        next if $col eq 'entry_id';
        $problem_props{$col} = { type => [ $PROBLEM_COLUMNS{$col}, 'null' ] };
    }

    my %problem_create_props = ( %problem_props, entry_id => { type => 'integer' } );

    _inject_body_properties( $spec, '/problems',              'post', \%problem_create_props );
    _inject_body_properties( $spec, '/problems/{problem_id}', 'put',  \%problem_props );

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

sub _inject_body_properties {
    my ( $spec, $path, $method, $props ) = @_;

    my $op = $spec->{$path}{$method} or return;

    for my $param ( @{ $op->{parameters} || [] } ) {
        next unless ( $param->{in} // '' ) eq 'body';
        $param->{schema}{properties} = $props;
        return;
    }
}
