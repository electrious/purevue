exports.reset = v => _ => {
  v.$reset()
}

exports.touch = v => _ => {
  v.$touch()
}

exports.valid = v => {
  return !v.$invalid
}
