#
# $Id: X.pm,v 1.9 2004/05/16 15:02:45 rdw Exp $
#

package PerlWM::X;

############################################################################

use strict;
use warnings;
use base qw(X11::Protocol
	    PerlWM::X::Event
	    PerlWM::X::Object
	    PerlWM::X::Color
	    PerlWM::X::Image
	    PerlWM::X::Font
	    PerlWM::X::Key
	    PerlWM::X::GC);

use PerlWM::X::Window;

############################################################################

sub new {

  my($proto, %args) = @_;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $self = $class->SUPER::new(delete $args{display}, delete $args{auth});

  $self->{error_handler} = \&error_handler;

  if ($args{debug}) {
    # super cool x debugging - you've never had it so good
    eval q{
      sub assemble_request {
	my($self, @args) = @_;
	my $cd = ((caller(2))[3] =~ /AUTOLOAD/) ? 2 : 1;
	$self->{debug}->{$self->{sequence_num}} = join ':',(caller($cd))[1,2];
	$self->SUPER::assemble_request(@args);
      }
    };
    die $@ if $@;
  }

  $self->object_init();
  $self->event_init();

  return $self;
}

############################################################################

sub pack_mods {

  my($self, @mods) = @_;
  if (!$#mods) {
    if ($mods[0] eq 'None') {
      return 0;
    }
    elsif ($mods[0] eq 'Any') {
      return 0x8000;
    }
  }
  my($result) = 0;
  foreach my $m (@mods) {
    $result |= 1 << $self->num('KeyMask', $m);
  }
  return $result;
}

############################################################################

sub unpack_mods {

  my($self, $value) = @_;
  my(@result);
  my($bit) = 0;
  while ($value) {
    if ($value & 1) {
      push @result, $self->interp('KeyMask', $bit);
    }
    $value >>= 1;
    $bit++;
  }
  return @result;
}

############################################################################

sub error_handler { 

  my($self, $data) = @_;
  my($type, $seq, $info, $minor_op, $major_op) = 
    unpack("xCSLSCxxxxxxxxxxxxxxxxxxxxx", $data);
  $type = $self->do_interp('Error', $type);
  my $request = ($self->do_interp('Request', $major_op) ||
		 $self->{ext_request}{$major_op}[$minor_op][0]);
  if ($self->{debug}) {
    $info = X11::Protocol::hexi($info);
    print STDERR "Error - $self->{debug}->{$seq} - $request($info) - $type\n";
  }
  else {
    print STDERR "Error - $request\n";
  }
  # unwedge anything waiting for reply
  ${$self->{replies}->{$seq}} = $data;
  # die (sometimes)
  die "$request" if $self->{die_on_error};
}

############################################################################

sub window_attach {

  my($self, $window) = @_;

  $self->{window}->{$window->{id}} = $window;
}

############################################################################

sub window_detach {

  my($self, $window, %args) = @_;

  delete $self->{window}->{$window->{id}};
  $self->event_window_detach($window, %args);
}

############################################################################

sub alien {

  my($self, $id) = @_;
  $id &= (-1 ^ $self->{resource_id_mask});
  return ($id != $self->{resource_id_base});
}

############################################################################

sub dumper {

  my($self, @args) = @_;
  require Data::Dumper;
  my $dd = Data::Dumper->new([@args]);
  $dd->Indent(1);
  $dd->Seen({x => $self});
  print $dd->Dump();
}

############################################################################

# We fix a problem with X11::Protocol here - it doesn't handle request
# numbers wrapping around correctly. We only need to tweak a couple of
# functions which are used to track the replies from requests.

no warnings 'redefine';

sub X11::Protocol::add_reply {
  my $self = shift;
  my($seq, $var) = @_;
  $self->{'replies'}->{$seq & 0xffff} = $var;
}

sub X11::Protocol::delete_reply {
  my $self = shift;
  my($seq) = @_;
  delete $self->{'replies'}->{$seq & 0xffff};
}

############################################################################

# We tweak X11::Protocol again here - to use sysread, not read, so we 
# can then use select. This shouldn't really hurt performance too badly, 
# since X11::Protocol reads everything fairly efficiently. This is just a
# copy of the function we need to change.

use X11::Protocol::Connection::Socket;
use X11::Protocol::Connection::FileHandle;

sub X11::Protocol::Connection::Socket::get {
  my($self) = shift;
  my($len) = @_;
  my($x, $n, $o) = ("", 0, 0);
  my($sock) = $$self;
  until ($o == $len) {
    $n = $sock->sysread($x, $len - $o, $o);
    croak $! unless defined $n;
    $o += $n;
  }
  return $x;
}

sub X11::Protocol::Connection::FileHandle::get {
  my($self) = shift;
  my($len) = @_;
  my($x, $n, $o) = ("", 0, 0);
  my($fh) = $$self;
  until ($o == $len) {
    $n = read $fh, $x, $len - $o, $o;
    croak $! unless defined $n;
    $o += $n;
  }
  return $x;
}

############################################################################

1;
