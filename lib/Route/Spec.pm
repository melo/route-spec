package Route::Spec;

# ABSTRACT: route declaration, matching and reconstruction

use strict;
use warnings;
use parent 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/spec re names parts/);

sub new {
  my ($class, $spec) = @_;
  my $self = bless {spec => $spec}, $class;

  $self->_compile_spec_to_re;

  return $self;
}

sub match {
  my ($self, $url) = @_;
  my $re = $self->{re};

  my @captured = $url =~ qr{^($re)(/.*)?$};
  return {} unless @captured;

  my $all   = shift @captured;
  my $rest  = pop @captured;
  my $names = $self->{names};

  my %args;
  my @splat;
  my $i = 0;
  while (@captured) {
    my $n = $names->[$i++];
    if ($n eq '__splat__') {
      push @splat, shift @captured;
    }
    else {
      $args{$n} = shift @captured;
    }
  }

  return {
    matched => $all,
    args    => {%args, (@splat ? (splat => \@splat) : ()),},
    rest    => $rest,
  };
}

sub url_for {
  my ($self, $args, $rest) = @_;
  my $s = 0;

  my $url = join(
    '',
    map {
          ref($_)
        ? $$_ eq '__splat__'
          ? $args->{splat}[$s++]
          : $args->{$$_}
        : $_
      } @{$self->{parts}}
  );

  $url .= $rest if $rest;

  return $url;
}

sub _compile_spec_to_re {
  my ($self) = @_;
  my $spec = $self->spec;

  # compile pattern
  my $names = $self->{names} = [];
  my $parts = $self->{parts} = [];
  $self->{re} = do {
    $spec =~ s!
        \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
        :([A-Za-z0-9_]+)              | # /blog/:year
        (\*)                          | # /blog/*/*
        ([^{:*]+)                       # normal string
    !
        if ($1) {
          my ($name, $pattern) = split /:/, $1, 2;
          push @$names, $name;
          push @$parts, \$name;
          $pattern ? "($pattern)" : "([^/]+)";
        }
        elsif ($2) {
          my $name = $2;
          push @$names, $name;
          push @$parts, \$name;
          "([^/]+)";
        }
        elsif ($3) {
          my $name = '__splat__';
          push @$names, $name;
          push @$parts, \$name;
          "(.+)";
        }
        else {
          push @$parts, $4;
          quotemeta($4);
        }
    !gex;
    qr{$spec};
  };

  return;
}

1;
