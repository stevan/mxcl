#!perl

use v5.42;
use Test::More;

use MXCL::Term;

subtest 'Exception creation' => sub {
    my $msg = MXCL::Term::Str->CREATE('Something went wrong');
    my $ex = MXCL::Term::Exception->new(msg => $msg);

    ok($ex isa MXCL::Term::Exception, 'isa Exception');
    ok($ex->msg->equals($msg), 'msg accessor');
    like($ex->stringify, qr/exception.*Something went wrong/, 'stringify');
    ok($ex->boolify, 'boolify true');
};

subtest 'Exception CREATE shortcut' => sub {
    my $msg = MXCL::Term::Str->CREATE('error');
    my $ex = MXCL::Term::Exception->CREATE($msg);

    ok($ex isa MXCL::Term::Exception, 'CREATE returns Exception');
    ok($ex->msg->equals($msg), 'msg from CREATE');
};

subtest 'Exception throw' => sub {
    my $caught;
    eval {
        MXCL::Term::Exception->throw('test error');
    };
    $caught = $@;

    ok($caught isa MXCL::Term::Exception, 'throw dies with Exception');
    like($caught->msg->stringify, qr/test error/, 'thrown exception has message');
};

subtest 'Exception throw with Term msg' => sub {
    my $msg = MXCL::Term::Str->CREATE('term message');
    my $caught;
    eval {
        MXCL::Term::Exception->throw($msg);
    };
    $caught = $@;

    ok($caught isa MXCL::Term::Exception, 'throw with Term msg');
    ok($caught->msg->equals($msg), 'preserves Term message');
};

subtest 'Exception equality' => sub {
    my $msg1 = MXCL::Term::Str->CREATE('error');
    my $msg2 = MXCL::Term::Str->CREATE('error');
    my $msg3 = MXCL::Term::Str->CREATE('different');

    my $ex1 = MXCL::Term::Exception->CREATE($msg1);
    my $ex2 = MXCL::Term::Exception->CREATE($msg2);
    my $ex3 = MXCL::Term::Exception->CREATE($msg3);

    ok($ex1->equals($ex2), 'equals same message');
    ok(!$ex1->equals($ex3), 'not equals different message');
};

done_testing;
