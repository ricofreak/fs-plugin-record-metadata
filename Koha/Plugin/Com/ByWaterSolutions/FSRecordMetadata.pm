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
                title_author  VARCHAR(255) NULL,
                callnumber    VARCHAR(255) NULL,
                barcode       VARCHAR(20) NULL,
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
    $page = 1 if $page < 1;

    my $table = $self->get_qualified_table_name('entries');
    my $dbh   = C4::Context->dbh;

    my ( @where, @binds );
    for my $col (qw( biblionumber barcode entry_id )) {
        if ( defined $filters->{$col} ) {
            push @where, "$col = ?";
            push @binds, $filters->{$col};
        }
    }
    my $where = @where ? 'WHERE ' . join( ' AND ', @where ) : '';

    my ($total) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM `$table` $where", undef, @binds );

    my $offset = ( $page - 1 ) * $per_page;
    my $rows   = $dbh->selectall_arrayref(
        "SELECT * FROM `$table` $where ORDER BY entry_id DESC LIMIT ? OFFSET ?",
        { Slice => {} },
        @binds, $per_page, $offset
    );

    return { entries => $rows, total => $total };
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

