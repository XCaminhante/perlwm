#
# $Id: Property.pm,v 1.5 2004/02/16 10:41:21 rdw Exp $
# 

package PerlWM::X::Property;

############################################################################

use strict;
use warnings;

############################################################################
# icccm   http://tronche.com/gui/x/icccm)
# ewmh    http://freedesktop.org/standards/wm-spec/
# gnome   http://developer.gnome.org/doc/standards/wm/
# motif   http://lesstif.org/
############################################################################

my %BITS = 
  ( 
   # icccm
   WM_STATE => 
   { Withdrawn => 0,
     Normal => 1,
     Iconic => 3 },
   WM_SIZE_HINTS => 
   { USPositition	=> (1<<0),	    # user specified position
     USSize		=> (1<<1),	    # user specified size
     PPosition		=> (1<<2),	    # program specified position
     PSize		=> (1<<3),	    # program specified size
     PMinSize		=> (1<<4),	    # program specified min size
     PMaxSize		=> (1<<5),	    # program specified max size
     PResizeInc		=> (1<<6),	    # program specified resize incrs
     PAspect		=> (1<<7),	    # program specified min/max aspect
     PBaseSize		=> (1<<8),	    # program specified base size
     PWinGravity	=> (1<<9) },	    # program specified win gravity
   WM_HINTS =>
   { InputHint		=> (1<<0),	    # input model
     StateHint		=> (1<<1),	    # initial state
     IconPixmapHint	=> (1<<2),	    # icon pixmap
     IconWindowHint	=> (1<<3),	    # icon window
     IconPositionHint	=> (1<<4),	    # icon position
     IconMaskHint	=> (1<<5),	    # icon mask
     WindowGroupHint	=> (1<<6),	    # window_group
     MessageHint	=> (1<<7),	    # obsolete
     UrgencyHint	=> (1<<8) },	    # urgency
   
   # gnome
   _WIN_STATE => 
   { WIN_STATE_STICKY          => (1<<0),   # everyone knows sticky
     WIN_STATE_MINIMIZED       => (1<<1),   # Reserved - definition is unclear
     WIN_STATE_MAXIMIZED_VERT  => (1<<2),   # window in maximized V state
     WIN_STATE_MAXIMIZED_HORIZ => (1<<3),   # window in maximized H state
     WIN_STATE_HIDDEN          => (1<<4),   # not on taskbar but visible
     WIN_STATE_SHADED          => (1<<5),   # shaded
     WIN_STATE_HID_WORKSPACE   => (1<<6),   # not on current desktop
     WIN_STATE_HID_TRANSIENT   => (1<<7),   # owner of transient is hidden
     WIN_STATE_FIXED_POSITION  => (1<<8),   # window is fixed in position even
     WIN_STATE_ARRANGE_IGNORE  => (1<<9) }, # ignore for auto arranging
   _WIN_HINTS => 
   { WIN_HINTS_SKIP_FOCUS      => (1<<0),   # "alt-tab" skips this win
     WIN_HINTS_SKIP_WINLIST    => (1<<1),   # do not show in window list
     WIN_HINTS_SKIP_TASKBAR    => (1<<2),   # do not show on taskbar
     WIN_HINTS_GROUP_TRANSIENT => (1<<3),   # Reserved - definition is unclear
     WIN_HINTS_FOCUS_ON_CLICK  => (1<<4) }, # only accepts focus if clicked
   _WIN_LAYER =>
   { WIN_LAYER_DESKTOP         => 0,
     WIN_LAYER_BELOW           => 2,
     WIN_LAYER_NORMAL          => 4,
     WIN_LAYER_ONTOP           => 6,
     WIN_LAYER_DOCK            => 8,
     WIN_LAYER_ABOVE_DOCK      => 10,
     WIN_LAYER_MENU            => 12 },

   # motif (MwmUtil.h)
   _MOTIF_WM_HINTS =>
   { MWM_HINTS_FUNCTIONS       => (1<<0),
     MWM_HINTS_DECORATIONS     => (1<<1),
     MWM_HINTS_INPUT_MODE      => (1<<2),
     MWM_HINTS_STATUS	       => (1<<3) },
   MWM_HINTS_FUNCTIONS =>
   { MWM_FUNC_ALL	       => (1<<0),
     MWM_FUNC_RESIZE	       => (1<<1),
     MWM_FUNC_MOVE	       => (1<<2),
     MWM_FUNC_MINIMIZE	       => (1<<3),
     MWM_FUNC_MAXIMIZE         => (1<<4),
     MWM_FUNC_CLOSE            => (1<<5) },
   MWM_HINTS_DECORATIONS =>
   { MWM_DECOR_ALL	       => (1<<0),
     MWM_DECOR_BORDER	       => (1<<1),
     MWM_DECOR_RESIZEH         => (1<<2),
     MWM_DECOR_TITLE           => (1<<3),
     MWM_DECOR_MENU            => (1<<4),
     MWM_DECOR_MINIMIZE        => (1<<5),
     MWM_DECOR_MAXIMIZE        => (1<<6) },
   MWM_HINTS_INPUT_MODE =>
   { MWM_INPUT_MODELESS                   => 0,
     MWM_INPUT_PRIMARY_APPLICATION_MODAL  => 1,
     MWM_INPUT_SYSTEM_MODAL               => 2,
     MWM_INPUT_FILL_APPLICATION_MODAL     => 3 },
   MWM_HINTS_STATUS =>
   { MWM_TEAROFF_WINDOW        => (1<<0) },
  );

my %RBITS = map {($_ => {reverse %{$BITS{$_}}})} keys %BITS;

my %OFFSETS = 
  (
   WM_SIZE_HINTS =>
   { USPositition	=> [ 0, 2],	    # user specified position
     USSize		=> [ 2, 2],	    # user specified size
     PPosition		=> [ 0, 2],	    # program specified position
     PSize		=> [ 2, 2],	    # program specified size
     PMinSize		=> [ 4, 2],	    # program specified min size
     PMaxSize		=> [ 6, 2],	    # program specified max size
     PResizeInc		=> [ 8, 2],	    # program specified resize incrs
     PAspect		=> [10, 4],	    # program specified min/max aspect
     PBaseSize		=> [14, 2],	    # program specified base size
     PWinGravity	=>  16 },	    # program specified win gravity
   WM_HINTS =>
   { InputHint		=>  0,		    # input model
     StateHint		=>  1,		    # initial state
     IconPixmapHint	=>  2,		    # icon pixmap
     IconWindowHint	=>  3,		    # icon window
     IconPositionHint	=> [4, 2],	    # icon position
     IconMaskHint	=>  6,		    # icon mask
     WindowGroupHint	=>  7 },	    # window_group
   _MOTIF_WM_HINTS =>
   { MWM_HINTS_FUNCTIONS       => 0,
     MWM_HINTS_DECORATIONS     => 1,
     MWM_HINTS_INPUT_MODE      => 2,
     MWM_HINTS_STATUS	       => 3 },
   );

############################################################################

sub TIEHASH {

  my($class, $w) = @_;
  die unless $w->isa('PerlWM::X::Window');
  return bless { x => $w->{x}, id => $w->{id} }, $class;
}

############################################################################

sub STORE {

  my($self, $key, $value) = @_;
  my($type, $format, $data) = $self->encode_property($key, $value);
  $self->{x}->ChangeProperty($self->{id},
			     $self->{x}->atom($key),
			     $type, $format,
			     'Replace',
			     $data);
  $value;
}

############################################################################

sub FETCH {

  my($self, $key) = @_;
  return $self->{cache}->{$key} if exists $self->{cache}->{$key};
  my($data, $type, $format, $after, $value) = 
    $self->{x}->GetProperty($self->{id},
			    $self->{x}->atom($key),
			    'AnyPropertyType',
			    0, -1, 0);
  if ($type) {
    $value = $self->decode_property($key, $data, $type, $format, $after);
  }
  $self->{cache}->{$key} = $value;
}

############################################################################

sub FIRSTKEY {

  my($self) = @_;
  unless (exists $self->{cached_list}) {
    $self->{cached_list} = [$self->{x}->ListProperties($self->{id})];
  }
  $self->{list} = [@{$self->{cached_list}}];
  return undef unless @{$self->{list}};
  return $self->{x}->atom_name(shift @{$self->{list}});
}

############################################################################

sub NEXTKEY {

  my($self, $lastkey) = @_;
  return undef unless @{$self->{list}};
  return $self->{x}->atom_name(shift @{$self->{list}});
}

############################################################################

sub EXISTS {

  my($self, $key) = @_;
  return 1 if exists $self->{cache}->{$key};
  my($data, $type, $format, $after) = 
    $self->{x}->GetProperty($self->{id},
			    $self->{x}->atom($key),
			    'AnyPropertyType',
			    0, 0, 0);
  return $type ? 1 : undef;
}

############################################################################

sub DELETE {

  my($self, $key) = @_;
  if (exists $self->{cache}->{$key}) {
    $self->{x}->DeleteProperty($self->{id},
			       $self->{x}->atom($key));
    delete $self->{cache}->{$key};
  }
  else {
    my($data, $type, $format, $after) = 
      $self->{x}->GetProperty($self->{id},
			      $self->{x}->atom($key),
			      'AnyPropertyType',
			      0, -1, 1);
    return undef unless $type;
    $self->decode_property($key, $data, $type, $format, $after);
  }
}

############################################################################

sub CLEAR {

  my($self) = @_;
  $self->{cache} = {};
}

############################################################################

sub flush_cache {

  my($self, $atom, $reason) = @_;
  my $name = $self->{x}->atom_name($atom);
  # clearing our cache (probably because of a property notify)
  if ($reason eq 'Deleted') { 
    # property deleted on server - cache that
    $self->{cache}->{$name} = undef;
  }
  elsif (exists $self->{cache}->{$name}) {
    # property changed - clear cache
    delete $self->{cache}->{$name};
  }
  elsif (exists $self->{cached_list}) {
    # we hadn't cached this one - perhaps our cached list is out of date
    return if grep { $atom eq $_ } @{$self->{cached_list}};
    # wasn't in our cached list - flush that
    delete $self->{cached_list};
  }
}

############################################################################

sub encode_property {

  my($self, $key, $value) = @_;
  my($type, $format, $data);
  if ((ref($value) eq 'HASH') && 
      exists($value->{type}) && 
      exists($value->{value})) {
    $type = $value->{type};
    $value = $value->{value};
  }
  if ($key eq 'WM_STATE') {
    ($type, $format, $data) = 
      ('WM_STATE', 32,
       pack('L*', ($BITS{WM_STATE}->{$value->{state}} || 0, 
		   $value->{icon} || 0)));
  }
  else {
    use Carp qw(cluck); cluck "?";
    die "TODO: encode_property($key) - ".join(':',(caller())[1,2]);
  }
  $type = $self->{x}->atom($type);
  return ($type, $format, $data);
}

############################################################################

sub squash_list {

  my($one, @rest) = @_;
  return [$one, @rest] if @rest;
  return $one;
}

############################################################################

sub decode_property {

  my($self, $name, $data, $type, $format, $after) = @_;

  my $type_name = $self->{x}->atom_name($type);

  if ($type_name eq 'STRING') {
    return squash_list(split(/\x00/, $data));
  }
  elsif ($type_name eq 'UTF8_STRING') {
    use utf8;
    return squash_list(split(/\x00/, $data));
  }
  elsif ($type_name eq 'WINDOW') {
    return unpack('L', $data);
  }
  elsif ($type_name eq 'ATOM') {
    return squash_list(map($self->{x}->atom_name($_), unpack('L*', $data)));
  }
  elsif ($type_name =~ /^WM_/) {
    # icccm
    if ($type_name =~ /^WM_(?:SIZE_)?HINTS$/) {
      my($flags, @fields) = unpack('L*', $data);
      my $result = {};
      while (my($k, $v) = each %{$BITS{$type_name}}) {
	if ($flags & $v) {
	  if (my $offset = $OFFSETS{$type_name}->{$k}) {
	    if (ref $offset) {
	      $result->{$k} = [@fields[$offset->[0]..
				       ($offset->[0]+$offset->[1]-1)]];
	    }
	    else {
	      $result->{$k} = $fields[$offset];
	    }
	  }
	  else {
	    $result->{$k} = 1;
	  }
	}
      }
      return $result;
    }
    elsif ($type_name eq 'WM_STATE') {
      my($state, $icon) = unpack('L*', $data);
      return { state => ($RBITS{WM_STATE}->{$state} || $state),
	       icon => $icon };
    }
  }
  elsif ($name =~ /^_WIN_/) {
    # gnome 
    if ($name =~ /^(?:_WIN_STATE|_WIN_HINTS)$/) {
      my $flags = unpack('L', $data);
      my $result;
      while (my($k, $v) = each %{$BITS{$name}}) {
	$result->{$k} = 1 if $flags & $v;
      }
      return $result;
    }
    elsif ($name eq '_WIN_LAYER') {
      my $layer = unpack('L', $data);
      $layer = $RBITS{_WIN_LAYER}->{$layer} || $layer;
      return $layer;
    }
    elsif ($name eq '_WIN_AREA') {
      return [unpack('LL', $data)]; # (h,v)
    }
    elsif ($name eq '_WIN_WORKSPACE') {
      return unpack('L', $data);
    }
  }
  elsif ($type_name eq '_MOTIF_WM_HINTS') {
    # motif
    my($flags, @fields) = unpack('LLLLL', $data);
    my $result;
    while (my($k, $v) = each %{$BITS{_MOTIF_WM_HINTS}}) {
      if ($flags & $v) {
	(my $field = lc($k)) =~ s/^MWM_HINTS_//;
	my $value = @fields[$OFFSETS{_MOTIF_WM_HINTS}->{$k}];
	$result->{$k} = {};
	while (my($ik, $iv) = each %{$BITS{$k}}) {
	  $result->{$k}->{$ik} = 1 if $value & $iv;
	}
      }
    }
    return $result;
  }
  elsif ($name =~ /^_NET/) {
    # ewmh
    if ($name eq '_NET_WM_DESKTOP') {
      my $desktop = unpack('L', $data);
      $desktop = 'all' if $desktop == 0xffffffff;
      return $desktop;
    }
  }
  # unhandled stuff
  return { "UNKNOWN($type_name)" => squash_list(unpack('L*', $data)) };
}

############################################################################

1;
