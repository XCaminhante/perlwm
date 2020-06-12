#
# $Id: Widget.pm,v 1.5 2004/05/23 14:24:33 rdw Exp $
#

package PerlWM::Widget;

############################################################################

use strict;
use warnings;

use base qw(PerlWM::X::Window);

use PerlWM::Config;

############################################################################

BEGIN {

  my $config = PerlWM::Config->new('default/widget');
  $config->set(background => 'black',
	       foreground => 'white',
	       font => '-b&h-lucida-medium-r-normal-*-*-100-*-*-p-*-iso8859-1');
};

############################################################################

sub new {

  my($proto, @args) = @_;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $self = $class->SUPER::new(@args);
  $self->{frozen} = 0;
  return $self;
}

############################################################################

sub freeze {

  my($self) = @_;
  $self->{frozen} = 1;
}

############################################################################

sub unfreeze {

  my($self) = @_;
  if ($self->{frozen} > 1) {
    $self->redraw();
  }
  $self->{frozen} = 0;
}

############################################################################

sub redraw {

  my($self) = @_;
  $self->ClearArea(0, 0, 0, 0, 1);
}

############################################################################

1;
