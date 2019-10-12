/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
