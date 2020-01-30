const {expect} = require('chai');
const htmlHandler = require('../lib/htmlHandler');

const context = {
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

describe('htmlHandler', () => {
    let handler = undefined;

    beforeEach(() => {
        handler = htmlHandler(context);
    });

    describe('#isHTMLPresent()', () => {
        it('should return true if the HTML interface is declared in the context', () => {
            expect(handler.userFacing.isHTMLPresent()).to.be.true;
        });
    });

    describe('#mark()', () => {
        it('should push a \'mark\' tag to context\'s say stack', () => {
            handler.userFacing.mark('myMarkName');
            expect(context.say.length).to.equal(1);
            expect(context.say[0]).to.equal("<mark name='myMarkName'/>");
        });

        it('should not push anything to context\'s say stack if HTML interface is not declared', () => {
            const anotherContext = { say: [], event: {} };
            const anotherHandler = htmlHandler(anotherContext);
            anotherHandler.userFacing.mark('myMarkName');
            expect(anotherContext.say.length).to.equal(0);
        });
    });
});
