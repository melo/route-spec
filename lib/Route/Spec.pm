package Route::Spec;

# ABSTRACT: route declaration, matching and reconstruction

use strict;
use warnings;
use parent 'Class::Accessor::Fast';
use Carp qw(confess);
use namespace::clean;

__PACKAGE__->mk_accessors(
  qw/spec re names parts element_re splat_re rest_re/);

sub new {
  my ($class, $spec) = @_;
  my $self = bless {
    element_re => '[^/]+',
    splat_re   => '.+',
    rest_re    => '/.*',
    ref($spec) ? %$spec : (spec => $spec)
  }, $class;

  confess("Missing required parameter 'spec', ")
    unless $self->spec;

  $self->_compile_spec_to_re;

  return $self;
}

sub match {
  my ($self, $url) = @_;
  my $re      = $self->re;
  my $rest_re = $self->rest_re;

  my @captured = $url =~ qr{^($re)($rest_re)?$};
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
      if (my $t = ref($_)) {
        if ($t eq 'ARRAY') {
          my $v = $args->{$_->[0]};
          confess("Bad argument '$v' for name '$_->[0]': doesn't match /$_->[1]/, ")
            unless $v =~ /^$_->[1]$/;
          $v;
        }
        else {
          $$_ eq '__splat__'
            ? $args->{splat}[$s++]
            : $args->{$$_}
        }
      }
      else {
        $_
      }
    } @{$self->{parts}}
  );

  $url .= $rest if $rest;

  return $url;
}

sub _compile_spec_to_re {
  my ($self)     = @_;
  my $spec       = $self->spec;
  my $element_re = $self->element_re;
  my $splat_re   = $self->splat_re;

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
          
          $pattern = $pattern ? "($pattern)" : "($element_re)";
          push @$parts, [$name, $pattern];
          $pattern;
        }
        elsif ($2) {
          my $name = $2;
          push @$names, $name;
          push @$parts, \$name;
          "($element_re)";
        }
        elsif ($3) {
          my $name = '__splat__';
          push @$names, $name;
          push @$parts, \$name;
          "($splat_re)";
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
