package Amon2::Web::Dispatch::RouterBoomWithAction;
use 5.008001;
use strict;
use warnings;
use Router::Boom::Method;

our $VERSION = "0.01";

sub import {
    my $class = shift;
    my %args = @_;
    my $caller = caller(0);

    my $router = Router::Boom::Method->new();
    my $base;

    no strict 'refs';

    *{"${caller}::base"} = sub { $base = $_[0] };

    # functions
    #
    # get( '/path', 'Controller#action')
    # post('/path', 'Controller#action')
    # delete_('/path', 'Controller#action')
    # any( '/path', 'Controller#action')
    # get( '/path', sub { })
    # post('/path', sub { })
    # delete_('/path', sub { })
    # any( '/path', sub { })
    for my $method (qw(get post delete_ any)) {
        *{"${caller}::${method}"} = sub {
            my ($path, @dests) = @_;

            my %dest;
            while (my $dest = shift @dests) {
                if (ref $dest eq 'ARRAY') {
                    for (@{ $dest }) {
                        my ($controller, $method) = split('#', $_);
                        $_ = +{};
                        $_->{class}  = $base ? "${base}::${controller}" : $controller;
                        $_->{method} = $method if defined $method;
                    }

                    if ($dest{code} || $dest{method}) {
                        $dest{after_dispatch} = $dest;
                    } else {
                        $dest{before_dispatch} = $dest;
                    }
                } elsif (ref $dest eq 'CODE') {
                    $dest{code} = $dest;
                } else {
                    my ($controller, $method) = split('#', $dest);
                    $dest{class}  = $base ? "${base}::${controller}" : $controller;
                    $dest{method} = $method if defined $method;
                }
            }

            my $http_method;
            if ($method eq 'get') {
                $http_method = ['GET','HEAD'];
            } elsif ($method eq 'post') {
                $http_method = 'POST';
            } elsif ($method eq 'delete_') {
                $http_method = 'DELETE';
            }

            $router->add($http_method, $path, \%dest);
        };
    }

    # class methods
    *{"${caller}::router"} = sub { $router };

    *{"${caller}::dispatch"} = sub {
        my ($class, $c) = @_;

        my $env = $c->request->env;
        if (my ($dest, $captured, $method_not_allowed) = $class->router->match($env->{REQUEST_METHOD}, $env->{PATH_INFO})) {
            if ($method_not_allowed) {
                return $c->res_405();
            }

            my $res = eval {
                if ($dest->{before_dispatch}) {
                    for (@{ $dest->{before_dispatch} }) {
                        my $method = $_->{method};
                        $c->{args} = $captured;
                        $_->{class}->$method($c, $captured);
                    }
                }

                my $response;
                if ($dest->{code}) {
                    $response = $dest->{code}->($c, $captured);
                } else {
                    my $method = $dest->{method};
                    $c->{args} = $captured;
                    $response = $dest->{class}->$method($c, $captured);
                }

                if ($dest->{after_dispatch}) {
                    for (@{ $dest->{after_dispatch} }) {
                        my $method = $_->{method};
                        $c->{args} = $captured;
                        $response = $_->{class}->$method($c, $response);
                    }
                }

                return $response;
            };
            if ($@) {
                if ($class->can('handle_exception')) {
                    return $class->handle_exception($c, $@);
                } else {
                    print STDERR "$env->{REQUEST_METHOD} $env->{PATH_INFO} [$env->{HTTP_USER_AGENT}]: $@";
                    return $c->res_500();
                }
            }
            return $res;
        } else {
            return $c->res_404();
        }
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Web::Dispatch::RouterBoomWithChain - It's new $module

=head1 SYNOPSIS

    use Amon2::Web::Dispatch::RouterBoomWithChain;

=head1 DESCRIPTION

Amon2::Web::Dispatch::RouterBoomWithChain is ...

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

