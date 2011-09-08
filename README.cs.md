## Summary

Ctrl is (yet another) a flow control library for Javascript.

What's wrong with TameJS or Flow or Step?  Well, I'm a Rubyist and CoffeeScript fan.
TameJS doesn't play well with CoffeeScript because of the extra
compilation step.  Plus the code that TameJS compiles down to is pretty heinous.

I didn't like how results are passed in either Flow or Step.  Plus, both Flow and Step
make use of `this`, which is no good for me since I want to use them from
within objects and I want `this` to refer to my object.

## Installation

Ctrl is not in npm yet, so you have to install manually.

```bash
cd node_modules
git clone git://github.com/cjbottaro/ctrl.git
```

Then in a Javascript file.

```javascript
Ctrl = require("ctrl")
```

## Conventions in this README

All examples are written in CoffeeScript.  Also, I make use of two
contrived async functions to demonstrate how Ctrl works.

```coffeescript
oneArgTimeout(n, callback)
twoArgTimeout(n, message, callback)
```

`oneArgTimeout` calls `callback` after `n` seconds.  It passes `n` to
the callback.

`twoArgTimeout` does the same thing, but passes both `n` and `message`
to the callback.

Example:

```coffeescript
twoArgTimeout 5, "I slept", (n, message) ->
  console.log("#{message} for #{n} seconds")
```

Outputs:

    "I slept for 5 seconds"

## Problem: nested callback hell

Consider this code that is trying to execute each call to
`oneArgTimeout` serially.

```coffeescript
oneArgTimeout 1, (n) ->
  console.log("slept for #{n}")
  oneArgTimeout 2, (n) ->
    console.log("slept for #{n}")
    oneArgTimeout 3, (n) ->
      console.log("slept for #{n}")
```

Here's how we would "un-nest" it with Ctrl.

```coffeescript
    Ctrl.run(
      (ctrl) ->
        oneArgTimeout 1, ctrl.collect()
      (ctrl) ->
        console.log("slept for #{ctrl.result}")
        oneArgTimeout 2, ctrl.collect()
      (ctrl) ->
        console.log("slept for #{ctrl.result}")
        oneArgTimeout 3, ctrl.collect()
      (ctrl) ->
        console.log("slept for #{ctrl.result}")
    )
```

## Problem: synchronizing async calls

Consider the following code that is trying to execute both calls to `oneArgTimeout` in parallel, collect the results, and then call `weAreDone` with the results after both of them are finished.

```coffeescript
finished_count = 0
results = []
callback = (result) ->
  finished_count += 1
  results.push(result)
  if finished_count == 2
    weAreDone(results)

oneArgTimeout(1, callback)
oneArgTimeout(1, callback)
```

Now with Ctrl.

```coffeescript
    Ctrl.run(
      (ctrl) ->
        oneArgTimeout(1, ctrl.collect())
        oneArgTimeout(1, ctrl.collect())
      (ctrl) ->
        weAreDone(ctrl.results)
    )
```

Oh man, that was sweet.

## Collecting and accessing results

A little bit of terminology first... we're going to call each function
passed to Ctrl a step.

Each step can designate how to collect results from callbacks, as well
as access results from the previous step.

### A single result (one call to `collect`)

If you call `collect` only once in a step, then you can access the
results with `result` (notice it's singular) from the next step.

```coffeescript
    Ctrl.run(
      (ctrl) ->
        oneArgTimeout 1.2, ctrl.collect()
      (ctrl) ->
        console.log(ctrl.result)
    )
```

That outputs `1.2`, but what if the callback is invoked with multiple
arguments?


```coffeescript
    Ctrl.run(
      (ctrl) ->
        twoArgTimeout 1.2, "hi", ctrl.collect()
      (ctrl) ->
        console.log(ctrl.result)
    )
```

That outputs `[ 1.2, 'hi' ]`, i.e. `ctrl.result` is an array.

### Multiple results (more than one call to `collect`)

If `collect` is called multiple times, then `results` (notice it's
plural) holds the results corresponding to each call of `collect`.

```coffeescript
    Ctrl.run(
      (ctrl) ->
        twoArgTimeout 2, "hi", ctrl.collect()
        twoArgTimeout 1, "bye", ctrl.collect()
      (ctrl) ->
        console.log(ctrl.results)
    )
```

That outputs `[ [ 2, 'hi' ], [ 1, 'bye' ] ]`.

Notice the order of the results correspond to the order that `collect` is called, *not* the
order in which the callbacks are executed.

### Named results

`collect` can be called with arguments which will result in
`named_results` being a hash (or I guess object in JS) where the keys
correspond to the arguments.

```coffeescript
Ctrl.run(
  (ctrl) ->
    twoArgTimeout 1, "hi", ctrl.collect("result1")
    twoArgTimeout 2, "bye", ctrl.collect("result2")
  (ctrl) ->
    console.log(ctrl.named_results["result1"])
    console.log(ctrl.named_results["result2"])
)

Results in the output:

```javascript
[ 1, "hi" ]
[ 2, "bye" ]
```

Or you can unpack arguments into discrete keys.

```coffeescript
Ctrl.run(
  (ctrl) ->
    twoArgTimeout 1, "hi", ctrl.collect("time1", "message1")
    twoArgTimeout 2, "bye", ctrl.collect("time2", "message2")
  (ctrl) ->
    console.log(ctrl.named_results["time1"])
    console.log(ctrl.named_results["message1"])
    console.log(ctrl.named_results["time2"])
    console.log(ctrl.named_results["message2"])
)
```

Which results in:

    1
    hi
    2
    bye

## Stopping execution

What happens if a step results in an error and we want to stop execution
of any remaining steps.  That's what the `stop` method is for.
```coffeescript
Ctrl.run(
  (ctrl) ->
    redis.get key, ctrl.collect()
  (ctrl) ->
    error = ctrl.result[0]
    value = ctrl.result[1]
    if error?
      console.log("oops, error with redis: #{error}")
      ctrl.stop()
    else
      redis.get value, ctrl.collect()
  (ctrl) ->
    error = ctrl.result[0]
    value = ctrl.result[1]
    console.log("final value is #{value}")
)
```

If there is an error, then the 3rd step will never be executed.

## Conveniences

You don't have to pass the Ctrl object to each step.  You can just use
the power of closures instead.

```coffeescript
ctrl = Ctrl.new()
ctrl.run(
  ->
    oneArgTimeout 1, ctrl.collect()
  ->
    console.log(ctrl.result)
)
```

Anytime a one element array would be returned in the results, just the
element will be returned instead.

## How is this different from Step, Flow or TameJS?

TameJS extends the Javascript langauge, thus requiring you to run a
preprocessor (compiler) on your TameJS code.  This makes it not play so
nice with CoffeeScript (which also requires a step to compile into JS).

Also, TameJS offers a more natural way to program in that it doesn't
require all your steps be wrapped in a function call.  It's more akin to
spawning threads and calling join on them.

Step and Flow are both less flexible with how async return values are
passed between the steps (as noted on the TameJS page).

This may sound silly, but I didn't like the way my code looked when
using Step or Flow.  Each step took different arguments and thus my
indentation wasn't pretty.

Also, both Step and Flow do some funky stuff with bindings which changes
`this` in the scope of a step.  I didn't like that because, I use "classes"
a lot.  I want `this` to refer to the object
I'm in so I can use "instances variables" and "instance methods".  I
know I can work around this with Flow and Step by using closures, but it
didn't make for pretty code.

Sorry for the "quotes"... I am new to Javascript and I feel like I'm
not using the proper terminology.

## Tests

    jasmine-node --color --coffee spec

This assumes you have `jasmine-node` and `coffee-script` installed
globally and that you are in the root dir of the Ctrl project.

## Please help me

Like I said, I'm new to Javascript and Node, but I've been immersed in
the Ruby world for quite some time now.  Please tweet at me to let me
know if I'm doing something wrong, or some Ruby concepts don't carry
over or I'm just not getting Javascript... :)  Name is @cjbottaro
