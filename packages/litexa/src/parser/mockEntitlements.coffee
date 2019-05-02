module.exports.fetchAll = (event, stateContext, after) ->
  unless stateContext.inSkillProducts.inSkillProducts?
    stateContext.inSkillProducts.inSkillProducts = []
  after()
