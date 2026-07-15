package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

use C4::Context;
use Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata;

sub list_entries {
    my $c = shift->openapi->valid_input or return;

    my $biblionumber = $c->validation->param('biblionumber');
    my $barcode      = $c->validation->param('barcode');
    my $page         = $c->validation->param('_page');
    my $per_page     = $c->validation->param('_per_page');

    unless ( defined $biblionumber || defined $barcode ) {
        return $c->render( status => 400,
            openapi => { error => "Provide biblionumber or barcode" } );
    }

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $result = $plugin->search_entries(
            { biblionumber => $biblionumber, barcode => $barcode },
            { page => $page, per_page => $per_page }
        );

        $c->res->headers->add( 'X-Total-Count' => $result->{total} );
        return $c->render( status => 200, openapi => $result->{entries} );
    }
    catch {
        return $c->render( status => 500,
            openapi => { error => "Something went wrong: $_" } );
    };
}

1;
