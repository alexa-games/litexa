{assert, expect} = require 'chai'
{spy, stub} = require 'sinon'
{addNumbers, todayName} = require '../../lib/components/utils'

describe 'utils', ->
  describe '#todayName', ->
    mockTimeService = undefined

    beforeEach ->
      mockTimeService =
        serverTimeGetDay: ->
          0

    it 'returns the days of the week correctly', ->
      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 0
      expect(todayName(mockTimeService)).to.equal 'Sunday'
      timeStub.restore()

      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 1
      expect(todayName(mockTimeService)).to.equal 'Monday'
      timeStub.restore()

      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 2
      expect(todayName(mockTimeService)).to.equal 'Tuesday'
      timeStub.restore()

      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 3
      expect(todayName(mockTimeService)).to.equal 'Wednesday'
      timeStub.restore()

      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 4
      expect(todayName(mockTimeService)).to.equal 'Thursday'
      timeStub.restore()

      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 5
      expect(todayName(mockTimeService)).to.equal 'Friday'
      timeStub.restore()

      timeStub = stub(mockTimeService, 'serverTimeGetDay').returns 6
      expect(todayName(mockTimeService)).to.equal 'Saturday'
      timeStub.restore()

    it 'makes a call to the time services for the day', ->
      timeSpy = spy mockTimeService, 'serverTimeGetDay'
      todayName mockTimeService
      assert timeSpy.calledOnce, 'made a call ot the service for the server day'

  describe '#addNumbers', ->
    it 'defaults to 0', ->
      expect(addNumbers()).to.equal 0

    it 'sums correctly', ->
      result = addNumbers 1, 2, 3
      expect(result).to.equal 6
