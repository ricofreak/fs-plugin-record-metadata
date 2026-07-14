package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

use C4::Context;
use Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata;

sub list_entries {
    my $c = shift->openapi->valid_input or return;

    my $biblionumber = $c->validation->param('biblionumber');
    my $barcode      = $c->validation->param('barcode');

    unless ( defined $biblionumber || defined $barcode ) {
        return $c->render(
            status  => 400,
            openapi => { error => "Provide biblionumber or barcode" }
        );
    }

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $table  = $plugin->get_qualified_table_name('entries');
        my $dbh    = C4::Context->dbh;

        my ( @where, @binds );
        if ( defined $biblionumber ) {
            push @where, 'biblionumber = ?';
            push @binds, $biblionumber;
        }
        if ( defined $barcode ) {
            push @where, 'barcode = ?';
            push @binds, $barcode;
        }
        my $where = join ' AND ', @where;

        my $sth = $dbh->prepare(
            "SELECT * FROM `$table` WHERE $where ORDER BY entry_id DESC"
        );
        $sth->execute(@binds);

        my @entries;
        while ( my $row = $sth->fetchrow_hashref ) {
            push @entries, $row;
        }

        return $c->render( status => 200, openapi => \@entries );
    }
    catch {
        return $c->render(
            status  => 500,
            openapi => { error => "Something went wrong: $_" }
        );
    };
}

1;
