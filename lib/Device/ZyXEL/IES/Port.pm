package Device::ZyXEL::IES::Port;
use Moose;
use Net::SNMP qw/:asn1 ticks_to_time/;
use Net::SNMP::Util qw/snmpget/;
use namespace::autoclean;

=head1 NAME

Device::ZyXEL::IES::Port - A model of a Port on a Slot on an IES.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Models a port on a ZyXEL IES Device.

Based on Moose.

# Must have a Device::Zyxel::IES::Slot object

my $p = Device::ZyXEL::IES::Port(
  id => 301, slot => $s );

my $adminstatus = $p->read_adminstatus();

# $adminstatus is now the same as $p->adminstatus();

# DOWN the port

$p->adminstatus(1); 

=head1 MOOSE ATTRIBUTES

=head2 id

Required attribute that identifies the port. Matches ifIndex.

=cut

has 'id' => (
  isa => 'Int', 
  is => 'ro', 
  required => 1
);

=head2 slot

Required attribute that isa Device::ZyXEL::IES::Slot object.

=cut
has 'slot' => (
	isa => 'Device::ZyXEL::IES::Slot', 
	is => 'ro', 
	required => 1
);

=head2 adminstatus (rw)

ifAdminStatus on the port. Read from IES using read_adminstatus

=cut
has 'adminstatus' => (
  isa => 'Int', 
  is => 'rw', 
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    $self->write_oid( '.1.3.6.1.2.1.2.2.1.7', INTEGER, $new_value );
  }
);

=head2 operstatus (ro)

ifOperStatus on the port. Read from IES using read_operstatus

=cut
has 'operstatus' => (
  isa => 'Int', 
  is => 'ro', 
  default => sub {0}, 
  writer => '_set_operstatus'
);

=head2 uptime (ro)

uptime on the port. Read from IES using read_uptime

=cut
has 'uptime' => (
  isa => 'Str', 
  is => 'ro', 
  writer => '_set_uptime'
);

=head2 profile (rw)

Configuration profile on the port. This attribute OID will depend on the 
type of xDSL interface of the port.

=cut
has 'profile' => (
  isa => 'Str', 
  is => 'rw', 
  default => sub {''}, 
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    my $ifType = $self->readIfType;

	my $oid;
    if ( $ifType eq 'ADSL' ) {
      $oid = '.1.3.6.1.2.1.10.94.1.1.1.1.4';
    }
    elsif ( $ifType eq 'VDSL' ) {
      $oid = '.1.3.6.1.2.1.10.97.1.1.1.1.3';
    }
    elsif ( $ifType eq 'SHDSL' ) {
      $oid = '.1.3.6.1.2.1.10.48.1.1.1.2';
    }
    $self->write_oid( $oid, OCTET_STRING, $new_value );
  }
);

=head2 ifInOctets (ro)

the ifInOctets on the port. Note that if this conglomorate of modules 
is used to systematically read and record (say using RRD) values,  you
might expience trouble with cpu load on the IES. (See Device::ZyXEL::IES)

Retrieve a value for this attribute from the IES using read_ifInOctets
=cut
has 'ifInOctets' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_ifInOctets'
);

=head2 ifOutOctets (ro)

the ifOutOctets on the port. Note that if this conglomorate of modules 
is used to systematically read and record (say using RRD) values,  you
might expience trouble with cpu load on the IES. (See Device::ZyXEL::IES)

Retrieve a value for this attribute from the IES using read_ifOutOctets
=cut
has 'ifOutOctets' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_ifOutOctets'
);

=head2 userinfo (ro)

Contains the userinfo OID value from the IES.

Retrieve userinfo from the IES Port using read_userinfo
=cut
has 'userinfo' => (
  isa => 'Str', 
  is => 'ro', 
  writer => '_set_userinfo'
);

=head2 ifLastChange (ro)

Contains the ifLastChange OID value from the IES.

Retrieve a value from the IES Port using read_ifLastChange.

This attribute can be used to calculate the uptime of the port.
=cut
has 'ifLastChange' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_ifLastChange'
);

=head2 maxmac (rw)

Contains the maxmac setting from the IES.

Retrieve the maxmac value from the IES Port using read_maxmac, 
before that the value of this attribute will not reflect reality.

The maxmac setting is used by the IES in conjunction with the Snoop
feature to ensure a maximum number of MAC address pr port.

=cut
has 'maxmac' => (
  isa => 'Int', 
  is => 'rw', 
  lazy => 1, 
  default => sub { 2 },
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.1.3.1.1.2', INTEGER, $new_value );
  }
);

=head2 maxdown (ro)

Contains the maxAttainableDownstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'maxdown' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_maxdown'
);

=head2 maxup (ro)

Contains the maxAttainableUpstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'maxup' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_maxup'
);

=head2 downspeed (ro)

Contains the currAttainableDownstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'downspeed' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_downspeed'
);

=head2 upspeed (ro)

Contains the currAttainableUpstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'upspeed' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_upspeed'
);

=head2 snr_down (ro)

Contains the SNR on the Downstream channel from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'snr_down' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_snrdown'
);

=head2 snr_up (ro)

Contains the SNR on the Upstream channel from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'snr_up' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_snrup'
);

=head2 atn_down (ro)

Contains the current Attenautaion Downstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'atn_down' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_atndown'
);

=head2 atn_up (ro)

Contains the current Attenautaion Upstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'atn_up' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_atnup'
);

=head2 inp_down (rw)

Contains the current impulse noise protection level on the Downstream channel.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'inp_down' => (
  isa => 'Int', 
  is => 'rw', 
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    my $ifType = $self->readIfType;

    if ( $ifType eq 'ADSL' ) {
	  # The INP value in ADSL must be [1..7] each unit 
	  #     zero(1), 
	  #     zero_point_five(2), 
	  #     one(3), 
	  #     two(4), 
	  #     four(5), 
	  #     eight(6), 
	  #     sixteen(7)
	  if ( $new_value > 0 && $new_value < 8 ) {
        $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.15', INTEGER, $new_value );
	  }
    }
    elsif ( $ifType eq 'VDSL' ) {
      # The INP value in VDSL must by [1..160] as is a .1 precision float
	  if ( $new_value > 0 && $new_value <= 160 ) {
        $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.6', INTEGER, $new_value );
	  }
    }
  }
);

=head2 inp_up (rw)

The upstream Impulse Noise Protection minimum setting in unit of DMT symbol.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'inp_up' => (
  isa => 'Int', 
  is => 'rw', 
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    my $ifType = $self->readIfType;

    if ( $ifType eq 'ADSL' ) {
	  # The INP value in ADSL must be [1..7] each unit 
	  #     zero(1), 
	  #     zero_point_five(2), 
	  #     one(3), 
	  #     two(4), 
	  #     four(5), 
	  #     eight(6), 
	  #     sixteen(7)
	  if ( $new_value > 0 && $new_value < 8 ) {
        $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.14', INTEGER, $new_value );
	  }
    }
    elsif ( $ifType eq 'VDSL' ) {
      # The INP value in VDSL must by [1..160] as is a .1 precision float
	  if ( $new_value > 0 && $new_value <= 160 ) {
        $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.7', INTEGER, $new_value );
	  }
    }
  }
);

=head2 annexM (rw)

The ADSL Annex M setting.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'annexM' => (
  isa => 'Int', 
  is => 'rw', 
  default => sub {0},
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    my $ifType = $self->readIfType;

    if ( $ifType eq 'ADSL' ) {
	  if ( $new_value =~ /^[12]$/ ) {
        $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.3', INTEGER, $new_value );
	  }
    }
  }
);

=head2 annexL (rw)

The ADSL Annex L setting.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'annexL' => (
  isa => 'Int', 
  is => 'rw', 
  default => sub {0},
  trigger => sub {
    my ($self, $new_value, $old_value) = @_;
    my $ifType = $self->readIfType;

    if ( $ifType eq 'ADSL' ) {
	  if ( $new_value =~ /^[123]$/ ) {
        $self->write_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.2', INTEGER, $new_value );
	  }
    }
  }
);

=head2 wirepairmode (ro)

The S.HDSL Wirepair Mode setting.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'wirepairmode' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_wirepairmode'
);


=head2 vdslprotocol (ro)

The VDSL Protocol Mode setting.

One of

 none(1), 
 vdsl_8a(2), 
 vdsl_8b(3), 
 vdsl_8c(4), 
 vdsl_8d(5), 
 vdsl_12a(6), 
 vdsl_12b(7), 
 vdsl_17a(8), 
 vdsl_30a(9), 
 adsl2plus(10)

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'vdslprotocol' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_vdslprotocol'
);




=head1 FUNCTIONS

=head2 write_oid

Used (mainly internally) to write a new value into the specified OID on the IES.

The port ID is appended to the passed OID value.

=cut
sub write_oid {
  my ($self, $oid, $type, $value) = @_;

  return "[ERROR] No set comminity" unless defined $self->slot->ies->set_community();

  my ($s, $e) = Net::SNMP->session(
    -hostname  => $self->slot->ies->hostname, 
    -version   => 1,  
    -community => $self->slot->ies->set_community() 
  );

  if ( !defined( $s ) ) {
    return "[ERROR] SNMP session creation failure: $e";
  }

  my $actualoid = $oid.'.'.$self->id;
  if ( $oid =~ /%d/ ) {
    $actualoid = sprintf( $oid, $self->id );	  
  }

  my $r = $s->set_request(
    varbindlist => [ $actualoid, $type, $value] 
  );

  return "[ERROR] SNMP set error: " . $s->error() unless defined( $r );
  return 'OK';
}

=head2 read_oid

Uses Net::SNMP::Util to read the value of an oid
for a specific slot. 

=cut
sub read_oid {
  my ($self, $oid) = @_;

  return "ERROR, invalid oid" unless defined( $oid );

  my $actualoid = $oid.'.'.$self->id;
  if ( $oid =~ /%d/ ) {
    $actualoid = sprintf( $oid, $self->id );	  
  }

  return $self->slot->ies->read_oid( $actualoid );
}


=head2 read_operstatus

Asks the IES for OperStatus on the port.

=cut
sub read_operstatus {
	my $self = shift;

	my $operstatus = $self->read_oid( '.1.3.6.1.2.1.2.2.1.8' );
	if ( $operstatus =~ /^[21]$/ ) {
		$self->_set_operstatus($operstatus);
	}
	return $operstatus;
}

=head2 read_uptime

Asks the IES for uptime on the port.

=cut
sub read_uptime {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $uptime = '';

  if ( $ifType eq 'ADSL' ) {
    $uptime = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.4.1.2' );
  }
  else {
    if ( $self->slot->ies->uptime() ne 'unknown' ) {
      # use ifLastChange in combination with IES uptime to calculate
      # the port uptime
      if ( $self->ifLastChange eq 'default' ) {
        $self->read_ifLastChange();
      }
      if ( $self->slot->ies->uptime() eq 'default' ) {
        $self->slot->ies->read_uptime();
      }
      $uptime = ticks_to_time( $self->slot->ies->uptime() - $self->ifLastChange() );
    }
  }

  $self->_set_uptime( $uptime ) if $uptime !~ /ERROR/;
  return $uptime;
}

=head2 read_profile

Asks the IES for profile on the port.

=cut
sub read_profile {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $oid = '';
  my $profile = '';

  if ( $ifType eq 'ADSL' ) {
    $oid = '.1.3.6.1.2.1.10.94.1.1.1.1.4';
  }
  elsif ( $ifType eq 'VDSL' ) {
    $oid = '.1.3.6.1.2.1.10.97.1.1.1.1.3';
  }
  elsif ( $ifType eq 'SHDSL' ) {
    $oid = '.1.3.6.1.2.1.10.48.1.1.1.2';
  }
  
  if ( $oid ne '' ) {
	  $profile = $self->read_oid( $oid );
	  $self->profile( $profile ) unless $profile =~ /ERROR/;
  }
  return $profile;
}

=head2 read_ifInOctets

Asks the IES for ifInOctets on the port.

=cut
sub read_ifInOctets {
	my $self = shift;

	my $octets = $self->read_oid( '.1.3.6.1.2.1.31.1.1.1.6' );
	if ( $octets =~ /^\d+$/ ) {
		$self->_set_ifInOctets($octets);
	}
	return $octets;
}

=head2 read_ifOutOctets

Asks the IES for ifOutOctets on the port.

=cut
sub read_ifOutOctets {
	my $self = shift;

	my $octets = $self->read_oid( '.1.3.6.1.2.1.31.1.1.1.10' );
	if ( $octets =~ /^\d+$/ ) {
		$self->_set_ifOutOctets($octets);
	}
	return $octets;
}

=head2 read_ifLastChange

Asks the IES for ifLastChange on the port.

=cut
sub read_ifLastChange {
	my $self = shift;

	my $lastchange = $self->read_oid( '.1.3.6.1.2.1.2.2.1.9' );
	if ( $lastchange =~ /^\d+$/ ) {
		$self->_set_ifLastChange($lastchange);
	}
	return $lastchange;
}

=head2 read_maxmac

Asks the IES for maxmac on the port.

=cut
sub read_maxmac {
	my $self = shift;

	my $maxmac = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.1.3.1.1.2' );
	if ( $maxmac =~ /^\d+$/ ) {
		$self->maxmac($maxmac);
	}
	return $maxmac;
}

=head2 read_adminstatus

Asks the IES for OperStatus on the port.

=cut
sub read_adminstatus {
	my $self = shift;

	my $adminstatus = $self->read_oid( '.1.3.6.1.2.1.2.2.1.7' );
	if ( $adminstatus =~ /^[21]$/ ) {
		$self->adminstatus($adminstatus);
	}
	return $adminstatus;
}

=head2 read_userinfo

Asks the IES for userinfo on the port.

=cut
sub read_userinfo {
	my $self = shift;

	my $userinfo = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.1.1.1' );
	if ( $userinfo !~ /ERROR/ ) {
		$self->_set_userinfo($userinfo);
	}
	return $userinfo;
}

=head2 readIfType

Retrieves the ifType [ADSL, VDSL, SHDSL] from the associated
slot object. If cardtype (which determines the ifType) is not
previosly read from the dslam, and present in the object, it start
by reading the cardtype from the IES.

=cut
sub readIfType {
	my $self = shift;
	if ( defined $self->slot->cardtype && $self->slot->cardtype ne '' ) {
		# trust ifType
		return $self->slot->iftype;
  }
	else {
		$self->slot->read_cardtype();
		return $self->slot->iftype;
	}
}

=head2 read_maxdown

Asks the IES for max attainable downstream speed on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_maxdown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $maxdown = '';

	if ( $ifType eq 'ADSL' ) {
	  $maxdown = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.2.1.8' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $maxdown = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.9.%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $maxdown = $self->read_oid( '.1.3.6.1.2.1.10.48.1.2.1.3' );
	}
	$self->_set_maxdown($maxdown) if $maxdown =~ /^\d+$/;
	return $maxdown;
}

=head2 read_maxup

Asks the IES for maximum attainable speed upstream on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_maxup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $maxup = '';

	if ( $ifType eq 'ADSL' ) {
	  $maxup = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.3.1.8' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $maxup = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.9.%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $maxup = $self->read_oid( '.1.3.6.1.2.1.10.48.1.2.1.3' );
	}
	$self->_set_maxup($maxup) if $maxup =~ /^\d+$/;
	return $maxup;
}

=head2 read_downspeed

Asks the IES for the current downstream speed on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_downspeed {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $downspeed = '';

	if ( $ifType eq 'ADSL' ) {
	  $downspeed = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.4.1.2' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $downspeed = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.10.%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $downspeed = $self->read_oid( '.1.3.6.1.2.1.10.48.1.2.1.3' );
	}
	$self->_set_downspeed($downspeed) if $downspeed =~ /^\d+$/;
	return $downspeed;
}

=head2 read_upspeed

Asks the IES for current upstream speed on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_upspeed {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $upspeed = '';

	if ( $ifType eq 'ADSL' ) {
	  $upspeed = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.5.1.2' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $upspeed = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.10.%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $upspeed = $self->read_oid( '.1.3.6.1.2.1.10.48.1.2.1.3' );
	}
	$self->_set_upspeed($upspeed) if $upspeed =~ /^\d+$/;
	return $upspeed;
}

=head2 read_snrdown

Asks the IES for the SNR for the downstream channel on the port.

Network side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_snrdown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $snrdown = '';

	if ( $ifType eq 'ADSL' ) {
	  $snrdown = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.3.1.4' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $snrdown = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.5.%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $snrdown = $self->read_oid( '.1.3.6.1.2.1.10.48.1.5.1.2.%d%02d.2.1.1' );
	}
	$self->_set_snrdown($snrdown) if $snrdown =~ /^\d+$/;
	return $snrdown;
}

=head2 read_snrup

Asks the IES for SNR Margin on the upstream channel on the port.

Customer side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_snrup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $snrup = '';

	if ( $ifType eq 'ADSL' ) {
	  $snrup = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.2.1.4' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $snrup = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.5.%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $snrup = $self->read_oid( '.1.3.6.1.2.1.10.48.1.5.1.2.%d%02d.1.2.1' );
	}
	$self->_set_snrup($snrup) if $snrup =~ /^\d+$/;
	return $snrup;
}

=head2 read_atndown

Asks the IES for the Attenaution for the downstream channel on the port.

Network side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_atndown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $atndown = '';

	if ( $ifType eq 'ADSL' ) {
	  $atndown = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.3.1.5' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $atndown = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.6.%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $atndown = $self->read_oid( '.1.3.6.1.2.1.10.48.1.5.1.1.%d%02d.2.1.1' );
	}
	$self->_set_atndown($atndown) if $atndown =~ /^\d+$/;
	return $atndown;
}

=head2 read_atnup

Asks the IES for Attenaution on the upstream channel on the port.

Customer side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_atnup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $atnup = '';

	if ( $ifType eq 'ADSL' ) {
	  $atnup = $self->read_oid( '.1.3.6.1.2.1.10.94.1.1.2.1.5' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $atnup = $self->read_oid( '.1.3.6.1.2.1.10.97.1.1.2.1.6.%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $atnup = $self->read_oid( '.1.3.6.1.2.1.10.48.1.5.1.1.%d%02d.1.2.1' );
	}
	$self->_set_atnup($atnup) if $atnup =~ /^\d+$/;
	return $atnup;
}

=head2 read_inpdown

Asks the IES for the Impulse Noice Protection level for the downstream channel on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_inpdown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $inpdown = 0;

	if ( $ifType eq 'ADSL' ) {
	  $inpdown = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.15' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $inpdown = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.6' );
	}
	$self->inp_down($inpdown) if $inpdown =~ /^\d+$/;;
	return $inpdown;
}

=head2 read_inpup

Asks the IES for the Impulse Noice Protection level for the upstream channel on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_inpup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $inpup = 0;

	if ( $ifType eq 'ADSL' ) {
	  $inpup = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.14' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $inpup = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.7' );
	}
	$self->inp_up($inpup) if $inpup =~ /^\d+$/;
	return $inpup;
}

=head2 read_annexM

Asks the IES for the Annex M setting for the ADSL port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_annexM {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $annexM = 0;

  if ( $ifType eq 'ADSL' ) {
    $annexM = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.3' );
  }
  $self->annexM($annexM) if $annexM =~ /^\d+$/;
  return $annexM;
}

=head2 read_annexL

Asks the IES for the Annex L setting for the ADSL port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_annexL {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $annexL = 0;

  if ( $ifType eq 'ADSL' ) {
    $annexL = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.2' );
  }
  $self->annexL($annexL) if $annexL =~ /^\d+$/;
  return $annexL;
}

=head2 read_wirepairmode

Asks the IES for the S.HDSL Wirepair mode of the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_wirepairmode {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $wpm = 0;

  if ( $ifType eq 'SHDSL' ) {
    $wpm = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.8.3.3.1.1' );
  }
  $self->_set_wirepairmode($wpm) if $wpm =~ /^\d+$/;
  return $wpm;
}

=head2 read_vdslprotocol

Asks the IES for the actual VDSL protocol used on the port

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_vdslprotocol {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $protocol = 0;

  if ( $ifType eq 'VDSL' ) {
    $protocol = $self->read_oid( '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.33' );
  }
  $self->_set_vdslprotocol($protocol) if $protocol =~ /^\d+$/;
  return $protocol;
}

=head2 fetchDetails

Retrieves the details of a port from the IES.

Fetches all relevant information from the port, and fills values into the appropriate attributes.

=cut

sub fetchDetails {
  my $self = shift;
  my $meta = $self->meta();

  foreach my $method ( $meta->get_method_list ) {
    if ( $method =~ /^read_/ && $method ne 'read_oid' ) {
      my $res = $self->$method;
	  return $res if $res =~ /ERROR/i;
    }
  }
  return 'OK';
}

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::ZyXEL::IES::Port


	You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-ZyXEL-IES>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-ZyXEL-IES>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-ZyXEL-IES>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-ZyXEL-IES/>

=back


=head1 ACKNOWLEDGEMENTS

Fullrate (http://www.fullrate.dk)
  Thanks for allowing me to be introduced to the "wonderful" device ;)
	And thanks for donating some of my work time to create this module and 
	sharing it with the world.

=head1 COPYRIGHT & LICENSE

Copyright 2012 Jesper Dalberg,  all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Device::ZyXEL::IES::Port
