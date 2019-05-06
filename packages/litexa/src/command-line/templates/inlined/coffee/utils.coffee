
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


todayName = ->
  day = (new Date).getDay()
  return [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
      'Thursday', 'Friday', 'Saturday' ][day]

addNumbers = (...numbers) ->
  console.log "the arguments are #{numbers}"
  result = 0
  for num in numbers 
    result += num
  return result
