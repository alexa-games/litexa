const path = require('path');

module.exports = {
    target: 'node',
    entry: './lib/index.coffee',
    devtool: 'inline-source-map',
    module: {
        rules: [
            {
                test: /\.coffee$/,
                use: [ 'coffee-loader' ]
            }
        ]
    },
    resolve: {
        extensions: ['.js', '.coffee'],
        modules: ['node_modules']
    },
    output: {
        libraryTarget: 'global',
        filename: 'main.min.js',
        path: path.resolve(__dirname, 'litexa')
    }
};
