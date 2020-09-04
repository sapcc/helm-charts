#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use local::lib 'local';

use MaxMind::DB::Reader;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;
use Data::Dumper;
use JSON::PP;
use Getopt::Long;
use Pod::Usage;

my $help;
my $json_file = '';
my $maxmind = '';
my $filename = 'GeoLite2-City-SAP.mmdb';
GetOptions ("output=s" => \$filename,
            "file=s"   => \$json_file,
			"public=s" => \$maxmind,
            "help"  => \$help)   # flag
or pod2usage("Try 'perl $0 --help' for more information.");

pod2usage( -verbose => 2 ) if $help || $json_file eq '';


# Your top level data structure will always be a map (hash).  The MMDB format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

my %continent_types = (
    code        => 'utf8_string',
    geoname_id  => 'uint32',
    names       => 'map',
);
my %country_types = (
    geoname_id  => 'uint32',
    iso_code    => 'utf8_string',
    names       => 'map',
);
my %reg_country_types = (
    %country_types,
);
my %location_types = (
    accuracy_radius => 'uint32',
    latitude    => 'double',
    longitude   => 'double',
    time_zone   => 'utf8_string',
);
my %name_languages = (
    en          => 'utf8_string',
);

my %types = (
    continent   => 'map',
    %continent_types,
    country     => 'map',
    %country_types,
    registered_country => 'map',
    %reg_country_types,
    location    => 'map',
    %location_types,
    names       => 'map',
    %name_languages,
);

my $address_for_sap_city;
{
	open (my $json_fh, "<:raw", $json_file) or die("can't open $json_file $!\n");
	local $/ = undef;
	$address_for_sap_city = decode_json(<$json_fh>);
	close $json_fh;
}

my $tree = MaxMind::DB::Writer::Tree->new(
    database_type => 'GeoIP2-City-SAP',
    description =>
        { en => 'GeoIP City Data with SAP Custom Additions', },
    ip_version => 4,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },

    # let the writer handle merges of IP ranges. if we don't set this then the
    # default behaviour is for the last network to clobber any overlapping
    # ranges.  See https://metacpan.org/pod/MaxMind::DB::Writer::Tree for
    # merge_strategy options.
    merge_strategy => 'recurse',

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 32,

    # Disable reservation of private networks in mmdbs
    remove_reserved_networks => 0,
);

# SAP Custom Private IPs
say "Insert Private Network Addresses";
for my $range ( keys %{$address_for_sap_city} ) {
    my $network = Net::Works::Network->new_from_string( string => $range );
    my $data = $address_for_sap_city->{$range};
	say "Insert Network $network";
    $tree->insert_network($network, $data);
}

if ($maxmind ne '') {
	my $reader = MaxMind::DB::Reader->new( file => $maxmind );
	say "Insert Public Network Addresses from MaxMind DB";
	# Maxmind Public IPs from GeoLite2-City.mmdb
	$reader->iterate_search_tree(
		sub {
			my $ip_as_integer = shift;
			my $mask_length   = shift;
			my $data          = shift;
			
			if ($ip_as_integer > 2**32-1) {
				#say "skipped because $ip_as_integer";
				say "skipping ipv6 ranges and saving current content";
				save();
				exit 1;
			}
			my $address = Net::Works::Address->new_from_integer(integer => $ip_as_integer );
			my $network = join '/', $address->as_ipv4_string, $mask_length - 96;
			if($mask_length > 127) { 
				return; 
			}
			say "Insert Network $network";
			$tree->insert_network($network, contruct_data($data));
		}
	);
}else {
	# Write the Custom database to disk.
	save();
	exit 1;
}


### SUBROUTINES
sub save {
	open my $fh, '>:raw', $filename;
	$tree->write_tree( $fh );
	close $fh;

	say "$filename has now been created";
	return;
}

sub _create_data {
    my $geoip_model = shift;
    my $section = shift;
    my %data;

    my %rules = (
        continent   => \%continent_types,
        country     => \%country_types,
        location    => \%location_types,
        registered_country => \%reg_country_types,
    );

    # curated data structure
    for my $key (keys %{$rules{$section}}) {
        if ($key eq 'names') {
            for my $lang (keys %name_languages) {
                $data{$section}{names}{$lang} = $geoip_model->{$section}->{names}->{$lang} if $geoip_model->{$section}->{names}->{$lang}
            }
        }else{
            $data{$section}{$key} = $geoip_model->{$section}->{$key} if $geoip_model->{$section}->{$key}
        }
    }
    return %data
}

sub contruct_data {
    my $geoip_model = shift;
    my %data = (
        _create_data($geoip_model, 'continent'),
        _create_data($geoip_model, 'country'),
        _create_data($geoip_model, 'location'),
        _create_data($geoip_model, 'registered_country'),
    );
    return \%data
}

__END__

=pod

=head1 create_city

Command sample - perl create_city.pl --file city.json

=head1 SYNOPSIS

perl create_city.pl [options] [parameters] 
 
Options:
	--help            brief help message

Parameters:
	--file <path/to/city.json>			Path to Custom city data in JSON format.
	--public <path/to/public.mmdb>		Path to MaxMind database.
	--output <path/to/save.mmdb>		Output location to where custom mmdb is saved.

=head1 DESCRIPTION

Curates data from JSON datafile and optionally from a MaxMind Public GeoIP2-City Database Binary file to create a customized GeoIP
mmdb binary file.

=head2 OPTIONS

=over 8

=item B<--help|-h>

Prints usage details

=back

=head2 PARAMETERS

=over 8

=item B<--file|-f>

REQUIRED. Name of file to load custom city data; Must be a valide json structure. Use jsonlint.com to confirm if necessary.

=item B<--public|-p>

OPTIONAL. Path to MaxMind GeoIP City Database to incorporate into the custom database. If not provided, signifies that only data from
<--file|-f> option will be considered

=item B<--output|-o>

OPTIONAL. Output location and file name where new custom mmdb will be saved. If none is provided DEFAULT is used. 
DEFAULT => './GeoLite2-City-SAP.mmdb'

=back

=head1 DATASE FORMAT

See C<< %types >> in source code for accepted JSON formating.

=cut
