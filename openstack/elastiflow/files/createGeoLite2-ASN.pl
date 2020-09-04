#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use local::lib 'local';

use MaxMind::DB::Reader;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;
use JSON::PP;
use Getopt::Long;
use Pod::Usage;

my $help;
my $json_file = '';
my $maxmind = '';
my $filename = 'GeoLite2-ASN-SAP.mmdb';
GetOptions ("output=s" => \$filename,
            "file=s"   => \$json_file,
			"public=s" => \$maxmind,
            "help"  => \$help)   # flag
or pod2usage("Try 'perl $0 --help' for more information.");

pod2usage( -verbose => 2 ) if $help || $json_file eq '';

my %types = (
    autonomous_system_number        => 'uint32',
    autonomous_system_organization  => 'utf8_string',
);

my $address_for_sap_asn;
{
	open (my $json_fh, "<:raw", $json_file) or die("can't open $json_file $!\n");
	local $/ = undef;
	$address_for_sap_asn = decode_json(<$json_fh>);
	close $json_fh;
}

my $tree = MaxMind::DB::Writer::Tree->new(
    database_type => 'GeoIP2-ASN-SAP',
    description =>
        { en => 'GeoIP ASN Data with SAP Custom Additions', },
    ip_version => 6,
    map_key_type_callback => sub { $types{ $_[0] } },
    merge_strategy => 'recurse',
    record_size => 32,
    # Disable reservation of private networks in mmdbs
    remove_reserved_networks => 0,
);

if ( $maxmind ne '' ) {
	my $reader   = MaxMind::DB::Reader->new( file => $maxmind );
	say "Insert Public Network Addresses from MaxMind DB";
	# Maxmind Public IPs from GeoLite2-ASN.mmdb
	$reader->iterate_search_tree(
		sub {
			my $ip_as_integer = shift;
			my $mask_length   = shift;
			my $data          = shift;

			my $address = Net::Works::Address->new_from_integer(integer => $ip_as_integer );
			my $ip_version = $address->version;

			my $network = join '/', $address->as_string, $mask_length;
			say "Insert Network $network";
			$tree->insert_network($network, $data);
		}
	);
}

# SAP Custom Private IPs
for my $range (keys %{$address_for_sap_asn}) {
    my $network = Net::Works::Network->new_from_string( string => $range );
    my $data = $address_for_sap_asn->{$range};

    print "$network \n";
    $tree->insert_network($network, $data);
}

save();
exit 1;

### SUBROUTINES
sub save {
	open my $fh, '>:raw', $filename;
	$tree->write_tree( $fh );
	close $fh;

	say "$filename has now been created";
	return;
}

__END__

=pod

=head1 create_asn

Command sample - perl create_asn.pl --file asn.json

=head1 SYNOPSIS

perl create_asn.pl [options] [parameters] 
 
Options:
	--help            brief help message

Parameters:
	--file <path/to/asn.json>			Path to Custom asn data in JSON format.
	--public <path/to/public.mmdb>		Path to MaxMind database.
	--output <path/to/save.mmdb>		Output location to where custom mmdb is saved.

=head1 DESCRIPTION

Curates data from JSON datafile and optionally from a MaxMind Public GeoIP2-ASN Database Binary file to create a customized GeoIP
mmdb binary file.

=head2 OPTIONS

=over 8

=item B<--help|-h>

Prints usage details

=back

=head2 PARAMETERS

=over 8

=item B<--file|-f>

REQUIRED. Name of file to load custom asn data; Must be a valide json structure. Use jsonlint.com to confirm if necessary.

=item B<--public|-p>

OPTIONAL. Path to MaxMind GeoIP asn Database to incorporate into the custom database. If not provided, signifies that only data from
<--file|-f> option will be considered

=item B<--output|-o>

OPTIONAL. Output location and file name where new custom mmdb will be saved. If none is provided DEFAULT is used. 
DEFAULT => './GeoLite2-ASN-SAP.mmdb'

=back

=head1 DATASE FORMAT

See C<< %types >> in source code for accepted JSON formating.

=cut