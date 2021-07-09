{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "purevue"
, dependencies =
  [ "arrays"
  , "console"
  , "control"
  , "effect"
  , "either"
  , "event"
  , "event-extra"
  , "filterable"
  , "foldable-traversable"
  , "foreign"
  , "foreign-generic"
  , "js-timers"
  , "maybe"
  , "now"
  , "prelude"
  , "psci-support"
  , "transformers"
  , "unsafe-coerce"
  , "unsafe-reference"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
