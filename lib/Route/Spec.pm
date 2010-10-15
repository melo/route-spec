package Route::Spec;

# ABSTRACT: route declaration, matching and reconstruction

use strict;
use warnings;
use parent 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/spec re names/);

sub new {
  my ($class, $spec) = @_;
  my $self = bless { spec => $spec }, $class;
  
  $self->_compile_spec_to_re;
  
  return $self;
}

sub match {
  my ($self, $url) = @_;
  my $re = $self->{re};

  my @captured = $url =~ qr{^($re)(/.*)?$};
  return {} unless @captured;
  
  my $all = shift @captured;
  my $rest = pop @captured;
  my $names = $self->{names};
  my %args;
  my @splat;
  while (@captured) {
    my $n = shift @$names;
    if ($n eq '__splat__') {
      push @splat, shift @captured;
    }
    else {
      $args{$n} = shift @captured;
    }
  }

  return {
    matched => $all,
    args => {
      %args,
      ( @splat ? ( splat => \@splat ) : () ),
    },
    rest => $rest,
  };
}

sub _compile_spec_to_re {
  my ($self) = @_;
  my $spec = $self->spec;
  
  # compile pattern
  my $names = $self->{names} = [];
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
          $pattern ? "($pattern)" : "([^/]+)";
        }
        elsif ($2) {
          push @$names, $2;
          "([^/]+)";
        }
        elsif ($3) {
          push @$names, '__splat__';
          "(.+)";
        }
        else {
          quotemeta($4);
        }
    !gex;
    qr{$spec};
  };
  
  return;
}

1;
