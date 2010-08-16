#!/usr/bin/env perl
package AberMUD::Object::Role::Getable;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Player;
use AberMUD::Mobile;

has weight => (
    is  => 'rw',
    isa => 'Int',
);

has size => (
    is  => 'rw',
    isa => 'Int',
);

has held_by => (
    is      => 'rw',
    isa     => 'AberMUD::Player|AberMUD::Mobile',
    clearer => '_stop_being_held',
);

has dropped_description => (
    is  => 'rw',
    isa => 'Str',
);

around on_the_ground => sub {
    my ($orig, $self) = @_;

    return 0 if $self->held_by;

    $self->$orig(@_);
};

1;

