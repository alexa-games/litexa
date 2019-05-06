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

const path = require('path');

module.exports = {
    target: 'node',
    entry: './lib/index.js',
    devtool: 'inline-source-map',
    resolve: {
        extensions: ['.js'],
        modules: ['node_modules']
    },
    output: {
        libraryTarget: 'global',
        filename: 'main.min.js',
        path: path.resolve(__dirname, 'litexa')
    }
};
