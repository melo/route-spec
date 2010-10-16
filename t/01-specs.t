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
    parts => ['/'],
    test_against =>
      [{url => '/', matched => '/', args => {}}, {url => '/foo'}],
    url_for => [{url => '/', args => {}}, {url => '/', args => {x => 1}}],
  },

  { spec  => {spec => '/foo'},
    names => [],
    parts => ['/foo'],
    test_against =>
      [{url => '/'}, {url => '/foo', matched => '/foo', args => {}}],
    url_for => [
      {url => '/foo',     args => {}},
      {url => '/foo/bar', args => {x => 1}, rest => '/bar'},
    ],
  },

  { spec         => '/i/:name',
    names        => [qw(name)],
    parts        => ['/i/', \'name'],
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
      {url => '/i/sofia', args => {name => 'sofia'}},
      {url => '/i/maria', args => {name => 'maria', x => 1}},
    ],
  },

  { spec         => '/i/:type/:name',
    names        => [qw(type name)],
    parts        => ['/i/', \'type', '/', \'name'],
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
      {url => '/i/girl/sofia', args => {type => 'girl', name => 'sofia'}},
      { url  => '/i/boy/maria',
        args => {type => 'boy', name => 'maria', x => 1}
      },
    ],
  },

  { spec  => '/i/:type/:name/*/*.*',
    names => [qw(type name __splat__ __splat__ __splat__)],
    parts => [
      '/i/', \'type',      '/', \'name', '/', \'__splat__',
      '/',   \'__splat__', '.', \'__splat__',
    ],
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
    ],
    url_for => [
      { url => '/i/type/me/oh/my/awesome.pl',
        args =>
          {type => 'type', name => 'me', splat => ['oh/my', 'awesome', 'pl']}
      },
    ],
  },

  { spec  => '/i/:type/:name/*/{base:\D{3}\d{4}}.*',
    names => [qw(type name __splat__ base __splat__)],
    parts => [
      '/i/', \'type', '/', \'name',
      '/', \'__splat__', '/', ['base', '(\D{3}\d{4})'],
      '.', \'__splat__',
    ],
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
    ],
    url_for => [
      { url  => '/i/type/me/oh/my/qwe1234.pl',
        args => {
          type  => 'type',
          name  => 'me',
          base  => 'qwe1234',
          splat => ['oh/my', 'pl']
        }
      },
      { exception =>
          q{Bad argument 'oops' for name 'base': doesn't match /(\D{3}\d{4})/, },
        args => {
          type  => 'type',
          name  => 'me',
          base  => 'oops',
          splat => ['oh/my', 'pl']
        }
      },
    ],
  },

  { spec  => '/i/:type/:name/*/{base:\D{3}\d{4}}',
    names => [qw(type name __splat__ base)],
    parts => [
      '/i/', \'type', '/', \'name',
      '/', \'__splat__', '/', ['base', '(\D{3}\d{4})'],
    ],
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
    ],
    url_for => [
      { url  => '/i/type/me/oh/my/qwe1234/and/more',
        args => {
          type  => 'type',
          name  => 'me',
          base  => 'qwe1234',
          splat => ['oh/my']
        },
        rest => '/and/more',
      },
    ],
  }
);


for my $tc (@test_cases) {
  my $spec = $tc->{spec};
  my $r    = Route::Spec->new($spec);

  $spec = $spec->{spec} if ref $spec;
  ok($r, "Got R::S for '$spec' spec");
  is($r->spec, $spec, '... expected spec()');
  ok($r->re, '... has a re()');
  is(ref($r->re), 'Regexp', '... of the expected type');

  my $en    = $tc->{names};
  my $en_c  = scalar @$en;
  my $names = $r->names;
  is(scalar(@$names), $en_c,
    "... Number of expected named captures correct ($en_c)");
  cmp_deeply($names, $en, '... and their names are ok too');

  my $ep = $tc->{parts};
  my $ep_c  = scalar @$ep;
  my $parts = $r->parts;
  is(scalar(@$parts), $ep_c,
    "... Number of expected url parts correct ($ep_c)");
  cmp_deeply($parts, $ep, '... and their contents are ok too');

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
    }
  }

  for my $uf (@{$tc->{url_for}}) {
    my ($ex_url, $ex_excp, $args, $rest) = @$uf{qw(url exception args rest)};
    my $url = eval { $r->url_for($args, $rest) };
    if ($ex_url) {
      is($url, $ex_url, "... url_for() matches expected '$ex_url'");
    }
    elsif ($ex_excp) {
      my $e = $@;
      $ex_excp = quotemeta($ex_excp);
      like($@, qr/^$ex_excp/,
        'Failed to generate the URL with the proper exception');
    }
  }
}


## Bad boys
throws_ok sub { Route::Spec->new }, qr/Missing required parameter 'spec', /,
  'No spec, dies, take 1';
throws_ok sub { Route::Spec->new({}) },
  qr/Missing required parameter 'spec', /, 'No spec, dies, take 2';


## Thats all folks!
done_testing();
