#
# $Id: GC.pm,v 1.1.1.1 2002/07/07 11:49:48 rdw Exp $
# 

package PerlWM::X::GC;

############################################################################

use strict;
use warnings;

use Storable qw(thaw);

############################################################################

sub gc_init {
  
  my($self) = @_;

  $self->object_add('gc', 'default', {});

  return { create => \&gc_create };
}

############################################################################

sub gc_create {

  my($self, $spec) = @_;
  
  $spec = thaw($spec) unless ref $spec;
  
  my %args;
  $args{font} = $self->font_get($spec->{font}) if $spec->{font};
  $args{foreground} = $self->color_get($spec->{foreground}) if $spec->{foreground};
  $args{background} = $self->color_get($spec->{background}) if $spec->{foreground};

  my $id = $self->new_rsrc;
  $self->CreateGC($id, $self->root, %args);
  return $id;
}

############################################################################

1;

