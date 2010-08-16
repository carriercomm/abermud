#!/usr/bin/env perl
package AberMUD::Object;
use KiokuDB::Class;
use Moose::Util qw(apply_all_roles);;
use Data::Dumper;
use namespace::autoclean;

with qw(
    MooseX::Traits
    AberMUD::Role::InGame
);

has name => (
    is => 'rw',
    isa => 'Str',
);

has alt_name => (
    is => 'rw',
    isa => 'Str',
);

has buy_value => (
    is => 'rw',
    isa => 'Int',
);

has description => (
    is => 'rw',
    isa => 'Str',
);

has flags => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
);

has examine_description => (
    is => 'rw',
    isa => 'Str',
);

sub on_the_ground { } # overridden by roles

sub o_does {
    my $self = shift;
    my $base = shift;
    $self->does("AberMUD::Object::Role::$base");
}

__PACKAGE__->meta->make_immutable;

1;

