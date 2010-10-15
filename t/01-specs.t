#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Route::Spec;

my $r = Route::Spec->new('/');
ok($r, "Got R::S for '/' spec");
is($r->spec, '/', '... expected pattern()');
ok($r->re, '... has a pattern_re()');
is(ref($r->re), 'Regexp', '... of the expected type');

my $names = $r->names;
is(scalar(@$names), 0, '... Number of expected named captures correct (0)');
cmp_deeply($names, [], '... and their names are ok too') if @$names;

for my $tc ({ url => '/', matched => 1, args => {} }) {
  my $result;
  lives_ok sub { $result = $r->match($tc->{url}) }, "Match with test case '/'";
  if ($tc->{matched}) {
    ok($result->{matched}, '... found a match');
    is($result->{matched}, '/', '... for the expected part of the url');
    cmp_deeply($result->{args}, $tc->{args}, '... with the expected captured args');
  }
}

## Thats all folks!
done_testing();
