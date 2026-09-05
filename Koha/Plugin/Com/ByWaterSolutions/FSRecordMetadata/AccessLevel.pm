package Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::AccessLevel;

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

use Exporter 'import';
our @EXPORT_OK = qw( resolve_access_level access_control_fields );

#privacy terms are used to determine access via MARC 998
my @PRIVACY_TERMS = qw( ADULT CHILD DECEASED );

#when no matching 998, the second level of access is
# 542$r contract permission codes ( related to the contract plugin )
#if 'J9' access denied 
#else if look for a J{\D} string and its corresponding 'K' blob 
#else move on 
my @CONTRACT_CODE_RULES = (
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

#when no matching 998 or 542, the next level of acc is 
# 506$a
#looking for string like either '108h exception' or '108c exception'
#else move on 
my @SECTION_108_RULES = (
    { subsection => 'h', access => '108h Exception' },
    { subsection => 'c', access => '108c Exception' },
);

#finally, look at 542$l, see if it begins with either 'PD' or 'IC'
my %COPYRIGHT_STATUS_ACCESS = (
    PD => 'Public',
    IC => 'Protected',
);

#MARC fields where access is read from 
my %ACCESS_CONTROL_FIELDS = (
    privacy_998f   => [ '998', 'f' ],
    contract_542r  => [ '542', 'r' ],
    ex_108         => [ '506', 'a' ],
    copyright_542l => [ '542', 'l' ],
);

sub resolve_access_level {
    my ($args) = @_;

    my $biblio = $args->{biblio};
    return { value => 'Undetermined', source => 'none' } unless $biblio;

    my $record = eval { $biblio->metadata->record };
    return { value => 'Undetermined', source => 'none' } unless $record;

    # 1. Privacy rationale in 998$f
    for my $field ( $record->field('998') ) {
        my $f = $field->subfield('f');
        next unless defined $f && length $f;
        return { value => 'Privacy Restricted', source => '998f' }
            if _is_privacy_rationale($f);
    }

    # 2. Contract permission code in 542$r
    for my $field ( $record->field('542') ) {
        my $r = $field->subfield('r');
        next unless defined $r && length $r;
        my $access = _access_from_contract_code($r);
        return { value => $access, source => '542r' } if defined $access;
    }

    # 3. Section 108 copyright exemption in 506$a
    for my $field ( $record->field('506') ) {
        my $a = $field->subfield('a');
        next unless defined $a && length $a;
        my $access = _access_from_section_108($a);
        return { value => $access, source => '506a' } if defined $access;
    }

    # 4. Copyright status in 542$l
    for my $field ( $record->field('542') ) {
        my $l = $field->subfield('l');
        next unless defined $l && length $l;
        my $access = _access_from_copyright_status($l);
        return { value => $access, source => '542l' } if defined $access;
    }

    return { value => 'Undetermined', source => 'none' };
}


#for reading the MARC fields related to access control, and then displaying them 
sub access_control_fields {
    my ($biblio) = @_;

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

#helper to see if 998 contains one of the listed @PRIVACY_TERMS
sub _is_privacy_rationale {
    my ($value) = @_;
    return 0 unless defined $value && length $value;

    for my $term (@PRIVACY_TERMS) {
        return 1 if $value =~ /\b\Q$term\E\b/i;
    }
    return 0;
}

#helper to read the permission strings 542$r
#checking the 'J{\D}' and 'K{\D}' strings  
sub _access_from_contract_code {
    my ($value) = @_;
    return undef unless defined $value && length $value;

    my @tokens = split /\s+/, $value;

    my ($j) = grep { /^J\d+[a-z]*$/i } @tokens;
    return undef unless $j;

    my @k    = grep { /^K\d+[a-z]*$/i } @tokens;
    my %have = map  { uc($_) => 1 } @k;

    for my $rule (@CONTRACT_CODE_RULES) {
        next unless uc($j) eq uc( $rule->{j} );

        my @want = @{ $rule->{k} };
        next unless scalar( keys %have ) == scalar(@want);

        my $matched = 1;
        for my $code (@want) {
            unless ( $have{ uc($code) } ) { $matched = 0; last }
        }

        return $rule->{access} if $matched;
    }

    return undef;
}

#helper for 506$a
#looking for strings like '108c' and '108h'
sub _access_from_section_108 {
    my ($value) = @_;
    return undef unless defined $value && length $value;

    for my $rule (@SECTION_108_RULES) {
        return $rule->{access}
            if $value =~ /108\s*\(\s*\Q$rule->{subsection}\E\s*\)/i;
    }

    return undef;
}

#helper for 542$l
#looking for string that begin with 'PD' or 'IC'
sub _access_from_copyright_status {
    my ($value) = @_;
    return undef unless defined $value && length $value;

    my ($token) = split /\s+/, $value;
    return undef unless defined $token;

    my ($prefix) = $token =~ /^(PD|IC)\b/i;
    return undef unless $prefix;

    return $COPYRIGHT_STATUS_ACCESS{ uc($prefix) };
}

1;
