requires 'perl', '5.008001';
requires 'Amon2';
requires 'Router::Boom';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'Test::WWW::Mechanize::PSGI';
};

