module Vue.Validator where

import Prelude

import Effect (Effect)
import Foreign (Foreign)

type Validator = Foreign

foreign import reset :: Validator -> Effect Unit
foreign import touch :: Validator -> Effect Unit
foreign import valid :: Validator -> Boolean