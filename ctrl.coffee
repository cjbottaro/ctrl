class Ctrl

  # Convenience method to create a Ctrl instance and call exec on it.
  @new = (steps...) ->
    ctrl = new Ctrl
    ctrl.exec(steps...) if steps.length > 0
    ctrl

  # Given a list of steps (functions) execute them serially, even if each step contains async code.
  exec: (steps...) ->
    @steps   = steps
    @index   = 0
    @i_results = []
    @n_results = []

    @run_steps()

  # Run steps until we detect we need to wait for an async call to finish.
  run_steps: ->
    while true
      step = @steps[@index]
      break unless step?
      @call(step)
      break if @defers > 0
      @index += 1

  # Execute a step's function.
  call: (step) ->
    @defers = 0
    @calls  = 0
    @i_results[@index] = []
    @n_results[@index] = {}
    @expose_previous_results()
    step(@)

  # Setups up instance vars so that the current step can access the previous step's results.
  expose_previous_results: ->
    # Special case, first step has no results
    if @index == 0
      @result = null
      @results = []
      @named_results = {}
      return

    # Results by index
    results = []
    for result in @i_results[@index-1]
      if result?
        if result.length == 1
          results.push(result[0])
        else
          results.push(result)
    @result  = results[0]
    @results = results

    # Results by name
    results = @n_results[@index-1]
    if results?
      @named_results = results
    else
      @named_results = {}

  # Collect callback results into an array or hash.
  # If names are given, results are collected into a hash with each name being a key.
  collect: (names...) ->
    index = @defers
    @defers += 1

    (results...) =>
      if names.length > 0
        for [name, result] in @zip(names, results)
          @n_results[@index][name] = result
      else
        @i_results[@index][index] = results

      @calls += 1
      if @calls == @defers
        @index += 1
        @run_steps()

  # This isn't a generic zipping function.  It assumes that ar1 has at least one item.
  # Also, if ar2 has more items than ar1, then ar1's last item will be zipped with the
  # remainding items of ar2 (which is contrary to how Ruby's Array#zip works.
  zip: (ar1, ar2) ->
    zipped = []
    i = 0
    while i < ar1.length
      zipped[i] = [ar1[i], ar2[i]]
      i += 1
    if ar2.length > ar1.length
      i -= 1
      zipped[i] = [ar1[i], ar2[i...ar2.length]]
    zipped

module.exports = Ctrl
