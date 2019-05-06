
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


lib = module.exports.lib = {}

whiteSpaceRegex = /(^\s*)|(\s*$)/g

stripWhiteSpace = (str) ->
  return "" unless str?
  str = str.replace whiteSpaceRegex, ''
  str = str.replace /\s/g, '\u00A0'
  return str

class lib.DataTable
  constructor: (@name, @schema) ->
    @rows = []

  isDataTable: true

  pushRow: (values) ->
    item = {}
    for value, idx in values
      item[@schema[idx]] = stripWhiteSpace(value)
    @rows.push item

  toLambda: (output, options) ->
    lines = []

    for row, idx in @rows
      line = []
      for name in @schema
        line.push "'" + row[name] + "'"
      lines.push "  [" + line.join(', ') + "]"

    lines = lines.join(",\n  ")
    output.push "dataTables['#{@name}'] = [\n  #{lines}\n];"
    output.push "Object.setPrototypeOf( dataTables['#{@name}'], DataTablePrototype );"
