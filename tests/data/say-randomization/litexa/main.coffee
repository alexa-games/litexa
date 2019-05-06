
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


testSay = (context) ->

  # test the algorithm directly for a range of variation counts
  totalDeviations = {}

  repetitionCount = 100.0
  testRepetitions = 10
  variations = 12

  for repetition in [0...repetitionCount]
    for count in [2..variations]
      picks = []

      testSayKey = 9999 + repetition * variations + count

      # get successive variations, testing each against the last
      lastPick = null
      testLength = count * testRepetitions
      for i in [0...testLength]
        idx = pickSayString context, testSayKey, count
        picks.push idx
        if idx == lastPick
          console.error "picks: #{JSON.stringify picks}"
          throw "count #{count} picked the same choice back to back #{idx} == #{lastPick}"
        lastPick = idx

      # run test to visually inspect the output patterns
      density = {}
      for i in picks
        density[i] = density[i] ? 0
        density[i] += 1

      deviation = ( Math.abs(testRepetitions - v) for k, v of density )
      average = 0
      average += d for d in deviation
      average /= count
      average = average.toFixed(2)

      totalDeviations[count] = totalDeviations[count] ? 0
      totalDeviations[count] += average / repetitionCount

      if repetition < 3
        if picks.length > 16
          picks = "#{picks[0...16].join(',')}..."
        else
          picks = picks.join '.'
        if count < 10
          count = " #{count}"
        console.log "count #{count}, deviation #{average} picked #{picks}"

  console.log "totalDeviations, #{(k + ':' + v.toFixed(2) for k, v of totalDeviations).join ', '} "
