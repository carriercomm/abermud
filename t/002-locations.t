#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Container;
use AberMUD::Zone;
use AberMUD::Input::State::Game;
use AberMUD::Config;
use AberMUD::Test::Sugar qw(build_preset_game);

my ($c, $locations) = build_preset_game('two_wide');
my $u = $c->resolve(service => 'universe');

sub player_logs_in {
    my $p = $c->resolve(service => 'player');
    $p->input_state([AberMUD::Input::State::Game->new]);

    $p->location($locations->{room1});
    $p->name(shift);
    $p->_join_game;
}

my $p = player_logs_in('myplayer');

my $look = $p->types_in('look');
like($look,  qr{Room One}, 'player sees location title');
like($look,  qr{first room}, 'player sees location description');
like($look,  qr{East\s*:\s+Room Two}, 'player sees location description');

like($p->types_in('east'),  qr{second}, 'player successfully goes east');

done_testing();
