const moduleAlias = require('module-alias');
moduleAlias.addAliases({
    '@root'  : __dirname,
    '@src': __dirname + '/src',
    '@test': __dirname + '/test',
});
moduleAlias();
