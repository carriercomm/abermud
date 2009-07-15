#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
extends 'MUD::Player';
use AberMUD::Server;
use POE::Wheel::ReadWrite;
use MooseX::Storage;
use Scalar::Util qw(weaken);
use Carp qw(cluck);

=head1 NAME

AberMUD::Player - AberMUD Player class for playing

=head1 SYNOPSIS

    my $player = AberMUD::Player->new;

    ...

    $player->save;

=head1 DESCRIPTION

AberMUD's player system is very straightforward. Each player has a connection
to the server. A player's location and inventory does not stay on that person
when he leaves the game. 

=cut

with Storage(format => 'YAML', 'io' => 'File');

has 'prompt' => (
    is  => 'rw',
    isa => 'Str'
);

has 'universe' => (
    is        => 'rw',
    isa       => 'AberMUD::Universe',
    weak_ref  => 1,
    traits => ['DoNotSerialize'],
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
);

has 'id' => (
    is        => 'rw',
    isa       => 'Int',
    traits => ['DoNotSerialize'],
);

has '+io' => (
    traits => ['DoNotSerialize'],
);

has '+input_state' => (
    traits => ['DoNotSerialize'],
);

sub unshift_state {
    my $self = shift;
    unshift @{$self->input_state}, @_;
}

sub shift_state {
    my $self = shift;
    shift @{$self->input_state};
}

sub in_game {
    my $self = shift;
    return exists($self->universe->players_in_game->{$self->name});
}

sub is_saved {
    my $self = shift;
    return -e('data/players/' . lc $self->name . '.yaml');
}

sub save_data {
    my $self = shift;

    cluck "Trying to call save when the player is not in-game"
        unless $self->in_game;

    $self->store('data/players/' . lc $self->name . '.yaml');
}

sub load_data {
    my $self = shift;

    my $load_file = 'data/players/' . lc $self->name . '.yaml';

    if ($self->is_saved) {
        my $player = AberMUD::Player->load($load_file);

        $player->$_($self->$_) for qw/id universe input_state io/;

        $self->universe->players->{$self->id} = $player;
        weaken($self->universe->players_in_game->{lc $self->name} = $player);
        return $player;
    }

    return $self;
}

sub disconnect {
    my $self = shift;
    my $id = $self->id;
    $self->io->shutdown_output;
    delete $self->universe->players->{$self->id};
    delete $self->universe->players_in_game->{$self->name}
        if exists $self->universe->players_in_game->{$self->name};
    print STDERR "DISconnection [$id] :(\n\n";
}

1;
