###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
