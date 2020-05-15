exports.setProp = name => val => vm => _ => {
  vm[name] = val
}

// extract the Authorization string from the axios object in vue instance
exports.getAxiosHeader = name => vm => _ => {
  return vm.$axios.defaults.headers.common[name]
}

exports.getCurrentUser = vm => _ => {
  return vm.$user()
}

exports.getEnv = name => _ => {
  let url = process.env[name]
  if (url) {
    return url
  } else {
    console.error(name + " is not defined in ENV")
    return undefined
  }
}

exports.routerPush = s => r => _ => {
  r.push(s)
}

exports.doEmit = s => vm => _ => {
  vm.$emit(s)
}

exports.doEmitVal = s => val => vm => _ => {
  vm.$emit(s, val)
}

exports.pushDefPropVal = name => vm => _ => {
  const p = vm[name]
  const f = vm[name + 'Push']

  if (f) f(p)()
}
