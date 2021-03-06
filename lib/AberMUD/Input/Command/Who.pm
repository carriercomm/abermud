#!/usr/bin/env perl
package AberMUD::Input::Command::Who;
use AberMUD::OO::Commands;

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

command who => sub {
    my ($self, $e) = @_;
    my $output = "$blue_line\n";

    my @names       = $e->universe->player_names;
    my $num_players = @names;

    $output .= join(
        "\n"
        => map {
            sprintf('%-10s | %-50s',
                ucfirst(),
                ucfirst() . ' the Player'
            )
        } @names);

    $output .= "\n$blue_line\n";
    my $linking_verb = @names == 1 ? 'is' : 'are';
    my $noun         = @names == 1 ? 'player' : 'players';

    $output .= "There $linking_verb currently &+C$num_players&* $noun in the game.\n";

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
