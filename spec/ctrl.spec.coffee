require.paths.push("#{__dirname}/..")

Ctrl = require("ctrl.coffee")

oneArgCallback = (value, callback) ->
  setTimeout(
    ->
      callback(value)
    10
  )

twoArgCallback = (v1, v2, callback) ->
  setTimeout(
    ->
      callback(v1, v2)
    10
  )

describe "Ctrl", ->

  describe "calling new", ->
    it "should return a new Ctrl object", ->
      expect(Ctrl.new()).toBeDefined()
    it "with steps should execute those steps", ->
      x = 0
      Ctrl.new(
        ->
          x += 1
        ->
          x += 1
      )
      expect(x).toEqual(2)

  describe "calling exec", ->
    it "should execute steps in order", ->
      a = []
      Ctrl.new(
        ->
          a.push 1
        ->
          a.push 2
      )
      expect(a).toEqual([1, 2])
  
  describe "results", ->
    it "should be blank on the first step", ->
      Ctrl.new(
        (ctrl) ->
          expect(ctrl.result).toBeNull()
          expect(ctrl.results).toEqual([])
          expect(ctrl.results).toEqual({})
      )
    it "or any step where the previous step doesn't call collect", ->
      Ctrl.new(
        (ctrl) ->
          null
        (ctrl) ->
          expect(ctrl.result).toBeUndefined()
          expect(ctrl.results).toEqual([])
          expect(ctrl.results).toEqual({})
      )
    
  describe "calling collect once with no arguments", ->
    describe "for a one argument callback", ->
      it "should populate results properly", ->
        done = false
        Ctrl.new(
          (ctrl) ->
            oneArgCallback 1, ctrl.collect()
          (ctrl) ->
            expect(ctrl.result).toEqual(1)
            expect(ctrl.results).toEqual([1])
            expect(ctrl.named_results).toEqual({})
            done = true
        )
        waitsFor -> done

    describe "for a two argument callback", ->
      it "should populate results properly", ->
        done = false
        Ctrl.new(
          (ctrl) ->
            twoArgCallback 1, 2, ctrl.collect()
          (ctrl) ->
            expect(ctrl.result).toEqual([1, 2])
            expect(ctrl.results).toEqual([[1, 2]])
            expect(ctrl.named_results).toEqual({})
            done = true
        )
        waitsFor -> done

  describe "calling collect more than once with no arguments", ->
    describe "for a one argument callback", ->
      it "should populate results properly", ->
        done = false
        Ctrl.new(
          (ctrl) ->
            oneArgCallback 1, ctrl.collect()
            oneArgCallback 2, ctrl.collect()
          (ctrl) ->
            expect(ctrl.result).toEqual(1)
            expect(ctrl.results).toEqual([1, 2])
            expect(ctrl.named_results).toEqual({})
            done = true
        )
        waitsFor -> done

    describe "for a two argument callback", ->
      it "should populate results properly", ->
        done = false
        Ctrl.new(
          (ctrl) ->
            twoArgCallback 1, 2, ctrl.collect()
            twoArgCallback 3, 4, ctrl.collect()
          (ctrl) ->
            expect(ctrl.result).toEqual([1, 2])
            expect(ctrl.results).toEqual([[1, 2], [3, 4]])
            expect(ctrl.named_results).toEqual({})
            done = true
        )
        waitsFor -> done

  describe "calling collect once with arguments", ->
    describe "for a one argument callback", ->
      it "should populate results properly", ->
        done = false
        Ctrl.new(
          (ctrl) ->
            oneArgCallback 1, ctrl.collect("res")
          (ctrl) ->
            expect(ctrl.result).toBeUndefined()
            expect(ctrl.results).toEqual([])
            expect(ctrl.named_results.res).toEqual(1)
            done = true
        )
        waitsFor ->
          done

    describe "for a two argument callback", ->
      it "should populate results properly", ->
        done = false
        Ctrl.new(
          (ctrl) ->
            twoArgCallback 1, 2, ctrl.collect("res")
          (ctrl) ->
            expect(ctrl.result).toBeUndefined()
            expect(ctrl.results).toEqual([])
            expect(ctrl.named_results.res).toEqual([1, 2])
            done = true
        )
        waitsFor -> done

  describe "calling collect multiple times with arguments", ->
    it "should populate results correctly", ->
      done = false
      Ctrl.new(
        (ctrl) ->
          twoArgCallback 1, 2, ctrl.collect("r1")
          twoArgCallback 3, 4, ctrl.collect("r3", "r4")
        (ctrl) ->
          expect(ctrl.named_results.r1).toEqual([1, 2])
          expect(ctrl.named_results.r3).toEqual(3)
          expect(ctrl.named_results.r4).toEqual(4)
          done = true
      )
      waitsFor -> done

  describe "calling stop", ->
    it "should prevent subsequent steps from running", ->
      runs ->
        @count = 0
        @ctrl = Ctrl.new(
          (ctrl) =>
            oneArgCallback 1, ctrl.collect()
            @count += 1
          (ctrl) =>
            ctrl.stop()
            @count += 1
            oneArgCallback 1, ctrl.collect()
          (ctrl) =>
            @count += 1
        )
      waitsFor -> @ctrl.done?
      runs ->
        expect(@count).toEqual(2)
