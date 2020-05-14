{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "purevue"
, dependencies =
  [ "console"
  , "effect"
  , "event"
  , "event-extra"
  , "foreign"
  , "foreign-generic"
  , "psci-support"
  , "web-dom"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
