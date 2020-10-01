/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const moduleAlias = require('module-alias');
const path = require('path');
moduleAlias.addAliases({
    '@root': __dirname,
    '@src': path.join(__dirname, '/src'),
    '@test': path.join(__dirname, '/test'),
});
moduleAlias();
