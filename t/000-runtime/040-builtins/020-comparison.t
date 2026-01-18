#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'numeric equality' => sub {
    ok(eval_mxcl('(== 1 1)')->value, '1 == 1');
    ok(!eval_mxcl('(== 1 2)')->value, '1 != 2');
    ok(eval_mxcl('(== 1.0 1)')->value, '1.0 == 1');
};

subtest 'numeric inequality' => sub {
    ok(eval_mxcl('(!= 1 2)')->value, '1 != 2');
    ok(!eval_mxcl('(!= 1 1)')->value, '!(1 != 1)');
};

subtest 'less than' => sub {
    ok(eval_mxcl('(< 1 2)')->value, '1 < 2');
    ok(!eval_mxcl('(< 2 1)')->value, '!(2 < 1)');
    ok(!eval_mxcl('(< 1 1)')->value, '!(1 < 1)');
};

subtest 'less than or equal' => sub {
    ok(eval_mxcl('(<= 1 2)')->value, '1 <= 2');
    ok(eval_mxcl('(<= 1 1)')->value, '1 <= 1');
    ok(!eval_mxcl('(<= 2 1)')->value, '!(2 <= 1)');
};

subtest 'greater than' => sub {
    ok(eval_mxcl('(> 2 1)')->value, '2 > 1');
    ok(!eval_mxcl('(> 1 2)')->value, '!(1 > 2)');
    ok(!eval_mxcl('(> 1 1)')->value, '!(1 > 1)');
};

subtest 'greater than or equal' => sub {
    ok(eval_mxcl('(>= 2 1)')->value, '2 >= 1');
    ok(eval_mxcl('(>= 1 1)')->value, '1 >= 1');
    ok(!eval_mxcl('(>= 1 2)')->value, '!(1 >= 2)');
};

subtest 'string equality' => sub {
    ok(eval_mxcl('(eq "hello" "hello")')->value, 'eq same');
    ok(!eval_mxcl('(eq "hello" "world")')->value, 'eq different');
};

subtest 'string inequality' => sub {
    ok(eval_mxcl('(ne "hello" "world")')->value, 'ne different');
    ok(!eval_mxcl('(ne "hello" "hello")')->value, 'ne same');
};

subtest 'string ordering' => sub {
    ok(eval_mxcl('(lt "a" "b")')->value, 'a lt b');
    ok(eval_mxcl('(le "a" "b")')->value, 'a le b');
    ok(eval_mxcl('(le "a" "a")')->value, 'a le a');
    ok(eval_mxcl('(gt "b" "a")')->value, 'b gt a');
    ok(eval_mxcl('(ge "b" "a")')->value, 'b ge a');
    ok(eval_mxcl('(ge "b" "b")')->value, 'b ge b');
};

subtest 'spaceship operator' => sub {
    is(eval_mxcl('(<=> 1 2)')->value, -1, '1 <=> 2');
    is(eval_mxcl('(<=> 2 1)')->value, 1, '2 <=> 1');
    is(eval_mxcl('(<=> 1 1)')->value, 0, '1 <=> 1');
};

subtest 'cmp operator' => sub {
    is(eval_mxcl('(cmp "a" "b")')->value, -1, 'a cmp b');
    is(eval_mxcl('(cmp "b" "a")')->value, 1, 'b cmp a');
    is(eval_mxcl('(cmp "a" "a")')->value, 0, 'a cmp a');
};

done_testing;
