# NAME

Amon2::Web::Dispatcher::RouterBoomWithAction - Amon2 + Router::Boom + (Before|After) actions

# SYNOPSIS

    # MyApp::Web::Dispatcher
    use Amon2::Web::Dispatcher::RouterBoomWithAction;
    use Module::Find qw/ useall /;

    useall('MyApp::Web::C');
    base('MyApp::Web::C');

    get '/' => [ 'Before#action1', 'Before#action2' ] => 'Root#index' => [ 'After#action1', 'After#action2' ];

    # MyApp::Web::C::Before
    sub action1 {
        my ($class, $c) = @_;
        ...
    }

    sub action2 {
        my ($class, $c) = @_;
        ...
    }

    # MyApp::Web::C::After
    sub action1 {
        my ($class, $c, $response) = @_;
        ...
        return $response;
    }

    sub action2 {
        my ($class, $c, $response) = @_;
        ...
        return $response;
    }

# DESCRIPTION

Amon2::Web::Dispatch::RouterBoomWithAction provide mechanism of before/acter action to Amon2's dispatcher.

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
