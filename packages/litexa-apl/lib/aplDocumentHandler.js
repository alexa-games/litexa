const merge = require('./aplFragmentMerger');
const {isEmpty} = require('./aplUtils');

const REQUIRED_ATTRIBUTE_DEFAULTS = {
    type: 'APL',
    version: '1.0',
    mainTemplate: {}
}
const REQUIRED_ATTRIBUTES = Object.keys(REQUIRED_ATTRIBUTE_DEFAULTS);

const OPTIONAL_ATTRIBUTES = [
  'description',  // String to describe this document
  'import',       // array of IMPORTS (list of references to external APL packages)
  'layouts',      // map of LAYOUTS (custom complex components)
  'resources',    // map of RESOURCES
  'styles',       // map of STYLES
  'theme'         // one of ['light', 'dark']
]

const SPEECH_CONTAINER_ID = 'LitexaSpeechContainer';

const customMergeOptions = {
  customMerge: (key) => {
    if (key === 'mainTemplate') {
      return customMainTemplateMerge;
    }
  }
}

const customMainTemplateMerge = (mainT1, mainT2) => {
  // Not accumulating mainTemplates since every document should only have one: Set to the latest.
  console.warn(`WARNING: aplDocumentHandler found two mainTemplates while merging two apl document fragments. Replacing the first mainTemplate with the second!`);
  return mainT2;
}

module.exports = {
  init: function(args = {}) {
    this.prefix = args.prefix || '';
    this.document = {};
  },

  addSpeechContainer: function({
    speech = '',
    suffix,
    isURL = false
  }) {
    const speechContainer = {
      layouts: {
        [SPEECH_CONTAINER_ID]: {
          item: {
            type: 'Container',
            items: [
              {
                type: 'Text',
                id: `${this.prefix}ID${suffix}`,
                // Leaving the below commented for now, to illustrate how the transformed text would be fetched/used.
                //text: '${payload.' + `${ID_PREFIX}SpeechObject${suffix}.properties.Text${suffix}` + '}'
                speech: isURL ? speech : '${payload.' + `${this.prefix}SpeechObject${suffix}.properties.${this.prefix}Speech${suffix}` + '}'
              }
            ]
          }
        }
      }
    }
    this.addDocument(speechContainer);
    this.createSpeechReference();
  },

  // This creates a container reference in our mainTemplate, which is required for the container and ID within to be visible at runtime.
  createSpeechReference: function() {
    let template = this.addMainTemplate(this.document);
    let templateItems = this.addTemplateItems(template);
    let container = this.addContainer(templateItems);
    let containerItems = this.addContainerItems(container);

    // Let's migrate any upper level items into our new container.
    templateItems.forEach((item) => {
      if (item !== container) {
        containerItems.push(item);
        templateItems.shift();
      }
    })

    this.addSpeechReference(containerItems);
  },

  addMainTemplate: function(document = {}) {
    if (!document.hasOwnProperty('mainTemplate')) {
      document.mainTemplate = {};
    }
    return document.mainTemplate;
  },

  addTemplateItems: function(template = {}) {
    if (!template.hasOwnProperty('items')) {
      template.items = [];
    }
    return template.items;
  },

  addContainer: function(templateItems = []) {
    let container = undefined;

    for (let item of templateItems) {
      if (item.type === 'Container') {
        container = item;
      }
    }

    if (isEmpty(container)) {
      container = {
        type: 'Container',
      }
      templateItems.push(container);
    }
    return container;
  },

  addContainerItems: function(container = {}) {
    if (!container.hasOwnProperty('items')) {
      container.items = [];
    }
    return container.items;
  },

  addSpeechReference: function(containerItems = []) {
    let speechRef = undefined;

    for (let item of containerItems) {
      if (item.type === SPEECH_CONTAINER_ID) {
        speechRef = item;
      }
    }

    if (isEmpty(speechRef)) {
      containerItems.push({
        type: SPEECH_CONTAINER_ID
      });
    }
  },

  addDocument: function(obj) {
    if (isEmpty(obj)) {
      // Nothing to merge.
      return;
    }

    if (typeof(obj) !== 'object') {
      console.error(`aplDocumentHandler|addDocument(): Tried adding non-object document of type '${typeof(obj)}' > ignoring.`)
      return;
    }

    this.itemToItems(obj.mainTemplate);

    this.document = merge(this.document, obj, customMergeOptions);
  },

  // This finds and moves a target's single 'item' object to an array of 'items', to facilitate merging.
  itemToItems: function(target) {
    if (isEmpty(target) || !target.hasOwnProperty('item')) {
      // Nothing to do.
      return;
    }

    target.items = target.items || [];

    if (Array.isArray(target.item)) {
      target.items.push(...target.item);
      delete target.item;
    } else if (typeof(target.item) === 'object') {
      target.items.push(target.item);
      delete target.item;
    } else {
      console.error(`aplDocumentHandler|itemToItems(): Found non-array and non-object 'item' of type '${typeof(target.item)}' > doing nothing.`);
    }
  },

  isValidDocument: function(document = this.document) {
    if (isEmpty(document)) {
      return false;
    }

    for (let attr of REQUIRED_ATTRIBUTES) {
      if (isEmpty(document[attr])) {
        if (attr === 'mainTemplate') {
          console.error(`APLHandler|isValidDocument(): Missing required attribute '${attr}' > ignoring this document.`);
          return false;
        } else {
          // Add default values for 'type' and 'version', if user forgot to add them.
          document[attr] = REQUIRED_ATTRIBUTE_DEFAULTS[attr];
        }
      }
    }

    for (let attr of Object.keys(document)) {
      if (!REQUIRED_ATTRIBUTES.includes(attr) && !OPTIONAL_ATTRIBUTES.includes(attr)) {
        // Don't need to fail out here, but logs should indicate this attribute is useless.
        console.warn(`APLHandler|isValidDocument(): Unsupported attribute '${attr}' found in document.`);
      }
    }
    return true;
  }
}
