use strict;
use warnings;
use utf8;
use Test::More 0.98;

use Amon2::Web::Dispatcher::RouterBoomWithAction;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

our $ACTION;

{
    package MyApp;
    use parent qw/ Amon2 /;
}
{
    package MyApp::Web;

    use parent -norequire, qw/ MyApp /;
    use parent qw/ Amon2::Web /;
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
}
{
    package MyApp::Web::C;
    sub before1 { push @$ACTION, 'before1' }
    sub before2 { push @$ACTION, 'before2' }
    sub before3 { push @$ACTION, 'before3'; return Amon2->context->create_response(200, [], 'before3') }
    sub after1 { push @$ACTION, 'after1' }
    sub after2 { push @$ACTION, 'after2' }
    sub after3 { push @$ACTION, 'after3'; return Amon2->context->create_response(200, [], 'after3') }
    sub root { push @$ACTION, 'root'; return Amon2->context->create_response(200, [], 'root') }
}
{
    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterBoomWithAction;
    base 'MyApp::Web';

    get '/1' => 'C#root';
    get '/2' => ['C#before1', 'C#before2'] => 'C#root';
    get '/3' => 'C#root' => ['C#after1', 'C#after2'];
    get '/4' => ['C#before1', 'C#before2'] => 'C#root' => ['C#after1', 'C#after2'];
    get '/5' => ['C#before1', 'C#before2', 'C#before3'] => 'C#root' => ['C#after1', 'C#after2'];
    get '/6' => ['C#before1', 'C#before2'] => 'C#root' => ['C#after1', 'C#after2', 'C#after3'];
}

my $app = MyApp::Web->to_app;
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);

subtest '1: root' => sub {
    $ACTION = [];
    $mech->get_ok('/1');
    $mech->content_is('root');
    is_deeply $ACTION, [qw/ root /];
};
subtest '2: before1 -> before2 -> root' => sub {
    $ACTION = [];
    $mech->get_ok('/2');
    $mech->content_is('root');
    is_deeply $ACTION, [qw/ before1 before2 root /];
};
subtest '3: root -> after1 -> after2' => sub {
    $ACTION = [];
    $mech->get_ok('/3');
    $mech->content_is('root');
    is_deeply $ACTION, [qw/ root after1 after2 /];
};
subtest '4: root -> after1 -> after2' => sub {
    $ACTION = [];
    $mech->get_ok('/4');
    $mech->content_is('root');
    is_deeply $ACTION, [qw/ before1 before2 root after1 after2 /];
};
subtest '5: before1 -> before2 -> before3 (-> root -> after1 -> after2)' => sub {
    $ACTION = [];
    $mech->get_ok('/5');
    $mech->content_is('before3');
    is_deeply $ACTION, [qw/ before1 before2 before3 /];
};
subtest '6: before1 -> before2 -> root -> after1 -> after2 -> after3' => sub {
    $ACTION = [];
    $mech->get_ok('/6');
    $mech->content_is('after3');
    is_deeply $ACTION, [qw/ before1 before2 root after1 after2 after3 /];
};

done_testing;

