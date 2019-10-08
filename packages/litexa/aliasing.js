/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const moduleAlias = require('module-alias');
moduleAlias.addAliases({
    '@root'  : __dirname,
    '@src': __dirname + '/src',
    '@test': __dirname + '/test',
});
moduleAlias();
