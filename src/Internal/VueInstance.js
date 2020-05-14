exports.setProp = name => val => vm => _ => {
  vm[name] = val
}

// extract the Authorization string from the axios object in vue instance
exports.getAuthString = vm => _ => {
  return vm.$axios.defaults.headers.common.Authorization
}

exports.getXUserId = vm => _ => {
  return vm.$axios.defaults.headers.common['x-user-id']
}

exports.getCurrentUser = vm => _ => {
  return vm.$user()
}

exports.getBaseUrl = _ => {
  return process.env.API_BASE_URL
}

exports.getAWSBucket = _ => {
  return process.env.AWS_S3_BUCKET
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
