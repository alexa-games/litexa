/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

Test.expect("stuff to work", function() {
  console.log(RuntimeInline.hello());
  if (RuntimeInline.secret != 13) {
    throw new Error("wrong secret for RuntimeInline");
  }

  console.log(RuntimeRequire.hello());
  if (RuntimeRequire.secret != 7) {
    throw new Error("wrong secret for RuntimeRequire");
  }
});
