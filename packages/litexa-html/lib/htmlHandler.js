module.exports = (context) => {
    const contextHasHTML = () => {
        const interfaces =
            context &&
            context.event &&
            context.event.context &&
            context.event.context.System &&
            context.event.context.System.device &&
            context.event.context.System.device.supportedInterfaces;
        return interfaces && interfaces.hasOwnProperty('Alexa.Presentation.HTML');
    };

    return {
        userFacing: {
            isHTMLPresent: () => contextHasHTML(),
            mark: (str) => {
                if (!contextHasHTML()) { return; }
                context.say.push(`<mark name='${str}'/>`);
            }
        },
        events: {}
    };
};
