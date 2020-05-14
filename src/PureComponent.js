'use strict'

exports.buildDataRecord = arr => {
  const rec = {}

  arr.forEach(vueData => {
    rec[vueData.name] = vueData.value
  })

  return rec
}

exports.buildMethodRecord = function(arr) {
  const rec = {}
  arr.forEach(name => {
    rec[name] = function(v) {
      // when the method is called, find the event Push method defined on
      // the vue instance object and call it.
      const func = this[name + 'Push']
      if (func) func(v)()
    }
  })

  return rec
}

exports.buildWatchRecord = function(arr) {
  const rec = {}
  arr.forEach(name => {
    rec[name] = function(v) {
      const func = this[name + 'Push']
      if (func) func(v)()
    }
  })

  return rec
}

// Don't use arrow functions here. Arrow functions will set 'this' lexically
exports.buildMountedFunc = function(f) {
  return function() {
    f(this)()
  }
}

exports.buildDestroyFunc = function(f) {
  return function() {
    f(this)()
  }
}
