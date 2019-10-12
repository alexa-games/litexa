/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

sendDirectiveValidator = function(validator) {
  const directive = validator.jsonObject;
  // @TODO: Add more validation here.
  const requiredKeys = ['type', 'header', 'endpoint', 'payload'];
  validator.require(requiredKeys);
},

startEventHandlerDirectiveValidator = function(validator) {
  const directive = validator.jsonObject;
  // @TODO: Add more validation here.
  const requiredKeys = ['type', 'token', 'eventFilter', 'expiration'];
  validator.require(requiredKeys);
},

stopEventHandlerDirectiveValidator = function(validator) {
  const directive = validator.jsonObject;
  // @TODO: Add more validation here.
  const requiredKeys = ['type', 'token'];
  validator.require(requiredKeys);
}

module.exports = {
  sendDirectiveValidator,
  startEventHandlerDirectiveValidator,
  stopEventHandlerDirectiveValidator
}
