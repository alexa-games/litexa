const MAX_ARRAY_INDEX = Math.pow(2, 53) - 1;

function isEmpty(obj) {
  if (obj == null) // also checks for undefined
    return true;
  if (isArrayLike(obj) && (Array.isArray(obj) || typeof(obj) === 'string'))
    return obj.length === 0;
  return Object.keys(obj).length === 0;
}

function isArrayLike(collection) {
  let length = getLength(collection);
  return typeof(length == 'number') && length >= 0 && length <= MAX_ARRAY_INDEX;
}

const getLength = shallowProperty('length');

function shallowProperty(key) {
  return function(obj) {
    return obj == null ? void 0 : obj[key];
  };
}

module.exports = {
  isEmpty
}