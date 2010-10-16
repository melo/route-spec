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
      [{url => '/', matched => '/', args => {}}, {url => '/foo'}],
    url_for => [{'/' => {}}, {'/' => {x => 1}},],
  },

  { spec  => '/foo',
    names => [],
    test_against =>
      [{url => '/'}, {url => '/foo', matched => '/foo', args => {}}]
  },

  { spec         => '/i/:name',
    names        => [qw(name)],
    test_against => [
      {url => '/i'},
      {url => '/i/foo', matched => '/i/foo', args => {name => 'foo'}},
      { url     => '/i/foo/bar',
        matched => '/i/foo',
        args    => {name => 'foo'},
        rest    => '/bar'
      },
    ],
    url_for => [
      {'/i/sofia' => {name => 'sofia'}},
      {'/i/maria' => {name => 'maria', x => 1}},
    ],
  },

  { spec         => '/i/:type/:name',
    names        => [qw(type name)],
    test_against => [
      {url => '/i'},
      {url => '/i/foo'},
      { url     => '/i/t/n',
        matched => '/i/t/n',
        args    => {name => 'n', type => 't'}
      },
      { url     => '/i/foo/bar',
        matched => '/i/foo/bar',
        args    => {type => 'foo', name => 'bar'},
      },
      { url     => '/i/foo/bar/more',
        matched => '/i/foo/bar',
        args    => {type => 'foo', name => 'bar'},
        rest    => '/more',
      },
    ],
    url_for => [
      {'/i/girl/sofia' => {type => 'girl', name => 'sofia'}},
      {'/i/boy/maria'  => {type => 'boy',  name => 'maria', x => 1}},
    ],
  },

  { spec         => '/i/:type/:name/*/*.*',
    names        => [qw(type name __splat__ __splat__ __splat__)],
    test_against => [
      {url => '/i'},
      {url => '/i/foo'},
      {url => '/i/t/n'},
      {url => '/i/t/n/l'},
      { url     => '/i/t/n/1/2.3',
        matched => '/i/t/n/1/2.3',
        args    => {type => 't', name => 'n', splat => [1, 2, 3]},
      },
      { url     => '/i/t/n/-1/0/1/2.3',
        matched => '/i/t/n/-1/0/1/2.3',
        args    => {type => 't', name => 'n', splat => ['-1/0/1', 2, 3]},
      },
    ]
  },

  { spec         => '/i/:type/:name/*/{base:\D{3}\d{4}}.*',
    names        => [qw(type name __splat__ base __splat__)],
    test_against => [
      {url => '/i'},
      {url => '/i/foo'},
      {url => '/i/t/n'},
      {url => '/i/t/n/l'},
      {url => '/i/t/n/1/2.3'},
      {url => '/i/t/n/classic/aaa20123.xml'},
      {url => '/i/t/n/classic/aa20123.xml'},
      { url     => '/i/t/n/classic/aaa2012.xml',
        matched => '/i/t/n/classic/aaa2012.xml',
        args    => {
          type  => 't',
          name  => 'n',
          base  => 'aaa2012',
          splat => ['classic', 'xml']
        },
      },
      { url     => '/i/t/n/-1/0/1/bbb1122.3',
        matched => '/i/t/n/-1/0/1/bbb1122.3',
        args    => {
          type  => 't',
          name  => 'n',
          base  => 'bbb1122',
          splat => ['-1/0/1', '3']
        },
      },
      { url     => '/i/t/n/-1/0/1/bbb1122.3/4/5/6',
        matched => '/i/t/n/-1/0/1/bbb1122.3/4/5/6',
        args    => {
          type  => 't',
          name  => 'n',
          base  => 'bbb1122',
          splat => ['-1/0/1', '3/4/5/6']
        },
      },
    ]
  },

  { spec         => '/i/:type/:name/*/{base:\D{3}\d{4}}',
    names        => [qw(type name __splat__ base)],
    test_against => [
      {url => '/i'},
      {url => '/i/foo'},
      {url => '/i/t/n'},
      {url => '/i/t/n/l'},
      {url => '/i/t/n/1/2.3'},
      {url => '/i/t/n/classic/aaa20123.xml'},
      {url => '/i/t/n/classic/aa20123.xml'},
      {url => '/i/t/n/classic/aaa2012.xml'},
      {url => '/i/t/n/classic/aaa2012.xml'},
      { url     => '/i/t/n/-1/0/1/bbb1122/3',
        matched => '/i/t/n/-1/0/1/bbb1122',
        args    => {
          type  => 't',
          name  => 'n',
          base  => 'bbb1122',
          splat => ['-1/0/1'],
        },
        rest => '/3',
      },
      { url     => '/i/t/n/-1/0/1/bbb1122/3/4/5/6',
        matched => '/i/t/n/-1/0/1/bbb1122',
        args    => {
          type  => 't',
          name  => 'n',
          base  => 'bbb1122',
          splat => ['-1/0/1'],
        },
        rest => '/3/4/5/6',
      },
    ]
  }
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
      is($r->url_for($args, $rest),
        $url, "... and url_for() reverts the process fine");
    }
    else {
      cmp_deeply($result, {}, '... and a sad story it is, without a match');

#      use Data::Dump qw(pp); print STDERR ">>>>>> ", pp($result), "\n";
    }
  }

  for my $uf (@{$tc->{url_for}}) {
    my ($ex, $args) = %$uf;
    is($r->url_for($args), $ex, "... url_for() matches expected '$ex'");
  }
}


## Thats all folks!
done_testing();
