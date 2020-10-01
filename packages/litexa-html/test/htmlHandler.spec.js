const {expect} = require('chai');
const readHandler = require('../lib/htmlHandler');

// this emulates what happens in the litexa deployed code:
// the handler is converted to text, and evaluated within 
// the context of the litexa monolitic file, so it can see
// the litexa variable.
let litexa = {
    assetsRoot: 'https://litexa-root.com/',
    language: 'MO-ON'
} 
let htmlHandler = eval(readHandler.toString());

const htmlContext = {
    say: [],
    directives: [],
    screen: {},
    language: 'default',
    event: {
        context: {
            System: {
                device: {
                    supportedInterfaces: {
                        'Alexa.Presentation.HTML': {}
                    }
                }
            }
        }
    }
};

const nonHtmlContext = {
    say: [],
    directives: [],
    screen: {},
    language: 'default',
    event: {
        context: {
            System: {
                device: {
                    supportedInterfaces: {
                        'Alexa.Presentation.APL': {}
                    }
                }
            }
        }
    }
};

describe('htmlHandler', () => {
    let make = (htmlPresent) => {
        let context = JSON.parse(JSON.stringify(htmlPresent ? htmlContext : nonHtmlContext)); 
        return {
            context: context,
            handler: htmlHandler(context)
        }
    }

    describe('isHTMLPresent()', () => {
        it('should return true if the HTML interface is declared in the context', () => {
            expect(make(true).handler.userFacing.isHTMLPresent()).to.be.true;
        });

        it('should return false if the HTML interface is not declared in the context', () => {
            expect(make(false).handler.userFacing.isHTMLPresent()).to.be.false;
        });

        it('should return false if the HTML interface is declared but disabled', () => {
            let test = make(true);
            test.handler.userFacing.setEnabled(false);
            expect(test.handler.userFacing.isHTMLPresent()).to.be.false;
        });

        it('should return false if the HTML interface is declared but not disabled', () => {
            let test = make(true);
            test.handler.userFacing.setEnabled(true);
            expect(test.handler.userFacing.isHTMLPresent()).to.be.true;
        });
    });

    describe('mark()', () => {
        it('should push a \'mark\' tag to context\'s say stack', () => {
            let test = make(true);
            test.handler.userFacing.mark('myMarkName');
            expect(test.context.say.length).to.equal(1);
            expect(test.context.say[0]).to.equal("<mark name='myMarkName'/>");
        });

        it('should not push anything to context\'s say stack if HTML interface is not declared', () => {
            let test = make(false);
            test.handler.userFacing.mark('myMarkName');
            expect(test.context.say.length).to.equal(0);
        });
    });

    describe('start()', () => {
        let start = (url, timeout, initialData) => {
            let test = make(true);
            let directive = test.handler.userFacing.start(url, timeout, initialData );
            return { directive, context: test.context, handler: test.handler };
        }

        it('should create a valid HTML directive', () => {
            let { directive } = start('https://myserver.com/index.html', 123, { sybill: true } );
            expect(directive.type).to.equal('Alexa.Presentation.HTML.Start');
            expect(directive.configuration.timeoutInSeconds).to.equal(123);
            expect(directive.data.sybill).to.be.true;
            expect(directive.request.uri).to.equal('https://myserver.com/index.html');
        });

        it("should return null if HTML isn't present", () => {
            expect( make(false).handler.userFacing.start("https://hello") ).to.be.null;
        });

        it('should pass through an absolute filename', () => {
            let { directive } = start('https://myserver.com/index.html' );
            expect(directive.request.uri).to.equal('https://myserver.com/index.html');
        });

        it('should append the litexa asset path for a relative filename', () => {
            let { directive } = start('index.html' );
            expect(directive.request.uri).to.equal('https://litexa-root.com/MO-ON/index.html');
        });

        it("should reject absolute URLs that aren't HTTPS", () => {
            expect( () => make(true).handler.userFacing.start("http://not-good.com") ).to.throw();
        });
    });

});
