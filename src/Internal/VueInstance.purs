module Vue.VueInstance.Internal where

import Prelude

import Control.Monad.Except (runExcept)
import Control.Monad.Reader (class MonadAsk, class MonadReader, ReaderT, ask, runReaderT)
import Control.Plus (empty)
import Data.Either (Either(..))
import Data.Filterable (separate)
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import FRP.Event (Event, create)
import Foreign (F, Foreign)
import Foreign.Generic (class Decode, class Encode, decode, encode)
import Foreign.Index (readProp)
import Unsafe.Coerce (unsafeCoerce)
import Vue.Common (Name)

newtype VueInstance = VueInstance Foreign
type VueRouter = Foreign
type VueRouteParam = Foreign

-- | the monad to run any actions that require Vue instance
newtype Vue a = Vue (ReaderT VueInstance Effect a)

derive newtype instance functorVue :: Functor Vue
derive newtype instance applivativeVue :: Applicative Vue
derive newtype instance applyVue :: Apply Vue
derive newtype instance bindVue :: Bind Vue
derive newtype instance monadVue :: Monad Vue
derive newtype instance monadReaderVue :: MonadReader VueInstance Vue
derive newtype instance monadAskVue :: MonadAsk VueInstance Vue
derive newtype instance monadEffectVue :: MonadEffect Vue

runVue :: forall a. Vue a -> VueInstance -> Effect a
runVue (Vue a) = runReaderT a


-- | get header value from axios object in the underline vue instance
foreign import getAxiosHeader :: Name -> VueInstance -> Effect Foreign
foreign import getEnv :: Name -> Effect Foreign
foreign import getCurrentUser :: VueInstance -> Effect Foreign

-- | set a foreign value on the vue instance
foreign import setProp :: String -> Foreign -> VueInstance -> Effect Unit

-- | internal helper functions
foreign import routerPush :: String -> VueRouter -> Effect Unit
foreign import doEmit :: String -> VueInstance -> Effect Unit
foreign import doEmitVal :: String -> Foreign -> VueInstance -> Effect Unit
foreign import pushDefPropVal :: String -> VueInstance -> Effect Unit

-- | Set a property of the vue instance
setVueProp :: forall a. Encode a => String -> a -> Vue Unit
setVueProp name v = ask >>= setProp name (encode v) >>> liftEffect

-- | Set a property of the vue instance directly coercing the type change.
setVuePropUnsafe :: forall a. String -> a -> Vue Unit
setVuePropUnsafe name v = ask >>= setProp name (unsafeCoerce v) >>> liftEffect

-- | get a property of the vue instance
getVueProp :: forall a. Decode a => String -> Vue (F a)
getVueProp name = do
    (VueInstance vm) <- ask
    pure $ readProp name vm >>= decode

getVuePropUnsafe :: forall a. String -> Vue (F a)
getVuePropUnsafe name = do
    (VueInstance vm) <- ask
    pure $ unsafeCoerce <$> readProp name vm

-- | set all disposables onto a vue instance
setupDisposables :: Array (Effect Unit) -> Vue Unit
setupDisposables arr = setVuePropUnsafe "disposables" arr

-- | get all disposables on a vue instance
getDisposables :: Vue (Array (Effect Unit))
getDisposables = f <$> getVuePropUnsafe "disposables"
    where f d = case runExcept d of
                    Left _ -> []
                    Right v -> v

-- | internal function should only be used in PureComponent.
-- This function will create a new Event and its push function and set both of
-- them on the Vue instance.
defVueMethod :: String -> Vue Unit
defVueMethod name = do
    { event: valEvt, push: f } <- liftEffect create
    setVuePropUnsafe (name <> "Push") f
    setVuePropUnsafe (name <> "Evt") valEvt

-- | internal function to get the Event of a prop or method
getPropEvt :: forall a. Decode a => Name -> Vue (Event a)
getPropEvt name = do
    p <- getVuePropUnsafe (name <> "Evt")
    case runExcept p of
        Left _ -> pure empty
        Right v -> pure $ onlyRight $ runExcept <<< decode <$> v

-- | filter the Right value of Either in an event
onlyRight :: forall a e. Event (Either e a) -> Event a
onlyRight = f <<< separate
    where f v = v.right

-- | internal API to push default Prop values into the corresponding
-- prop Event
pushPropDef :: Name -> Vue Unit
pushPropDef name = ask >>= (liftEffect <<< pushDefPropVal name)
