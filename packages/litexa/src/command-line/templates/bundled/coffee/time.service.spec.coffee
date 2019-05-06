
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
###


{assert} = require 'chai'
{spy} = require 'sinon'
{Time} = require '../../lib/services/time.service'

describe 'Time', ->
  describe '#serverTimeGetDay', ->
    mockDate = undefined

    beforeEach ->
      mockDate =
        getDay: ->
          0

    it 'returns the day', ->
      dateSpy = spy(mockDate, 'getDay')
      Time.serverTimeGetDay mockDate
      assert dateSpy.calledOnce, 'got the day'
