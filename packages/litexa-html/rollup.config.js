/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';

export default {
  input: 'lib/htmlHandler.js',
  output: {
    file: './dist/handler.js',
    format: 'iife',
    name: 'createHTMLHandler',
    banner: 'module.exports = (args) => {',
    footer: 'return createHTMLHandler(args); }',
    preferConst: true
  },
  plugins: [
    resolve({
      module: true,
      preferBuiltins: false
    }),
    commonjs()
  ]
};
