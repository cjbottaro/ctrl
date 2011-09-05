class Ctrl

  class Ctrl.Step
    constructor: (func, cont) ->
      @func = func # Function that constitutes the step.
      @cont = cont # Continuation to call once the step is complete.
      @async_started  = 0
      @async_finished = 0
      @a_results = [] # Array results
      @h_results = {} # Hash results

    execute: (ctrl) ->
      @func(ctrl)
      @finished() if @async_started == 0

    collect: (names...) ->
      index = @async_started
      @async_started += 1

      (results...) =>
        if names.length > 0
          for [name, result] in Ctrl.zip(names, results)
            @h_results[name] = result
        else
          @a_results[index] = results
        @async_finished += 1
        @finished() if @async_started == @async_finished

    finished: ->
      # Compact the indexed results and flatten any that are single
      # element arrays.
      @results = []
      for result in @a_results
        if result?
          if result.length == 1
            @results.push(result[0])
          else
            @results.push(result)

      # No processing needs to be done on named results.
      @named_results = @h_results

      # Provided as a convenience.
      @result = @results[0]

      # Call the continuation.
      @cont()

  # end class Ctrl.Step

  # Convenience method to create a Ctrl instance and call exec on it.
  @new = (steps...) ->
    ctrl = new Ctrl
    ctrl.exec(steps...) if steps.length > 0
    ctrl

  # This isn't a generic zipping function.  It assumes that ar1 has at least one item.
  # Also, if ar2 has more items than ar1, then ar1's last item will be zipped with the
  # remainding items of ar2 (which is contrary to how Ruby's Array#zip works.
  @zip: (ar1, ar2) ->
    zipped = []
    i = 0
    while i < ar1.length
      zipped[i] = [ar1[i], ar2[i]]
      i += 1
    if ar2.length > ar1.length
      i -= 1
      zipped[i] = [ar1[i], ar2[i...ar2.length]]
    zipped

  # Given a list of steps (functions) execute them serially, even if each step contains async code.
  exec: (funcs...) ->
    @steps   = (new Ctrl.Step(func, @execNextStep) for func in funcs)
    @index   = -1
    @execNextStep()

  currentStep: ->
    @steps[@index]

  previousStep: ->
    @steps[@index - 1]

  execNextStep: =>
    @index += 1
    previous_step = @previousStep()
    current_step  = @currentStep()
    if previous_step?
      @result        = previous_step.result
      @results       = previous_step.results
      @named_results = previous_step.named_results
    else
      @result        = null
      @results       = []
      @named_results = {}
    current_step.execute(@) if current_step?

  collect: (names...) ->
    @currentStep().collect(names...)

module.exports = Ctrl
