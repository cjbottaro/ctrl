require.paths.push("#{__dirname}/..")

Ctrl = require("ctrl.coffee")

describe "Ctrl.Step", ->

  describe "calling execute", -> 
    it "should immediately call the continuation if there were no calls to collect", ->
      finished = false
      step = new Ctrl.Step(
        ->
          null
        ->
          finished = true
      )
      step.execute()
      expect(finished).toEqual(true)

  describe "calling finished", ->
    beforeEach ->
      @finished = false
      @step = new Ctrl.Step(
        =>
          null
        =>
          @finished = true
      )
    it "should prepare results and call the continuation", ->
      @step.a_results = [[1], null, [2], [3], [4, 5]]
      @step.h_results = { r1 : 1, r2 : 2 }
      @step.finished()
      expect(@step.result).toEqual(1)
      expect(@step.results).toEqual([1, 2, 3, [4, 5]])
      expect(@step.named_results).toEqual({ r1 : 1, r2 : 2 })
      expect(@finished).toEqual(true)

  describe "calling collect should return a function that", ->
    beforeEach ->
      @step = new Ctrl.Step
      @step.finished = -> # The method collect returns will call finished because @async_finished == 0.
    it "should collect results into an array (in the order that collect was called)", ->
      c1 = @step.collect()
      c2 = @step.collect()
      c2(2, 3)
      c1(1)
      expect(@step.a_results).toEqual([[1], [2, 3]])
    it "should collect named results into a hash", ->
      @step.collect("r1")(1)
      @step.collect("r2")(2, 3)
      @step.collect("r3", "r4")(4, 5, 6)
      @step.collect("r7", "r8")(7, 8)
      expect(@step.h_results.r1).toEqual(1)
      expect(@step.h_results.r2).toEqual([2, 3])
      expect(@step.h_results.r3).toEqual(4)
      expect(@step.h_results.r4).toEqual([5, 6])
      expect(@step.h_results.r7).toEqual(7)
      expect(@step.h_results.r8).toEqual(8)
