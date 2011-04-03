#!/usr/bin/env perl
package AberMUD::Controller;
use Moose;
#use MooseX::POE;
extends 'MUD::Controller';
use AberMUD::Player;
use AberMUD::Mobile;
use AberMUD::Universe;
use AberMUD::Util;
use JSON;
use Data::UUID::LibUUID;
use DDS;

use Module::Pluggable
    search_path => ['AberMUD::Input::State'],
    sub_name    => '_input_states',
;

with qw(
    MooseX::Traits
);

has '+input_states' => (
    lazy    => 1,
    builder => '_build_input_states',
);

sub _build_input_states {
    my %input_states;
    foreach my $input_state_class ($controller->_input_states) {
        next unless $input_state_class;
        Class::MOP::load_class($input_state_class);
        my $input_state_object = $input_state_class->new(
            universe          => $self->universe,
            command_composite => $self->command_composite,
            special_composite => $self->special_composite,
        );

        $input_states{ $input_state_class } = $input_state_object;
    }

    return \%input_states;
}

around build_response => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $player = $self->universe->players->{$id};

    my $response = $self->$orig($id, @_);
    my $output;

    $output = "You are in a void of nothingness...\n"
        unless $player && @{$player->input_state};

    if ($player && ref $player->input_state->[0] eq 'AberMUD::Input::State::Game') {
        $player = $player->materialize;
        my $prompt = $player->final_prompt;
        $output = "$response\n$prompt";
    }
    else {
        $output = $response;
    }

    # sweep here

    return AberMUD::Util::colorify($output);
};

around connect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $result = $self->$orig(@_);

    return $result if $data->{param} ne 'connect';

    my $id = $data->{data}->{id};
    return +{
        param => 'output',
        data => {
            id    => $id,
            value => $self->connection($id)->input_state->entry_message,
        },
        txn_id => new_uuid_string(),
    }
};

before input_hook => sub {
    my $self = shift;
    my ($data) = @_;
};

around disconnect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $u = $self->universe;
    my $conn = $self->connection( $data->{data}{id} );
    if ($player && exists $u->players_in_game->{$player->name}) {
        $player->disconnect; # XXX tell players leaving the game,
                             #     then mark to disconnect

        #$u->broadcast($player->name . " disconnected.\n")
        #    unless $data->{data}->{ghost};

        $player->shift_state;
    }

    delete $u->players_in_game->{$player->name};
    my $result = $self->$orig(@_);

    return $result;
};

{
    # AberMUDs have a tick every two seconds
    my $two_second_toggle = 0;
    around tick => sub {
        my $orig = shift;
        my $self = shift;

        if ($two_second_toggle) {
            $self->universe->can('advance')
                && $self->universe->advance;
        }
        $two_second_toggle = !$two_second_toggle;
    };
}

sub materialize_player {
    my $self   = shift;
    my $player = shift;

    my $u = $self->universe;

    return $player if $player->in_game;

    my $m_player = $player->dir_player || $self;

    if ($m_player != $player && $m_player->in_game) {
        $self->ghost_player($m_player);
        return $self;
    }

    if (!$m_player->in_game) {
        $self->copy_unserializable_player_data($m_player, $player);
        $u->players->{$player->id} = $player;
    }

    $m_player->_join_game;
    $m_player->save_data if $m_player == $self;
    $m_player->setup;

    return $m_player;
}

sub dematerialize_payer {
    my $self   = shift;
    my $player = shift;
    delete $self->universe->players_in_game->{lc $player->name};
}

sub copy_unserializable_player_data {
    my $self = shift;
    my $source_player = shift;
    my $dest_player = shift;

    for ($source_player->meta->get_all_attributes) {
        if ($_->does('KiokuDB::DoNotSerialize')) {
            my $attr = $_->accessor;
            next if $attr eq 'dir_player';
            $dest_player->$attr($source_player->$attr)
                if defined $source_player->$attr;
        }
    }
}

sub ghost_player {
    my $self   = shift;
    my $new_player = shift;
    my $old_player = shift;
    my $u = $self->universe;

    return unless $old_player->id and $new_player->id;

    $u->_controller->force_disconnect($old_player->id, ghost => 1);
    $u->players->{$new_player->id} = delete $u->players->{$old_player->id};
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

AberMUD::Controller - Logic that coordinates gameplay and I/O

=head1 SYNOPSIS

  my $abermud = AberMUD::Controller->new(universe => $universe);

=head1 DESCRIPTION

This module is basically L<MUD::Controller> with some modifications
involving player actions and POE-related enhancements.

See L<MUD::Controller> documentation for more details on the functionality
of this module.

=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

You may use this code under the same terms of Perl itself.
