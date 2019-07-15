inquirer = require 'inquirer'

# Function to check and handle major/minor mismatch between last deployed @litexa/core
# version and currently installed version.
validateCoreVersion = ({
  prevCoreVersion
  curCoreVersion
  inputHandler
}) ->
  inquirer = inputHandler ? inquirer
  # if this is the first deployment, there's nothing to validate
  unless prevCoreVersion?
    return true

  # split the version strings, to check major/minor/revision
  splitCur = curCoreVersion.split('.')
  splitPrev = prevCoreVersion.split('.')

  diff = null
  if splitCur[0] != splitPrev[0]
    diff = "major"
  else if splitCur[1] != splitPrev[1]
    diff = "minor"

  result = { proceed: true }

  if diff?
    msg = "WARNING: This project was last deployed with version #{prevCoreVersion} of
    @litexa/core. A different #{diff} version #{curCoreVersion} is currently installed. Are you
    sure you want to proceed?"
    result = await inquirer.prompt({
      type: 'list'
      name: 'proceed'
      message: msg
      default: {
        value: 'yes'
      }
      choices: [
        {
          name: 'Yes (I am aware there might have been breaking changes between these versions)'
          value: true
        }
        {
          name: "No (I will install the last deployed #{diff} version of @litexa/core)"
          value: false
        }
      ]
    })

  return result.proceed

module.exports = {
  validateCoreVersion
}
