--experimental:strictFuncs

switch("mm", "arc")

when defined(release):
  switch("d", "danger")
  switch("opt", "size")
  switch("passL", "-s")
  switch("passC", "-flto")
  switch("passL", "-flto")

