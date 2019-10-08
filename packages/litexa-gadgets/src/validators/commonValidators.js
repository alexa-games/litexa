/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

validateDirectiveType = function({ validator, directive, expectedType }) {
  if (directive.type == null)
    return;

  if (directive.type !== expectedType) {
    validator.fail('type', `should be '${expectedType}'`);
  }
}

module.exports = {
  validateDirectiveType
}
