package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

use C4::Context;
use Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata;

use Koha::Biblios;

sub list_entries {
    my $c = shift->openapi->valid_input or return;

    my $biblionumber = $c->validation->param('biblionumber');
    my $barcode      = $c->validation->param('barcode');
    my $page         = $c->validation->param('_page');
    my $per_page     = $c->validation->param('_per_page');

    unless ( defined $biblionumber || defined $barcode ) {
        return $c->render(
            status  => 400,
            openapi => { error => "Provide biblionumber or barcode" }
        );
    }

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $result = $plugin->search_entries(
            { biblionumber => $biblionumber, barcode => $barcode },
            { page         => $page,         per_page => $per_page }
        );

        $c->res->headers->add( 'X-Total-Count' => $result->{total} );
        return $c->render( status => 200, openapi => $result->{entries} );
    }
    catch {
        return $c->render(
            status  => 500,
            openapi => { error => "Something went wrong: $_" }
        );
    };
}

sub create_entry {
    my $c = shift->openapi->valid_input or return;

    my $body = $c->validation->param('body');

    return try {
        my $biblio = Koha::Biblios->find( $body->{biblionumber} );
        unless ($biblio) {
            return $c->render(
                status  => 404,
                openapi => { error => "Biblio not found" }
            );
        }

        my $plugin   = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $entry_id = $plugin->create_entry($body);

        my $result = $plugin->search_entries( { entry_id => $entry_id } );

        return $c->render( status => 201, openapi => $result->{entries}->[0] );
    }
    catch {
        return $c->render(
            status  => 500,
            openapi => { error => "Something went wrong: $_" }
        );
    };
}

1;
