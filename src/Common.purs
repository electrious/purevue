module Vue.Common where

import Prelude

type Name = String

newtype VueProp a = VueProp Name
newtype VueMethod a = VueMethod Name

newtype VueData a = VueData {
    name  :: Name,
    value :: a
}

instance functorVueData :: Functor VueData where
    map f (VueData vd) = VueData $ vd { value = f vd.value }
