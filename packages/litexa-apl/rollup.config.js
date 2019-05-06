/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';

export default {
  input: 'lib/aplHandler.js',
  output: {
    file: './dist/handler.js',
    format: 'iife',
    name: 'createAPLHandler',
    banner: 'module.exports = (args) => {',
    footer: 'return createAPLHandler(args); }',
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
