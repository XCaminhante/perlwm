#
# $Id: Object.pm,v 1.2 2004/05/23 14:20:53 rdw Exp $
# 

package PerlWM::X::Object;

############################################################################

use strict;
use warnings;

use Storable qw(freeze);

use PerlWM::Config;

############################################################################

sub object_init {

  my($self) = @_;

  foreach my $type (qw(color font gc image)) {
    $self->{name}->{$type} = { spec => { }, id => { }, info => { } };
    $self->{spec}->{$type} = { id => { }, info => { } };
    $self->{id}->{$type} = { info => { } };
    eval qq { sub ${type}_add  { shift->object_add ('$type', \@_) } };
    eval qq { sub ${type}_get  { shift->object_get ('$type', \@_) } };
    eval qq { sub ${type}_info { shift->object_info('$type', \@_) } };
    $self->{objfn}->{$type} = eval qq{ \$self->$type\_init() };
  }
}

############################################################################

sub object_add {

  my($self, $type, $name, $spec, $id, $info) = @_;

  $spec = freeze($spec) if ref $spec;

  if ($spec) {
    $self->{name}->{$type}->{spec}->{$name} = $spec if $name;
    if ($id) {
      $self->{name}->{$type}->{id}->{$name} = $id if $name;
      $self->{spec}->{$type}->{id}->{$spec} = $id;
      if ($info) {
	$self->{name}->{$type}->{info}->{$name} = $info if $name;
	$self->{spec}->{$type}->{info}->{$spec} = $info;
	$self->{id}->{$type}->{info}->{$id} = $info;
      }
    }
  }
}

############################################################################

sub object_get {

  my($self, $type, $name, $spec) = @_;

  $spec = freeze($spec) if ref $spec;

  my $id;
  if ($name && defined($id = $self->{name}->{$type}->{id}->{$name})) {
    # already created it via this name
    return $id;
  }
  else {
    # look up the spec
    $spec ||= $self->{name}->{$type}->{spec}->{$name} if $name;
    if ((!$spec) && ($type ne 'gc')) {
      # nothing there - try the config
      $spec = PerlWM::Config->get($name);
      # save it for next time
      $self->object_add($type, $name, $spec);
    }
    if (!$spec) {
      # still no spec found - look for a 'default' for this type
      $spec =  $self->{name}->{$type}->{spec}->{default};
      die "no spec for $type/$name, no default either\n" unless $spec;
    }
    if (defined($id = $self->{spec}->{$type}->{id}->{$spec})) {
      # already created this spec - add to name cache
      $self->{name}->{$type}->{id}->{$name} = $id if $name;
      return $id;
    }
    else {
      # need to create it
      my $create = $self->{objfn}->{$type}->{create};
      die "unable to create object of type $type\n" unless $create;
      my $info;
      ($id, $info) = $create->($self, $spec);
      die "creation of $type/$name failed\n" unless defined($id);
      # cache this in the spec and name caches
      $self->{spec}->{$type}->{id}->{$spec} = $id;
      $self->{name}->{$type}->{id}->{$name} = $id if $name;
      # info comes at creation - cache it
      if ($info) {
	$self->{id}->{$type}->{info}->{$id} = $info;
	$self->{spec}->{$type}->{info}->{$spec} = $info;
	$self->{name}->{$type}->{info}->{$name} = $info if $name;
      }
      return $id;
    }
  }
}

############################################################################

sub object_info {

  my($self, $type, $name) = @_;

  my $info;
  if ($info = $self->{name}->{$type}->{info}->{$name}) {
    # already got info via this name
    return $info;
  }
  else {
    # look up the spec
    my $spec = $self->{name}->{$type}->{spec}->{$name};
    if ((!$spec) && ($type ne 'gc')) {
      # nothing there - try the config
      $spec = PerlWM::Config->get($name);
      # save it for next time
      $self->object_add($type, $name, $spec);
    }
    if (!$spec) {
      # still no spec found - look for a 'default' for this type
      $spec =  $self->{name}->{$type}->{spec}->{default};
      die "no spec for $type/$name, no default either\n" unless $spec;
    }
    if ($info = $self->{spec}->{$type}->{info}->{$spec}) {
      # already got info via this spec - add to name cache
      $self->{name}->{$type}->{info}->{$name} = $info;
      return $info;
    }
    else {
      my $id = $self->{spec}->{$type}->{id}->{$spec};
      unless (defined($id)) {
	# not yet created it
	$id = $self->object_get($type, $name);
	die "cannot get object for $type/$name\n" unless defined($id);
      }
      # need to get the info it
      my $info = $self->{objfn}->{$type}->{info};
      die "unable to get info for object of type $type\n" unless $info;
      $info = $info->($self, $id);
      die "get info of $type/$name failed\n" unless $info;
      # cache this in the spec and name caches
      $self->{spec}->{$type}->{info}->{$spec} = $info;
      $self->{name}->{$type}->{info}->{$name} = $info;
      return $info;
    }
  }
}

############################################################################

sub object_dump {

  my($self) = @_;

  require Data::Dumper;
  my @fields = qw(name spec);
  my $dd = Data::Dumper->new([@{$self}{@fields}], \@fields)->Indent(1);
  print STDERR $dd->Dump();
}

############################################################################

1;
