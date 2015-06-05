use strict;
use warnings;
use Test::More tests => 17;
use Storable;
use Data::Dumper::Simple;
use XML::Simple qw(:strict);
use Flickr::API;


my $config_file  = $ENV{MAKETEST_OAUTH_CFG};
my $config_ref;
my $xs = XML::Simple->new(ForceArray => 0);
my $api;

SKIP: {
    skip "Skipping authenticated method tests,  oauth config not specified via \$ENV{MAKETEST_OAUTH_CFG}", 17
	  if !$config_file;

    my $fileflag=0;
    if (-r $config_file) { $fileflag = 1; }
    is($fileflag, 1, "Is the config file: $config_file, readable?");

  SKIP: {

        skip "Skipping authentication tests, oauth config isn't there or is not readable", 16
		  if $fileflag == 0;

		$api = Flickr::API->oauth_import_storable_config($config_file);

		isa_ok($api, 'Flickr::API');
		is($api->is_oauth, 1, 'Does Flickr::API object identify as OAuth');

		like($api->{oauth}->{consumer_key},  qr/[0-9a-f]+/i, "Did we get a consumer key from $config_file");
		like($api->{oauth}->{consumer_secret}, qr/[0-9a-f]+/i, "Did we get a consumer secret from $config_file");

		like($api->{oauth}->{access_token}->{token}, qr/^[0-9]+-[0-9a-f]+$/i,
			 "Did we get a access_token token from $config_file");
		like($api->{oauth}->{access_token}->{token_secret}, qr/^[0-9a-f]+$/i,
			 "Did we get a access_token token_secret from $config_file");
		isa_ok($api->{oauth}->{access_token}, 'Net::OAuth::AccessTokenResponse');

		my $proceed = 0;
		if ($api->{oauth}->{access_token}->{token} =~ m/^[0-9]+-[0-9a-f]+$/i and
			$api->{oauth}->{access_token}->{token_secret} =~ m/^[0-9a-f]+$/i) {

			$proceed = 1;

		}

	  SKIP: {

			skip "Skipping authentication tests, oauth access token seems wrong", 9
			  if $proceed == 0;

			my $response=$api->execute_method('flickr.auth.oauth.checkToken');

			my $content = $response->decoded_content();
			$content = $response->content() unless defined $content;

			my $ref = $xs->XMLin($content,KeyAttr => []);

			is($ref->{stat}, 'ok', "Did flickr.auth.oauth.checkToken complete sucessfully");

			isnt($ref->{oauth}->{user}->{nsid}, undef, "Did flickr.auth.oauth.checkToken return nsid");
			isnt($ref->{oauth}->{user}->{username}, undef, "Did flickr.auth.oauth.checkToken return username");

			$response=$api->execute_method('flickr.test.login');

			$content = $response->decoded_content();
			$content = $response->content() unless defined $content;

			$ref = $xs->XMLin($content,KeyAttr => []);
			is($ref->{stat}, 'ok', "Did flickr.test.login complete sucessfully");

			isnt($ref->{user}->{id}, undef, "Did flickr.test.login return id");
			isnt($ref->{user}->{username}, undef, "Did flickr.test.login return username");


			$response=$api->execute_method('flickr.prefs.getPrivacy');

			$content = $response->decoded_content();
			$content = $response->content() unless defined $content;

			$ref = $xs->XMLin($content,KeyAttr => []);
			is($ref->{stat}, 'ok', "Did flickr.prefs.getPrivacy complete sucessfully");

			isnt($ref->{person}->{nsid}, undef, "Did flickr.prefs.getPrivacy return nsid");
			isnt($ref->{person}->{privacy}, undef, "Did flickr.prefs.getPrivacy return privacy");
			warn Dumper($ref);

		}
	}
}


exit;

__END__


# Local Variables:
# mode: Perl
# End:
