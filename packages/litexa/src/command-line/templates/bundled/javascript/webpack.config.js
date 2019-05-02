const path = require('path');

module.exports = {
    target: 'node',
    entry: './lib/index.js',
    devtool: 'inline-source-map',
    resolve: {
        extensions: ['.js'],
        modules: ['node_modules']
    },
    output: {
        libraryTarget: 'global',
        filename: 'main.min.js',
        path: path.resolve(__dirname, 'litexa')
    }
};
