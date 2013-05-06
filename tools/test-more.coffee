# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

exports.like = (t,got_str,should_re,msg) -> t.ok should_re.test( got_str ), msg, { found : got_str, wanted : should_re }

exports.throws_like = (t,f,should_re,msg) ->
  try
    f()
    t.fail "nothing thrown", { found : null, wanted : should_re }
  catch got_e
    exports.like t, got_e.message, should_re, msg

exports.is_deeply = (t,got,expect,message) -> t.is( JSON.stringify(got), JSON.stringify(expect), message )
