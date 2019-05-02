const {isEmpty} = require('./renderTemplateUtils')

module.exports = {
  init: function(args = {}) {
    this.template = args.template || {};
    this.myData = args.myData || {};
  },

  addHTMLTags: function(s) {
    s = s.replace(/\n/g, '<br/>');
    s = s.replace(/\&/g, '&amp;');
    return s;
  },

  addText: function(src, type, dest = this.template) {
    if (isEmpty(src)) {
      // Nothing to add.
      return;
    }

    dest.textContent = dest.textContent || {};

    dest.textContent[type] = {
      text: this.addHTMLTags(src),
      type: 'RichText'
    }
  },

  uniqueURL: function(url) {
    if (this.myData.shouldUniqueURLs === 'true') {
      url += `#${new Date().getTime()}`;
    }
    return url;
  },

  addImage: function(src, type, dest = this.template) {
    if (isEmpty(src)) {
      // Nothing to add.
      return;
    }

    dest[type] = {
      sources: [
        {
          url: this.uniqueURL(src)
        }
      ]
    }
  },

  addList: function(srcList) {
    // Let's make sure we correctly received an array of items.
    if (Array.isArray(srcList)) {
      this.template.listItems = [];
    } else {
      console.error(`RenderTemplateHandler:addList(): srcList was not an array > ignoring list.`);
      return;
    }

    for (let srcItem of srcList) {
      let destItem = this.createListItem(srcItem);

      // Make sure we have a non-empty item before adding it.
      if (isEmpty(destItem)) {
        console.error(`RenderTemplateHandler|afterStateMachine(): Item ${JSON.stringify(srcItem)} with no valid attributes found > ignoring list item.`)
      } else {
        this.template.listItems.push(destItem);
      }
    }
  },

  createListItem: function(srcItem) {
    if (isEmpty(srcItem)) {
      console.error(`RenderTemplateHandler|addListItem(): Empty srcItem > ignoring list item.`)
      return;
    }

    let destItem = {};

    for (let key in srcItem) {
      switch (key) {
        case 'primaryText':
        case 'secondaryText':
        case 'tertiaryText':
          let text = srcItem[key];
          if (this.template.type === 'ListTemplate2' && key === 'tertiaryText') {
            console.error(`RenderTemplateHandler|afterStateMachine(): Attribute '${key}' not supported by '${this.template.type}' > ignoring attribute.`)
          } else {
            this.addText(text, key, destItem);
          }
          break;

        case 'image':
          let img = srcItem[key];
          if (img.indexOf('http') < 0) {
            // If image wasn't a URL, assume it's a file in assets and build the URL here.
            img = litexa.assetsRoot + `${this.myData.language}/` + img;
          }
          this.addImage(img, key, destItem)
          break;

        case 'token':
          destItem.token = srcItem['token'];
          break;

        default:
          console.error(`RenderTemplateHandler|afterStateMachine(): Unsupported attribute '${key}' found in list item ${JSON.stringify(srcItem)} > ignoring attribute.`)
          break;
      }
    }
    return destItem;
  },

  addDisplaySpeechAs: function(speech, type, delimiter = ' ') {
    const cleanSpeech = this.stripSpeechSSML(speech);

    switch (type) {
      case 'title':
        if (!isEmpty(this.template.title)) {
          this.template.title += delimiter;
        }
        this.template.title += cleanSpeech.join(' ');
        break;

      default:
        this.template.textContent = this.template.textContent || {};
        if (isEmpty(this.template.textContent[type])) {
          this.template.textContent[type] = {
            text: '',
            type: 'RichText'
          }
        }
        let target = this.template.textContent[type];
        if (!isEmpty(target.text)) {
          target.text += delimiter;
        }
        target.text += cleanSpeech.join('<br/><br/>');
        break;
    }
  },

  stripSpeechSSML: function(speech) {
    return speech.map(this.stripLineSSML);
  },

  stripLineSSML: function(line) {
    let res = '';
    if (line) {
      res = line.replace(/<[^>]+>/g, '');
      res = res.replace(/[ ]+/g, ' ');
    }
    return res;
  }
}