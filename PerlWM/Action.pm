#
# $Id: Action.pm,v 1.4 2004/05/23 14:27:01 rdw Exp $
#

package PerlWM::Action;

############################################################################

use strict;
use warnings;

use base qw(Exporter);

our(@EXPORT) = qw(action action_register action_alias);

############################################################################

my(%ACTION, %ACTION_ALIAS);

############################################################################

sub action_register {

  my($action, $spec) = @_;
  $spec ||= $action;
  if (ref($spec) eq 'CODE') {
    return $ACTION{$action} = $spec;
  }
  foreach ($spec, "${spec}::start",
	   "PerlWM::Action::Builtin::${spec}",
	   "PerlWM::Action::Builtin::${spec}::start") {
    next unless /^(.*)::([^:]+)$/;
    my($class, $method) = ($1, $2);
    if (my $code = eval qq{ require $class; 
			    $class->can('$method'); }) {
      return $ACTION{$action} = $code;
    }
    elsif ($@ && $@ !~ /Can\'t locate/) {
      warn "action_register: '$spec' - $@\n";
    }
  }
  warn "action_register: failed to find code for '$spec'\n" 
    unless $action eq $spec;
  return;
}

############################################################################

sub action_alias {

  my($alias, $action) = @_;
  $ACTION_ALIAS{$action} = $alias;
}

############################################################################

sub action {

  my($action) = @_;
  if (my $alias = $ACTION_ALIAS{$action}) {
    $action = $alias;
  }
  my $spec = $ACTION{$action} || action_register($action);
  if (!$spec) {
    my $dummy = sub { warn "action '$action' not defined\n" };
    $dummy->();
    sleep(1);
    return $dummy;
  }
  return $spec;
}

############################################################################

sub new {

  my($proto, %arg) = @_;
  my $class = ref($proto) || $proto || __PACKAGE__;
  my $self = bless { %arg }, $class;

  $self->{x} ||= $arg{event}->{x};

  die "need x" unless $self->{x};

  if ($self->{target}) {
    # finish any current action on this window
    if ($self->{target}->{action}) {
      $self->{target}->{action}->finish();
    }
    # remember we are in progress
    $self->{target}->{action} = $self;
    # overlay our event table
    $self->{target}->event_overlay_add($self);
  }

  if ($self->{grab}) {
    die "need target" unless $self->{target};
    if ($self->{grab} =~ /pointer/) {
      $self->{x}->GrabPointer($self->{target}->{id}, 0, 
			      scalar $self->{x}->event_window_mask($self),
			      'Asynchronous', 'Asynchronous',
			      'None', 'None', 'CurrentTime');

      die "grab pointer\n";
    }
    if ($self->{grab} =~ /keyboard/) {
      $self->{x}->GrabKeyboard($self->{target}->{id}, 0,
			       'Asynchronous', 'Asynchronous',
			       'CurrentTime');
    }
    # handy safety net
    if ($ENV{PERLWM_DEBUG}) {
      $SIG{ALRM} = sub { $self->cancel(); };
      alarm(20);
    }
  }

  return $self;
}

############################################################################

sub finish {

  my($self) = @_;
  # cancel the safety net
  alarm(0) if $ENV{PERLWM_DEBUG};
  $self->{target}->event_overlay_remove($self);
  $self->{target}->{action} = undef;
  if ($self->{grab}) {
    # undo any grabs
    if ($self->{grab} =~ /pointer/) {
      $self->{x}->UngrabPointer('CurrentTime');
    }
    if ($self->{grab} =~ /keyboard/) {
      $self->{x}->UngrabKeyboard('CurrentTime');
    }
  }
}

############################################################################

sub cancel {

  my($self) = @_;
  $self->finish();
}

############################################################################

sub OVERLAY { ( 'Key(Escape)' => 'cancel' ) }

############################################################################

1;

