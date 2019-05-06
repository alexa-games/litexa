/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

class Board {
  constructor() {
    this.constructed = this.constructed || 0
    this.constructed += 1;
    this.focus = 0;
    console.log("Constructed board");
  }

  greeting() {
    return "Hello board";
  }

  getFocus() {
    return this.focus;
  }
}

var JSWrapperPrototype = {
  async fullName(prefix) {
    await this.ensureCache();
    return prefix + " " + this.cache.title + " " + this.data.first + " " + this.data.family
  },
  async ensureCache() {
    var wrapper = this;
    if (wrapper.cache.loaded) {
      return;
    }
    await new Promise((resolve, reject) => {
      wrapper.cache.title = 'Ms.';
      wrapper.cache.loaded = true;
      setTimeout(resolve, 200);
    });
  },
  async saveLoaded() {
    await this.ensureCache();
    this.data.loaded = this.cache.loaded;
  }
}

var JSWrapper = {
  Initialize() {
    return {
      first: "Lana",
      family: "Wrapsdottir"
    }
  },
  Prepare(obj) {
    var wrapper = Object.create(JSWrapperPrototype);
    wrapper.data = obj;
    wrapper.cache = {}
    return wrapper;
  }
}
