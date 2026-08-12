package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(true false);

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

sub lookup_record {
    my $c = shift->openapi->valid_input or return;

    my $biblionumber = $c->validation->param('biblionumber');
    my $barcode      = $c->validation->param('barcode');

    unless ( defined $biblionumber || defined $barcode ) {
        return $c->render( status => 400,
            openapi => { error => "Provide biblionumber or barcode" } );
    }

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $details = $plugin->get_record_details(
            { biblionumber => $biblionumber, barcode => $barcode } );

        unless ($details) {
            return $c->render( status => 404,
                openapi => { error => "Record not found" } );
        }

        return $c->render( status => 200, openapi => $details );
    }
    catch {
        return $c->render( status => 500,
            openapi => { error => "Something went wrong: $_" } );
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

sub update_entry {
    my $c = shift->openapi->valid_input or return;

    my $entry_id = $c->validation->param('entry_id');
    my $body     = $c->validation->param('body');

    return try {
        my $plugin   = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $existing = $plugin->search_entries( { entry_id => $entry_id } );

        unless ( $existing->{total} ) {
            return $c->render( status => 404, openapi => { error => "Entry not found" } );
        }

        $plugin->update_entry( $entry_id, $body );

        my $updated = $plugin->search_entries( { entry_id => $entry_id } );
        return $c->render( status => 200, openapi => $updated->{entries}->[0] );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub list_problems {
    my $c = shift->openapi->valid_input or return;

    my $status   = $c->validation->param('status');
    my $entry_id = $c->validation->param('entry_id');
    my $problem_id = $c->validation->param('problem_id');
    my $page     = $c->validation->param('_page');
    my $per_page = $c->validation->param('_per_page');

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $result = $plugin->search_problems(
            { status => $status, entry_id => $entry_id, problem_id => $problem_id },
            { page   => $page,   per_page => $per_page }
        );

        $c->res->headers->add( 'X-Total-Count' => $result->{total} );
        return $c->render( status => 200, openapi => $result->{problems} );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub create_problem {
    my $c = shift->openapi->valid_input or return;

    my $body = $c->validation->param('body');

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;

        my $entry = $plugin->search_entries( { entry_id => $body->{entry_id} } );
        unless ( $entry->{total} ) {
            return $c->render( status => 404, openapi => { error => "Entry not found" } );
        }

        my $problem_id = $plugin->create_problem($body);
        my $result = $plugin->search_problems( { problem_id => $problem_id } );

        return $c->render( status => 201, openapi => $result->{problems}->[0] );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub update_problem {
    my $c = shift->openapi->valid_input or return;

    my $problem_id = $c->validation->param('problem_id');
    my $body       = $c->validation->param('body');

    return try {
        my $plugin   = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $existing = $plugin->search_problems( { problem_id => $problem_id } );

        unless ( $existing->{total} ) {
            return $c->render( status => 404, openapi => { error => "Problem not found" } );
        }

        $plugin->update_problem( $problem_id, $body );

        my $updated = $plugin->search_problems( { problem_id => $problem_id } );
        return $c->render( status => 200, openapi => $updated->{problems}->[0] );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub list_staff {
    my $c = shift->openapi->valid_input or return;

    my $q = $c->validation->param('q');

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        return $c->render( status => 200, openapi => $plugin->search_staff( { q => $q } ) );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub check_dtn {
    my $c = shift->openapi->valid_input or return;

    my $dtn = $c->validation->param('dtn');

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $result = $plugin->search_entries( { dtn => $dtn } );

        return $c->render(
            status  => 200,
            openapi => { dtn => $dtn, available => ( $result->{total} ? false : true ) }
        );
    }
    catch {
        return $c->render( status => 500,
            openapi => { error => "Something went wrong: $_" } );
    };
}

1;
