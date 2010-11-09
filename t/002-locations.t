#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
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

my $one = player_logs_in('playerone');
my $two = player_logs_in('playertwo');

like($one->types_in('look'),  qr{playertwo is standing here}i);
like($one->types_in('east'),  qr{second});
like($two->get_output,        qr{playerone goes east}i);
like($two->types_in('east'), qr{playerone is standing here}i);
like($one->get_output,        qr{playertwo arrives from the west}i);

$one->types_in('west');
$one->types_in('east');

like($two->get_output, qr{playerone goes west});
like($two->get_output, qr{playerone arrives from the west});
