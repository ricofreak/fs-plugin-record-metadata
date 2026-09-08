package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::UserRoles;

# User roles related to the plugin
# A staff user with no role has no access. Superlibrarians can always reach
# the Admin page so the first roles can be granted.

use Modern::Perl;

use C4::Context;
use C4::Auth qw( haspermission );

use Exporter 'import';
our @EXPORT_OK = qw( roles user_access list_users save_users );

my %ROLES = (
    admin      => { label => 'Admin',      views => [qw( search new bulknew create create2 problems reports admin )] },
    metadata   => { label => 'Metadata',   views => [qw( search new bulknew create )] },
    scanning   => { label => 'Scanning',   views => [qw( search create problems reports )] },
    processing => { label => 'Processing', views => [qw( search create2 problems reports )] },
    readonly   => { label => 'Read-only',  views => [qw( search create create2 problems reports )] },
);

sub roles { return \%ROLES }

sub roles_for_borrower {
    my ( $table, $borrowernumber ) = @_;
    return [] unless $borrowernumber;

    return C4::Context->dbh->selectcol_arrayref(
        "SELECT role FROM `$table` WHERE borrowernumber = ?",
        undef, $borrowernumber
    );
}

sub user_access {
    my ($table) = @_;

    my $userenv = C4::Context->userenv;
    return { roles => [], views => [], can_write => 0, is_admin => 0 } unless $userenv;

    my $superlibrarian = haspermission( $userenv->{id}, { superlibrarian => 1 } ) ? 1 : 0;
    my $roles          = roles_for_borrower( $table, $userenv->{number} );

    my $is_admin = ( $superlibrarian || grep { $_ eq 'admin' } @$roles ) ? 1 : 0;

    my %views;
    for my $role (@$roles) {
        next unless $ROLES{$role};
        $views{$_} = 1 for @{ $ROLES{$role}->{views} };
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
    my ($table) = @_;

    my $rows = C4::Context->dbh->selectall_arrayref(
        "SELECT borrowernumber, role FROM `$table` ORDER BY role, borrowernumber",
        { Slice => {} }
    );

    my %by_role;
    push @{ $by_role{ $_->{role} } }, $_->{borrowernumber} for @$rows;
    return \%by_role;
}

sub save_users {
    my ( $table, $params ) = @_;

    my $dbh = C4::Context->dbh;
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

1;
