--experimental:strictFuncs

switch("mm", "arc")

when defined(release):
  switch("d", "danger")
  switch("opt", "size")
  switch("panics", "on")
  switch("passL", "-s")
  switch("passC", "-flto=auto")
  switch("passL", "-flto=auto")

