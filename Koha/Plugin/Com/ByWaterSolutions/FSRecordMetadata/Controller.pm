package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Controller;

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
        my $plugin   = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        return if _deny_unless_writable( $c, $plugin );

        my $biblio = Koha::Biblios->find( $body->{biblionumber} );
        unless ($biblio) {
            return $c->render(
                status  => 404,
                openapi => { error => "Biblio not found" }
            );
        }

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

sub create_entries {
    my $c = shift->openapi->valid_input or return;

    my $body = $c->validation->param('body');

    return try {
        my $plugin  = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        return if _deny_unless_writable( $c, $plugin );

        my $results = $plugin->create_entries({
            items  => $body->{items},
            shared => {
                owning_institution => $body->{owning_institution},
                scan_site          => $body->{scan_site},
            },
        });

        my %summary = ( created => 0, skipped => 0, failed => 0 );
        for my $r (@$results) {
            if    ( $r->{status} eq 'created' ) { $summary{created}++ }
            elsif ( $r->{status} eq 'error' )   { $summary{failed}++ }
            else                                { $summary{skipped}++ }
        }

        return $c->render(
            status  => 200,
            openapi => { summary => \%summary, results => $results }
        );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub preview_entries {
    my $c = shift->openapi->valid_input or return;

    my $body = $c->validation->param('body');

    return try {
        my $plugin  = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $results = $plugin->preview_entries({ items => $body->{items} });
        return $c->render( status => 200, openapi => { results => $results } );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub update_entry {
    my $c = shift->openapi->valid_input or return;

    my $entry_id = $c->validation->param('entry_id');
    my $body     = $c->validation->param('body');

    return try {
        my $plugin   = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        return if _deny_unless_writable( $c, $plugin );
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
    my $q = $c->validation->param('q');

    my $status   = $c->validation->param('status');
    my $entry_id = $c->validation->param('entry_id');
    my $problem_id = $c->validation->param('problem_id');
    my $page     = $c->validation->param('_page');
    my $per_page = $c->validation->param('_per_page');
    my $sort_by  = $c->validation->param('_order_by');
    my $sort_dir = $c->validation->param('_order_dir');

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        my $result = $plugin->search_problems(
            { status => $status, entry_id => $entry_id, problem_id => $problem_id, q => $q },
            { page   => $page,   per_page => $per_page, sort_by => $sort_by, sort_dir => $sort_dir }
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
        return if _deny_unless_writable( $c, $plugin );

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
        return if _deny_unless_writable( $c, $plugin );

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

sub _deny_unless_writable {
    my ( $c, $plugin ) = @_;

    return 0 if $plugin->access_for_current_user->{can_write};

    $c->render( status => 403, openapi => { error => "Read-only access" } );
    return 1;
}

sub list_users {
    my $c = shift->openapi->valid_input or return;

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        return $c->render( status => 403, openapi => { error => "Not permitted" } )
            unless $plugin->access_for_current_user->{is_admin};

        return $c->render( status => 200, openapi => $plugin->list_users );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

sub save_users {
    my $c = shift->openapi->valid_input or return;

    my $body = $c->validation->param('body');

    return try {
        my $plugin = Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata->new;
        return $c->render( status => 403, openapi => { error => "Not permitted" } )
            unless $plugin->access_for_current_user->{is_admin};

        $plugin->save_users($body);
        return $c->render( status => 200, openapi => { saved => \1 } );
    }
    catch {
        return $c->render( status => 500, openapi => { error => "Something went wrong: $_" } );
    };
}

1;
