#
# $Id: Search.pm,v 1.6 2004/05/23 14:23:20 rdw Exp $
#

package PerlWM::Action::Search;

############################################################################

use strict;
use warnings;
use base qw(PerlWM::Action);

use PerlWM::Config;

############################################################################

BEGIN {
  my $popup = PerlWM::Config->new('default/search/popup');
  $popup->set('border' => '#00ff00',
	      'background' => '#000000',
	      'input' => '#eeeeee',
	      'match' => '#8080ff',
	      'select' => '#00ff00',
	      'font' => '-b&h-lucida-medium-r-normal-*-*-100-*-*-p-*-iso8859-1');

  my $frame = PerlWM::Config->new('default/search/frame');
  $frame->set(match => '#8080ff',
	      select => '#00ff00',
	      nomatch => '#ffffff',
	      focus => '#ff0000');
};

############################################################################

sub start {

  my($target, $event) = @_;
  my $self = __PACKAGE__->SUPER::new(target => $target,
				     event => $event,
				     grab => 'keyboard');

  $self->{text} = '';
  $self->{select} = 0;
  $self->{case_insensitive} = 1;
  $self->{frames} = $target->{perlwm}->{frames};
  $self->{match} = [@{$self->{frames}}];

  $self->{popup} = PerlWM::Action::Search::Popup->new
    (x => $target->{x}, search => $self);
  $self->{popup}->update();

  return $self;
}

############################################################################

sub highlight_frame {

  my($self, $frame, $type, $itype) = @_;
  return unless my $color = $self->{x}->color_get("search/frame/$type");
  $itype ||= $type;
  return unless my $icolor = $self->{x}->color_get("search/frame/$itype");
  $frame->ChangeWindowAttributes(background_pixel => $color);
  $frame->ClearArea();
  if ($frame->{icon}) {
    $frame->{icon}->ChangeWindowAttributes(background_pixel => $icolor);
    $frame->{icon}->ClearArea();
  }
}

############################################################################

sub finish {

  my($self) = @_;
  $self->highlight_frame($_, 'nomatch') for @{$self->{frames}};
  $self->{popup}->UnmapWindow();
  $self->{popup}->DestroyWindow();
  $self->SUPER::finish();
}

############################################################################

sub show {

  my($self) = @_;

  my %seen;
  for (my $index = 0; $index <= $#{$self->{match}}; $index++) { 
    my $frame = $self->{match}->[$index];
    my $type = ($index == $self->{select} ? 'select' : 'match');
    $self->highlight_frame($frame, $type);
    $seen{$frame->{id}}++;
  }
  foreach my $frame (@{$self->{frames}}) {
    next if $seen{$frame->{id}};
    $self->highlight_frame($frame, 'nomatch');
  }
  $self->{popup}->update();
}

############################################################################

sub search {

  my($self) = @_;
  my $regexp = ($self->{case_insensitive} 
		? eval { qr/$self->{text}/i }
		: eval { qr/$self->{text}/ });
  unless ($self->{error} = $@) {
    $self->{match} = [ grep $_->{name} =~ $regexp, @{$self->{frames}} ];
    my $max = $#{$self->{match}};
    $self->{select} = $max if $self->{select} > $max;
    $self->{select} = 0 if $max == -1;
  }
  $self->show();
}

############################################################################

sub key {

  my($self, $event) = @_;
  my $string = $event->{string};
  # ignore special keys
  return unless $string && (length($string) eq 1);
  $self->{text} .= $event->{string};
  $self->search();
}

############################################################################

sub backspace {

  my($self, $event) = @_;
  return unless length($self->{text});
  $self->{text} = substr($self->{text}, 0, length($self->{text}) - 1);
  $self->search();
}

############################################################################

sub up_down {

  my($self, $event) = @_;
  if ($event->{string} eq 'Up') {
    $self->{select}--;
  }
  elsif ($event->{string} eq 'Down') {
    $self->{select}++;
  }
  my $max = $#{$self->{match}};
  $self->{select} = $max if $self->{select} < 0;
  $self->{select} = 0 if $self->{select} > $max;
  $self->show();
}

############################################################################

sub toggle_case {

  my($self) = @_;
  $self->{case_insensitive} = !$self->{case_insensitive};
  $self->search();
}

############################################################################

sub enter {

  my($self) = @_;
  $self->finish();
  if (my $select = $self->{match}->[$self->{select}]) {
    $select->deiconify();
    $select->ConfigureWindow(stack_mode => 'Above');
    $self->highlight_frame($select, 'focus', 'nomatch');
    $select->warp_to([-10, 10]);
    $select->enter();
  }
}

############################################################################

sub OVERLAY { ( __PACKAGE__->SUPER::OVERLAY,
		
		'Key(Any)' => 'key',
		'Key(Backspace)' => 'backspace',
		'Key(Up)' => 'up_down',
		'Key(Down)' => 'up_down',
		'Key(Control i)' => 'toggle_case',
		'Key(Enter)' => 'enter') }

############################################################################

package PerlWM::Action::Search::Popup;

use strict;
use warnings;
use base qw(PerlWM::X::Window);

############################################################################

sub new {

  my($proto, %arg) = @_;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $self = $class->SUPER::new(%arg);

  die unless my $x = $self->{x};

  $self->create(x => 2, y => 2,
		# TODO: what width? (auto resize?)
		width => 100, 
		height => 1,
		border_width => 2,
		background_pixel => $x->color_get('search/popup/background'),
		border_pixel => $x->color_get('search/popup/border'));

  my $font_info = $x->font_info('search/popup/font');

  $self->{ascent} = $font_info->{font_ascent};
  $self->{descent} = $font_info->{font_descent};
  $self->{font} = $x->font_get('search/popup/font');

  $self->{padding} = 2;
  $self->{row_height} = (($self->{ascent} + $self->{descent}) + 
			 (2 * $self->{padding}));

  $self->{rows_max} = 10;

  $self->{rows} = 0;

  return $self;
}

############################################################################

sub update {

  my($self) = @_;
  my $rows = scalar @{$self->{search}->{match}} + 1;
  $rows = $self->{rows_max} if $rows > $self->{rows_max};
  if ($rows != $self->{rows}) {
    $self->ConfigureWindow(height => $self->{row_height} * $rows);
    $self->MapWindow() unless $self->{rows};
    $self->{rows} = $rows;
  }
  $self->draw();
}

############################################################################

sub draw {

  my($self) = @_;

  $self->ClearArea();

  return unless my $search = $self->{search};

  unless ($self->{gc}) {
    foreach (qw(input match select)) {
      $self->{gc}->{$_} = 
	$self->{x}->gc_get("search/popup/$_", 
			   { font => 'search/popup/font',
			     foreground => "search/popup/${_}",
			     background => 'search/popup/background' } );
    }
  }

  my $y = $self->{padding} + $self->{ascent};
  if ($search->{text}) {
    $self->PolyText8($self->{gc}->{input},
		     $self->{padding}, $y,
		     [0, $search->{text}]);
  }
  for (my $index = 0; $index <= $#{$search->{match}}; $index++) { 
    $y += $self->{row_height};
    my $type = ($index == $search->{select} ? 'select' : 'match');
    $self->PolyText8($self->{gc}->{$type},
		     $self->{padding}, $y,
		     [0, $search->{match}->[$index]->{name}]);
  }
}

############################################################################

sub EVENT { (__PACKAGE__->SUPER::EVENT,
	     'Expose' => 'draw') }

############################################################################

1;
