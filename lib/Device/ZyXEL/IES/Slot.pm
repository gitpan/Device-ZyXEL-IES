package Device::ZyXEL::IES::Slot;
use Moose;
use Net::SNMP::Util;
use Device::ZyXEL::IES::Port;

=head1 NAME

Device::ZyXEL::IES::Slot - A model of a Slot on an IES.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Meant to be instanciated from Device::ZyXEL::IES only.

=cut

# slot ID
# 1, 3, 4, 5, 6, 7, 8, 9, 10
has 'id' => (
  isa => 'Int', 
  is => 'ro', 
  required => 1
);

# slot firmware
has 'firmware' => (
  isa => 'Str', 
  is => 'ro', 
  writer => '_set_firmware'
);

# slot type, ADSL, VDSL, SHDSL,  MSC
has 'cardtype' => (
  isa => 'Str', 
  is => 'ro', 
  writer => '_set_cardtype', 
);


has 'iftype' => (
  isa => 'Str', 
  is => 'rw', 
  default => 'ADSL'
);

# A list of ports,  1-24 or 1-48, howmany ever
# ports the slot contains.
has 'ports' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Device::ZyXEL::IES::Port]', 
  is => 'rw', 
  default => sub { [] }, 
  handles => {
    add_port => 'push'
  }
);

sub BUILD {
  my ( $self,  $params ) = @_;
  foreach my $port ( @{ $self->ports } ) {
	    $port->slot( $self )
  }
}

after 'ports' => sub {
  my ( $self,  $ports ) = @_;
  return unless $ports;
  foreach my $port ( @$ports ) {
	    $port->slot( $self );
	}
};

has 'ies' => (
  isa => 'Device::ZyXEL::IES', 
  is => 'rw', 
  weak_ref => 1
);

=head1 FUNCTIONS

=head2 read_oid

Uses Net::SNMP::Util to read the value of an oid
for a specific slot. Used internally by _set_*

=cut
sub read_oid {
  my ($self,  $oid) = @_;

  if ( $oid =~ /\%d/ ) {
	  $oid = sprintf( $oid, $self->id );
  }
  else {
	  $oid = $oid . '.' . $self->id;
  }
  return $self->ies->read_oid( $oid );
}

=head2 read_firmware

reads the firmware version from the IES
using Net::SNMP::Util

=cut

sub read_firmware {
  my ($self) = @_;
  my $firmware = $self->read_oid('.1.3.6.1.4.1.890.1.5.13.5.6.3.1.4.0.%d');
  if ( $firmware !~ /ERROR/ ) {
    $self->_set_firmware( $firmware );
  }
  return $firmware;
}

=head2 alignports

Sets up any missing port elements in the list of ports, so
that the list always matches the actual number of and id's of the ports
on the slot.

=cut
sub alignports {
  my ($self, $nofports) = @_;
  
  for ( my $p = 1; $p <= $nofports; $p++ ) {
    my $portid = sprintf( "%d%02d", $self->id,  $p);
	# Check if this id allready exist.
    my $exists = 0;
	foreach my $ap ( @{$self->ports} ) {
      if ( $ap->id eq $portid ) {
        $exists=1; 
        last;
	  }
	}
	push @{$self->ports}, Device::ZyXEL::IES::Port->new( id => $portid, slot => $self) unless $exists;
  }

  # check if the numbers match
  if ( scalar( @{$self->ports} ) > $nofports ) {
    splice @{$self->ports}, $nofports;
  }
}

=head2 read_cardtype

reads the cardtype from the IES
using Net::SNMP::Util

=cut

sub read_cardtype {
  my ($self) = @_;
  my $cardtype = $self->read_oid('.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0.%d');
  if ( $cardtype !~ /ERROR/ ) {
    $self->_set_cardtype( $cardtype );
    if ( $cardtype =~ /^MSC/ ) {
      $self->iftype('MSC');
	  $self->alignports(0);
    }
    elsif ( $cardtype =~ /^VLC\d\d(\d\d).*$/ ) {
      $self->iftype('VDSL');
	  $self->alignports($1);
    }
    elsif ( $cardtype =~ /^SLC\d\d(\d\d).*$/ ) {
      $self->iftype('SHDSL');
	  $self->alignports($1);
    }
    elsif ( $cardtype =~ /^ALC\d\d(\d\d).*$/ ) {
      $self->iftype('ADSL');
	  $self->alignports($1);
    }
	else {
      $self->iftype('Unknown');
	  $self->alignports(0);
	}
  }
  return $cardtype;
}

=head2 fetchDetails

Fetches all the details of a slot by calling
all the read_* methods of this module.

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

=head2 portInventory

Fetches details for all ports on the slot.

=cut
sub portInventory {
  my $self = shift;

  # Will make sure all ports are created.
  my $cres = $self->read_cardtype();
  if ( $cres !~ /ERROR/ ) {
    my $pres;
	foreach my $port ( @{$self->ports} ) {
	  $pres = $port->fetchDetails();
	  return $pres if $pres =~ /ERROR/;
    }
  }
  else {
	  return $cres;
  }
  return 'OK';
}


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::ZyXEL::IES::Slot

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
			
  Copyright 2012 Jesper Dalberg,   all rights reserved.
			
  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1; # End of Device::ZyXEL::IES::Slot
