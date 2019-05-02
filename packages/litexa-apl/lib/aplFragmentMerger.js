function isMergeableObject(val) {
  return isNonNullObject(val) && !isSpecial(val);
};

function isNonNullObject(val) {
  return !!val && typeof val === 'object';
}

function isSpecial(val) {
  const prototype = Object.getPrototypeOf(val);

  return prototype === RegExp.prototype
      || prototype === Date.prototype;
}

function emptyTarget(val) {
  return Array.isArray(val) ? [] : {};
}

function defaultArrayMerge(target, source, options) {
  return target.concat(source).map(function(element) {
    return cloneUnlessOtherwiseSpecified(element, options);
  })
}

function cloneUnlessOtherwiseSpecified(val, options) {
  return (options.clone !== false && options.isMergeableObject(val))
    ? deepMerge(emptyTarget(val), val, options)
    : val;
}

function mergeObject(target, source, options) {
  const destination = {};
  if (options.isMergeableObject(target)) {
    Object.keys(target).forEach(function(key) {
      destination[key] = cloneUnlessOtherwiseSpecified(target[key], options);
    });
  }
  Object.keys(source).forEach(function(key) {
    if (!options.isMergeableObject(source[key]) || !target[key]) {
      destination[key] = cloneUnlessOtherwiseSpecified(source[key], options);
    } else {
      destination[key] = getObjectMergeFunction(key, options)(target[key], source[key], options);
    }
  });
  return destination;
}

function getObjectMergeFunction(key, options) {
  if (!options.customMerge) {
    return deepMerge
  }
  let customMerge = options.customMerge(key);

  return (typeof(customMerge) === 'function') ? customMerge : deepMerge;
}

function deepMerge(target, source, options) {
  // The following 'options' are currently supported:
  //   arrayMerge ... custom array merge function
  //   customMerge ... function used to merge (should take two inputs, and produce one output)
  //   isMergeableObject ... custom function to determine whether object should be merged
  //   clone ... Boolean to determine whether to create clones of identical objects
  options = options || {};
  options.arrayMerge = options.arrayMerge || defaultArrayMerge;
  options.isMergeableObject = options.isMergeableObject || isMergeableObject;

  let sourceIsArray = Array.isArray(source);
  let targetIsArray = Array.isArray(target);
  let sourceAndTargetTypesMatch = sourceIsArray === targetIsArray;

  if (!sourceAndTargetTypesMatch) {
    return cloneUnlessOtherwiseSpecified(source, options);
  } else if (sourceIsArray) {
    return options.arrayMerge(target, source, options);
  } else {
    return mergeObject(target, source, options);
  }
}

module.exports = deepMerge;
