package WherigoCartridge;

use strict;
use utf8;	# skript je psan v utf-8
use FindBin qw($Bin); use lib "$Bin";	# kvuli "F9" (make) ve vim-u
use Fcntl qw(:seek);
use Data::Dumper;
use Data::HexDump;
use Encode;
use Carp qw(carp);
use Storable;

# automaticke verzovani
our $VERSION = qw($Revision: 1.9 $)[1];

##############################################################################
package Groundspeak::GWC; # {{{
{
#use Object::InsideOut;
use Data::Dumper;

sub new {
	my ($class, %args) = @_;
	my $self = bless({}, $class);
	$self->{errors} = [];
	$self->{data} = undef;
	return $self;
}

sub load_from {
	my ($self, $filename) = @_;
	$self->{data} = Groundspeak::GWC::Data->new(parent => $self, gwcfile => $filename);
};
sub data {$_[0]->{data} || die "data not loaded yet"};

sub clear_errors {
	my ($self) = @_;
	warn "cleared error list\n";
	$self->{errors} = [];
};
sub error {
	my ($self, $err) = @_;
	warn "adding error: $err\n";
	if (!grep {$_ eq $err} $self->error_list) {
		push @{$self->{errors}}, $err;
	};
};
sub error_list {
	my ($self) = @_;
	return @{ $self->{errors} };
};

sub as_binary {
	my ($self) = @_;
	return $self->data->as_binary;
};
};
# }}}

package Groundspeak::GWC::Common; # {{{
use Data::Dumper;

sub SmartDump($) {
	my @t = split /\n/, WherigoCartridge::HexDump($_[0]); splice(@t, 0, 2);	# pryc se zahlavim
	return join("\n", map {"; $_"} @t). "\n";
};
sub smart_dump { # metoda!
	my ($self, $co) = @_;
	return SmartDump($co);
};

sub getset {
	my ($self, $attr, $value) = @_;
	#warn $#_ . ": $self, $attr, $value";
	if ($#_ >= 2) {
		$self->{$attr} = $value;
	};
	die "$attr does not exists" if !exists $self->{$attr};
	return $self->{$attr};
};

# }}};

##############################################################################
package Groundspeak::GWC::Data; # {{{
#use Object::InsideOut qw(Groundspeak::GWC::Common);
use base qw(Groundspeak::GWC::Common);
use Data::Dumper;
use POSIX qw(strftime);
use File::Temp;
use IO::File;

sub tempdir {shift->getset('tempdir', @_)};
sub signature {shift->getset('signature', @_)};
sub _coords {shift->getset('coords', @_)};
sub coords {@{ shift->_coords }};	# vyjimka, vraci pole misto reference
sub unknown {shift->getset('unknown', @_)};
sub name {shift->getset('name', @_)};
sub type {shift->getset('type', @_)};
sub player {shift->getset('player', @_)};
sub guid {shift->getset('guid', @_)};
sub description {shift->getset('description', @_)};
sub start_description {shift->getset('start_description', @_)};
sub version {shift->getset('version', @_)};
sub author {shift->getset('author', @_)};
sub company {shift->getset('company', @_)};
sub device {shift->getset('device', @_)};
sub completion_code {shift->getset('completion_code', @_)};
sub icon_id {shift->getset('icon_id', @_)};
sub splashscreen_id {shift->getset('splashscreen_id', @_)};
sub _objects {shift->getset('objects', @_)};
sub objects {$_[0]->_objects};

sub new  {
	my ($class, %args) = @_;
	my $self = bless({}, $class);
	$self->{parent} = $args{parent};
	$self->tempdir(File::Temp::tempdir(CLEANUP => 1));

	my $fh = new IO::File;
	$fh->open("<" . $args{gwcfile}) || die "$!: $args{gwcfile}";
	binmode($fh);
	$fh->sysseek(0, SEEK_SET);

	my $buf;
	sysread($fh, $buf, 7);
	my $tmp = unpack('H*', $buf);
	die {delete_file=>1, message=>"Not a GWC cartridge file: >$tmp< ($buf)"} if $buf ne pack('H*', '020a4341525400');
	$self->signature($buf);

	# pocet objektu ("souboru") v cartridgi:
	sysread($fh, $buf, 2);
	my ($numobjects) = unpack('s', $buf);

	# odkazy na jednotlive objekty:
	my %test = ();
	my @objects = ();
	for (my $i=1; $i<=$numobjects; $i++) {
		sysread($fh, $buf, 6);
		my ($id, $ofs) = unpack('sl', $buf);
		$test{$id}++;
		if ($test{$id} > 1) {
			die "duplicitni ID objektu: $id!";
		};
		push @objects, {
			id => $id,
			offset => $ofs,
			original_order => $i	# nepodstatne
		};
	};

	my $pos = $fh->sysseek(0, SEEK_CUR);
	# Nasleduje skutecne zahlavi se souradnicemi, popisem, atd.:
	sysread($fh, $buf, 4);
	$pos += 4;
	my $len=unpack('l', $buf);	# delka zahlavi
	my $b_addr = $len + $pos;
	if ($b_addr != $objects[0]->{offset}) {
		die "divne, po hlavicce (\@ $pos) nenasleduje hned LUA bytecode (@ $objects[0]->{offset}), nesedi delka zahlavi a zacatek bytekodu!";
		# asi ne, ma uplne jiny vyznam:
		#warn sprintf("b=%02x (adresa kodu je file \@ %02x)\n", $len, $b_addr);	# adresa zaverecneho kodu 
	};

	sysread($fh, $buf, $len);
	my ($N, $E,
		$a,$b,
		$x,$y,
		$large_icon_id,
		$small_icon_id,
		$type, $member, $v, $w, $name, $guid, $htmldesc, $shortdesc, $textversion, $author, $authorurl, $destdevice, $u, $code) = 
		unpack('dd llll ss Z*Z* ll Z*Z*Z*Z*Z*Z*Z*Z*LZ*', $buf);

	$self->_coords([$N,$E]);
	$self->unknown([$a,$b, $x,$y, $u, $v,$w]);
	$self->type($type);
	$self->player($member);
	$self->name($name);
	$self->guid($guid);
	$self->description($htmldesc);
	$self->start_description($shortdesc);
	$self->version($textversion);
	$self->author($author);
	$self->company($authorurl);
	$self->device($destdevice);
	$self->completion_code($code);
	$self->splashscreen_id($large_icon_id);
	$self->icon_id($small_icon_id);

	my @newobjects = ();
	#warn "nacitam objekty ze souboru";
	#warn "objs=".Dumper(\@objects);
	for (my $i=0; $i<=$#objects; $i++) {
		my $info = $objects[$i];
		my $ofs = $info->{offset};
		$fh->sysseek($ofs, SEEK_SET) || die $!;

		my $obj = Groundspeak::GWC::Object->new(parent => $self, id => $info->{id});
		$obj->filename($self->dir . "/" . $i);	# docasne soubory pojmenuji podle poradi, je to jednodussi
		#warn "$i: " . $obj->filename;

		if ($i == 0) { # uplne prvni objekt s Lua bytecodem, nema u sebe uvedeny typ ani nic dalsiho. Jen delku.
			sysread($fh, $buf, 4);
			my $len = unpack('l', $buf);
			sysread($fh, $buf, $len);
			$obj->bintype(-2);
			$obj->set_content($buf);	# luac.out
			$buf = undef;
		} else {
			sysread($fh, $buf, 1);
			my ($a) = unpack('C', $buf);
			if ($a == 0) {
				# nutne. Cartridge pro Colorado casto obsahuji "smazane" objekty ktere ukazuji na blok s cislem '0',
				# a kdybych je nepreskakoval tak vzapeti nactu chybnou delku bloku a program jde do haje.
				#warn "$a is not 01, ignoring object [$id], probably Colorado cartridge with deleted WAV or something similar";
				$obj->bintype(-1);	# smazany soubor
				$obj->set_content('');	# dtto
			} elsif (($a == 1) || ($a == 2)) {	# co je dvojka, to nevim, ale je v 135660620cdd08b6fcb6ea55dab7ac1d3e91ad0f.gwc
				sysread($fh, $buf, 8);
				my ($type, $len) = unpack('ll', $buf);
				sysread($fh, $buf, $len);
				$obj->bintype($type);	
				$obj->set_content($buf);
				$buf = undef;
			} else {
				die "unknown first byte: $a";
			};
		};
		push @newobjects, $obj;
	};
	$self->_objects(\@newobjects);

	$fh->close;
	return $self;
}

sub dir {$_[0]->tempdir || die "tempdir not known"};	# die kdyz docasny adresar neni znamy
sub numobjects {1 + $#{$_[0]->objects}};
sub as_binary {
	my ($self) = @_;
	my $ret = '';
	$ret .= $self->signature;	# 7 bajtu

	$ret .= pack('s', $self->numobjects);	# 2 bajty

	# ted musim spocitat delku zbytku hlavicky:
	my $innerheader = '';
	$innerheader .= pack('dd llll ss Z*Z* ll Z*Z*Z*Z*Z*Z*Z*Z*LZ*',
		$self->coords,	# vraci 2 hodnoty

		$self->unknown->[0],
		$self->unknown->[1],
		$self->unknown->[2],
		$self->unknown->[3],

		$self->icon_id,	# nebo -1
		$self->splashscreen_id,	# nebo -1
	
		$self->type,
		$self->player,

		$self->unknown->[5],
		$self->unknown->[6],

		$self->name,
		$self->guid,
		$self->description,
		$self->start_description,
		$self->version,
		$self->author,
		$self->company,
		$self->device,
		$self->unknown->[4],
		$self->completion_code
	);
	my $baseoffset = length($ret) + 6*$self->numobjects + 4 + length($innerheader);

	# pridam tam odkazy na vsechny objekty:
	for (my $i=1; $i<=$self->numobjects; $i++) {
		my $obj = ($self->objects)->[$i-1];

		$ret .= pack('sl', $obj->id, $baseoffset);
		my $datalen = $obj->content_length;
		if ($i == 1) {
			$datalen += 4;
		} else {
			if ($obj->bintype == -1) {
				# smazany prvek neobsahuje nic nez jednu nulu
				$datalen += 1;
			} else {
				$datalen += 9;
			};
		};
		$baseoffset += $datalen;
	};

	$ret .= pack('l', length($innerheader));	# 4 bajty
	$ret .= $innerheader;

	for (my $i=1; $i<=$self->numobjects; $i++) {
		my $obj = ($self->objects)->[$i-1];
		my $datalen = $obj->content_length;
		if ($i == 1) {
			$ret .= pack('l', $datalen);
			$ret .= $obj->get_content;
		} else {
			if ($obj->bintype == -1) {
				# smazany objekt, mel by mit i bintype=-1
				$ret .= pack('C', 0);
			} else {
				$ret .= pack('C', 1);	# FIXME vzdy 1, nebo treba i 2 atd.?
				$ret .= pack('ll', $obj->bintype, $datalen);
				$ret .= $obj->get_content;
			};
		};
	};
	
	return $ret;
};

sub DESTROY {
	my ($self) = @_;
	# FIXME smazat docasne soubory
	# netreba, postara se o to File::Temp s parametrem CLEANUP u dir
};
# }}}

package Groundspeak::GWC::Object; { # {{{
#use Object::InsideOut qw(Groundspeak::GWC::Common);
use base qw(Groundspeak::GWC::Common);
use Data::Dumper;
use POSIX qw(strftime);
use File::Temp;
use IO::File;

# parametry:
sub id {shift->getset('id', @_)};
sub bintype {shift->getset('bintype', @_)};
sub _filename {shift->getset('filename', @_)};

sub new  {
	my ($class, %args) = @_;
	my $self = bless({}, $class);
	$self->{parent} = $args{parent};
	$self->id($args{id});
	return $self;
};

sub texttype {
	my ($self, $new) = @_;
	die if defined $new;	# nelze nastavovat
	my $b = $self->bintype;
	return {
		-2		=> 'lua',	# lua bytecode
		-1		=> 'del',	# smazany soubor neznameho typu
		0x01	=> 'bmp',
		0x03	=> 'jpg',
		0x04	=> 'gif',
		0x11	=> 'wav',
		0x13	=> 'fdl'	# nahrada WAVu pro Coloradu. Neco jako MID ci co? Netusim. Proste "pseudo.fdl"
	}->{$b};
};

sub filename {
	my ($self, $new) = @_;
	if (defined $new) {
		$self->_filename($new);
	};
	return $self->_filename || die "filename not assigned yet!";
};

sub set_content {
	my ($self, $raw_data) = @_;
	my $fh = IO::File->new;
	open ($fh, ">", $self->filename) || die;
	binmode($fh);
	print $fh $raw_data;
	close $fh;
	return;
};

sub get_content {
	my ($self) = @_;
	my $fh = IO::File->new;
	open ($fh, "<", $self->filename) || die;
	binmode($fh);
	my $ret = undef;
	{
		local $/ = undef;
		$ret = <$fh>;
	};
	close $fh;
	return $ret;
};

sub content_length {
	my ($self) = @_;
	return -s ($self->filename);
};
}; # }}}

1;

