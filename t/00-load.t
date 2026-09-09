use Modern::Perl;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/..";

use_ok('Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata');
use_ok('Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::AccessLevel');
use_ok('Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::UserRoles');
use_ok('Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Entries');
use_ok('Koha::Plugin::Com::ByWaterSolutions::FSRecordMetadata::Problems');
