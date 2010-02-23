package AberMUD::Web::Templates::HTML;

use strict;
use warnings;
use parent 'Template::Declare::Catalyst';
use Template::Declare::Tags;

BEGIN {
    create_wrapper locations => sub {
        my $inner = shift;

        html {
            head {
                title { 'AberMUD::Web KiokuDB Management Interface' }
                link {
                    attr {
                        rel => 'stylesheet',
                        href => '/static/css/main.css',
                        type => 'text/css',
                        media => 'screen',
                        charset => 'utf-8',
                    }
                }
            }
            body {
                div {
                    attr { id => 'topmain'}
                    h1 { 'AberMUD - Locations' }
                }
                div {
                    attr { id => 'sidenav'}
                    'foo bar'
                }
                div {
                    attr { id => 'contentmain' };
                    $inner->();
                }
                div {
                    attr { id => 'footer' }
                    'No rights reserved.'
                }
            }
        };
    };
}

template 'locations.look' => sub {
    my $class = shift;
    my $vars     = shift;
    my $loc = $vars->{loc};

    locations {
        h2 { attr { id => 'loc_title' } $loc->title }
        p { attr { class => 'description' } $loc->description }
        form {
            attr {method => 'post', action => '/locations/new'};
            ul {
                attr { class => 'exits' };
                foreach my $exit (@{ $loc->directions }) {
                    li {
                        label {
                            attr { class => 'exit' }
                            b { ucfirst("$exit:")  }
                        };
                        if ($loc->$exit) {
                            my $id = $loc->$exit->world_id;
                            a {
                                attr { href => "/locations/look/$id" }
                                $loc->$exit->title
                            }
                        }
                        else {
                            my $id = $loc->world_id;
                            input {
                                attr {
                                    type  => 'submit',
                                    name  => "edit_${id}_$exit",
                                    value => 'Make an exit'
                                }
                            }
                        }
                    }
                }
            }
        }
    }
};

template 'locations.new' => sub {
    locations {
        h2 { "New Location" }
        label { 'Title: ' }
        input {
            attr {
                id   => 'new_title',
                type => 'text',
                name => "title",
            }
        } br {}
        label { 'Description: ' }
        textarea {
            attr {
                name => 'description',
                id   => 'new_description',
                rows => 5,
            }
        } br {}
        input {
            attr {
                type  => 'submit',
                name  => "submit",
                value => "Submit",
            }
        }
    }
};

=head1 NAME

AberMUD::Web::Templates::HTML - HTML templates for AberMUD::Web

=head1 DESCRIPTION

HTML templates for AberMUD::Web.

=head1 SEE ALSO

=over

=item L<Template::Declare>

=item L<AberMUD::Web::View::HTML>

=item L<AberMUD::Web>

=item L<Catalyst::View::TD>

=back

=head1 AUTHOR

jasonmay

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

