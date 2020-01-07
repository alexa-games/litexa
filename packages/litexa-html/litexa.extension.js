htmlHandler = require('./dist/handler');

module.exports = (options, lib) => {
    const compiler = {
        requiredAPIs: ['ALEXA_PRESENTATION_HTML'],
        validEventNames: ['Alexa.Presentation.HTML.Message'],
        validIntentNames: ['Alexa.Presentation.HTML.Message'],
        validators: {
            manifest: () => {},
            model: () => {},
            directives: {
                'Alexa.Presentation.HTML.Start': () => {},
                'Alexa.Presentation.HTML.HandleMessage': () => {}
            }
        }
    };

    const language = {
        statements: {},
        testStatements: {},
        lib: {}
    };

    const runtime = {
        apiName: 'HTML',
        source: htmlHandler
    };

    return { compiler, language, runtime };
};
