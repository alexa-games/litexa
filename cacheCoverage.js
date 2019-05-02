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
