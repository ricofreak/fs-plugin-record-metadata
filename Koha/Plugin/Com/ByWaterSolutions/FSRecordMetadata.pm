package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata;

use Modern::Perl;

use base qw(Koha::Plugins::Base);
use JSON;

use C4::Installer qw(TableExists);
use C4::Auth   qw( haspermission );

our $VERSION = "0.0.1";

our $metadata = {
    name             => 'Family Search Record Metadata Plugin',
    author           => 'Lucas Gass',
    description      => 'Family Search Koha Record Metadata plugin',
    date_authored    => '2026-07-13',
    date_updated     => '2026-07-13',
    minimum_version  => '25.1100000',
    maximum_version  => '25.1199000',
    version          => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my ( $self, $args ) = @_;
    my $dbh = C4::Context->dbh;

    my $entries_table = $self->get_qualified_table_name('entries');
    unless ( TableExists($entries_table) ) {
        $dbh->do("
            CREATE TABLE `$entries_table` (
                entry_id      INT(11) NOT NULL AUTO_INCREMENT,
                biblionumber  INT(11) NOT NULL,
                itemnumber    INT(11) NULL,
                dtn           VARCHAR(32) NULL,
                problem       TEXT NULL,
                access        VARCHAR(80) NULL, -- FS_ACCESS authorised value
                md            TINYINT(1) NOT NULL DEFAULT 0,
                audit1        TINYINT(1) NOT NULL DEFAULT 0,
                audit2        TINYINT(1) NOT NULL DEFAULT 0,
                ocr           TINYINT(1) NOT NULL DEFAULT 0,
                published     TINYINT(1) NOT NULL DEFAULT 0,
                online_review TINYINT(1) NOT NULL DEFAULT 0,
                created_on    TIMESTAMP NOT NULL DEFAULT current_timestamp(),
                created_user  INT(11) NULL,
                updated_on    TIMESTAMP NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                updated_user  INT(11) NULL,
                PRIMARY KEY (`entry_id`),
                INDEX (`biblionumber`),
                INDEX (`dtn`),
                CONSTRAINT `fs_record_metadata_entries_ibfk_1` FOREIGN KEY (`biblionumber`)
                    REFERENCES `biblio` (`biblionumber`) ON DELETE CASCADE ON UPDATE CASCADE
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

    my $userid = C4::Context->userenv ? C4::Context->userenv->{id} : undef;
    my $can_edit = $userid && haspermission( $userid, { editcatalogue => 'edit_catalogue' } ) ? 1 : 0;

    $template->param( can_edit => $can_edit );

    $self->output_html( $template->output() );
}

sub search_entries {
    my ( $self, $filters, $opts ) = @_;
    $opts //= {};

    my $page     = $opts->{page}     || 1;
    my $per_page = $opts->{per_page} || 50;
    $per_page = 100 if $per_page > 100;
    $page     = 1   if $page < 1;

    my $table = $self->get_qualified_table_name('entries');
    my $dbh   = C4::Context->dbh;

    my %columns = (
        entry_id     => 'e.entry_id',
        biblionumber => 'e.biblionumber',
        itemnumber   => 'e.itemnumber',
        dtn          => 'e.dtn',
        barcode      => 'i.barcode',
    );

    my ( @where, @binds );
    for my $key ( keys %columns ) {
        next unless defined $filters->{$key};
        push @where, "$columns{$key} = ?";
        push @binds, $filters->{$key};
    }
    my $where = @where ? 'WHERE ' . join( ' AND ', @where ) : '';

    my $from = qq{
        FROM `$table` e
        JOIN biblio b ON b.biblionumber = e.biblionumber
        LEFT JOIN items i ON i.itemnumber = e.itemnumber
        $where
    };

    my ($total) = $dbh->selectrow_array( "SELECT COUNT(*) $from", undef, @binds );

    my $offset = ( $page - 1 ) * $per_page;
    my $rows   = $dbh->selectall_arrayref(
        qq{
            SELECT e.*,
                   b.title,
                   b.author,
                   i.barcode,
                   i.itemcallnumber
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

    my $userenv = C4::Context->userenv;
    my $user_id = $userenv ? $userenv->{number} : undef;

    my @cols = qw( biblionumber itemnumber dtn problem access
                   md audit1 audit2 ocr published online_review );

    my ( @names, @placeholders, @binds );
    for my $col (@cols) {
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

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

