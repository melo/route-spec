#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Route::Spec;

my @test_cases = (
  { spec  => '/',
    names => [],

    test_against =>
      [{url => '/', matched => '/', args => {}}, {url => '/foo'},]
  },
);

for my $tc (@test_cases) {
  my $spec = $tc->{spec};
  my $r    = Route::Spec->new($spec);
  ok($r, "Got R::S for '$spec' spec");
  is($r->spec, $spec, '... expected spec()');
  ok($r->re, '... has a re()');
  is(ref($r->re), 'Regexp', '... of the expected type');

  my $en    = $tc->{names};
  my $en_c  = scalar @$en;
  my $names = $r->names;
  is(scalar(@$names), $en_c,
    '... Number of expected named captures correct ($en_c)');
  cmp_deeply($names, $en, '... and their names are ok too');

  for my $ma (@{$tc->{test_against}}) {
    my ($url, $matched, $args, $rest) = @$ma{qw(url matched args rest)};
    my $result;
    lives_ok sub { $result = $r->match($url) },
      "Match against '$url' lived to tell his story";

    if ($matched) {
      is($result->{matched}, $matched,
        "... found the expected match, '$matched'");
      cmp_deeply($result->{args}, $args,
        '... with the expected captured args');
      if (defined $rest) {
        is($result->{rest}, $rest,
          "... and the expected unmatched part, '$rest'");
      }
      else {
        ok(!defined($result->{result}), '... and we have a exact match');
      }
    }
    else {
      cmp_deeply($result, {}, '... and a sad story it is, without a match');
    }
  }
}


## Thats all folks!
done_testing();
