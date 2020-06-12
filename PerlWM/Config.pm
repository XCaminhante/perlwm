#
# $Id: Config.pm,v 1.1 2004/05/23 14:19:44 rdw Exp $
#

package PerlWM::Config;

############################################################################

use strict;
use warnings;

############################################################################

our $CONFIG = { default => { } };

############################################################################

sub new {

  my($proto, $path) = @_;
  my $class = ref($proto) || $proto || __PACKAGE__;
  my $self = { path => $path||'' };
  bless $self, $class;
  my $ref = $CONFIG;
  foreach my $part (split /\//, $self->{path}) {
    $ref->{$part} = { } unless exists $ref->{$part};
    $ref = $ref->{$part};
  }
  $self->{ref} = $ref;
  unless ($self->{path} =~ /^default/) {
    my $def = $CONFIG;
    foreach my $part (split /\//, $self->{path}) {
      $def->{$part} = { } unless exists $def->{$part};
      $def = $def->{$part};
    }
    $self->{def} = $ref;
  }
  return $self;
}

############################################################################

sub set {

  my($self, %value) = @_;

  while (my($k, $v) = each %value) {
    my $ref = $self->{ref};
    my @path = split /\//, $k;
    while (@path > 1) {
      my $bit = shift @path;
      $ref->{$bit} = { } unless exists $ref->{$bit};
      $ref = $ref->{$bit};
    }
    $ref->{shift @path} = $v;
  }
  return $self;
}

############################################################################

sub get {

  my($self, @arg) = @_;

  unless (ref($self)) {
    my $path = shift @arg;
    return $self->get_simple($path) unless @arg;
    $self = PerlWM::Config->new($path) 
  }

  my $value;
  if (@arg == 1) {
    if (ref($arg[0]) eq 'ARRAY') {
      $value = { map { $_ => undef } @{$arg[0]} };
    }
    elsif (ref($arg[0]) eq 'HASH') {
      $value = $arg[0];
    }
    elsif (ref($arg[0])) {
      die "unexpected ref";
    }
    else {
      $value->{$arg[0]} = undef;
    }
  }
  else {
    $value = { @arg };
  }
  my %result;
  while (my($k, $v) = each %{$value}) {
    if (exists $self->{ref}->{$k}) {
      $result{$k} = $self->{ref}->{$k};
    }
    elsif ($self->{def} && exists($self->{def}->{$k})) {
      $result{$k} = $self->{ref}->{$k};
    }
    else {
      $result{$k} = $v;
    }	
  }
  if (@arg == 1) {
    if (ref($arg[0]) eq 'ARRAY') {
      return map $result{$_}, @{$arg[0]};
    }
    elsif (ref($arg[0]) eq 'HASH') {
      return %result;
    }
    else {
      return $result{$arg[0]};
    }
  }
  else {
    return %result;
  }
}

############################################################################

sub get_simple {

  my($self, $path) = @_;
  my($ref, $def) = ($CONFIG, $CONFIG->{default});
  foreach my $part (split /\//, $path) {
    $ref = exists $ref->{$part} ? $ref->{$part} : { };
    return $ref unless ref $ref;
    $def = exists $def->{$part} ? $def->{$part} : { };
    return $def unless ref $def;
  }
  return undef;
}

############################################################################

sub load {

  my($self, $perlwm) = @_;
  require PerlWM unless $perlwm;
  $self = $self->new() unless ref $self;
  if (-d "$ENV{HOME}/.perlwm") {
    push @INC, "$ENV{HOME}/.perlwm";
    eval { 
      package config; 
      our($PerlWM) = $perlwm;
      our($config) = $self;
      require config; 
    };
    warn "Errors loading config - $@\n" if $@;
  }
  return $self;
}

############################################################################

sub save {

  my($self, %arg) = @_;

  my %save;
  my @todo = (['', $CONFIG->{default}], ['', $CONFIG]);
  while (my $item = shift @todo) {
    my($base, $tree) = @{$item};
    next if ($tree eq $CONFIG->{default}) && (!$arg{default});
    while (my($k, $v) = each %{$tree}) {
      next if $v eq $CONFIG->{default};
      if (ref($v) eq 'HASH') {
	push @todo, ["$base$k/", $v];
      }
      else {
	$save{"$base$k"} = $v;
      }
    }
  }
  die "no HOME?" unless $ENV{HOME};
  mkdir("$ENV{HOME}/.perlwm");
  if (open(CONFIG, ">$ENV{HOME}/.perlwm/config.pm")) {
    print CONFIG "# perlwm\n\n";
    print CONFIG "\$config->set(";
    print CONFIG join(",\n             ", 
		      map("'$_' => '$save{$_}'",
			  sort keys %save));
    print CONFIG ");\n\n1;\n";
    close(CONFIG);
  }
  else {
    warn "failed to open $ENV{HOME}/.perlwm for writing - $!";
  }	
}

############################################################################

1;
