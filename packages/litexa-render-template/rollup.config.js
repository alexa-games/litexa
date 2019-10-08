/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';

export default {
  input: 'lib/renderTemplateHandler.js',
  output: {
    file: './dist/handler.js',
    format: 'iife',
    name: 'createRenderTemplateHandler',
    banner: 'module.exports = (args) => {',
    footer: 'return createRenderTemplateHandler(args); }',
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
