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

// Script to cache the current coverage report. This can be used to persist the reports in a
// .nyc_output_combined directory, which is then utilized by npm run coverage:report.
const execSync = require('child_process').execSync;
const path = require('path');
const isWin = (process.platform === "win32");

let src = path.join(`${__dirname}`, '.nyc_output', '*');
let dst = path.join(`${__dirname}`, '.nyc_output_combined');
let cmd = '';

if (isWin) {
  cmd = `if not exists "${dst}" mkdir "${dst}" && move ${src} ${dst}`;
} else {
  cmd = `mkdir -p ${dst} && mv ${src} ${dst}`;
}

execSync(cmd, {
  encoding: 'utf-8',
  stdio: 'inherit'
});
