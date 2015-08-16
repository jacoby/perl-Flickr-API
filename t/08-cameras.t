use strict;
use warnings;
use Test::More;
use Flickr::API::Cameras;
use Flickr::Tools;
use Flickr::API::People;

if (defined($ENV{MAKETEST_OAUTH_CFG})) {
    plan( tests => 15 );
}
else {
    plan(skip_all => 'Cameras tests require that MAKETEST_OAUTH_CFG points to a valid config, see README.');
}

my $config_file  = $ENV{MAKETEST_OAUTH_CFG};
my $config_ref;
my $api;
my $papi;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

    skip "Skipping oauth cameras tests, oauth config isn't there or is not readable", 14
        if $fileflag == 0;

    $api  = Flickr::API::Cameras->import_storable_config($config_file);
    $papi = Flickr::API::People->import_storable_config($config_file);

    isa_ok($api,  'Flickr::API::Cameras');
    isa_ok($papi, 'Flickr::API::People');

    is($api->is_oauth, 1, 'Does this Flickr::API::Cameras object identify as OAuth');
    is($api->success,  1, 'Did cameras api initialize successful');

    my $brands = $api->brands_list();

  SKIP: {

        skip "Skipping brands_list tests, not able to reach the API or received error", 3,
            if !$api->success;

        like($brands->[0], qr/^[a-zA-Z]+$/, "Does the list appear to have a brand");

        my %check = map {$_ => 1} @{$brands};

        is( $check{'Canon'}, 1, 'Was Canon in the brands_list');
        is( $check{'Olympus'}, 1, 'Was Olympus in the brands_list');

    }

    my $hashcameras = $api->brands_hash();

  SKIP: {

        skip "Skipping brands_hash tests, not able to reach the API or received error", 2,
            if !$api->success;

        is( $hashcameras->{'Nikon'}, 1,
            'Was Nikon in the cameras_hash');
        is( $hashcameras->{'Olympus'}, 1,
            'Was Olympus in the cameras_hash');

    }

    my $cameras = $api->get_cameras('You_call_THIS_a_camera_Brand');

    is( $api->success, 0, 'Did we fail on a fake brand as expected');
    is( $api->error_code, 1, 'Did we get an error code from Flickr');

    $cameras = $api->get_cameras('Leica');

    is( $api->success, 1, 'Were we successful as expected');

    my @cam_ids = keys(%{$cameras->{'Leica'}});

    ok( $#cam_ids > 0, 'Did we get a list of camera models');

}


exit;

__END__


# Local Variables:
# mode: Perl
# End: