module Vue.VueInstance (module Vue, dispose, doSubscribe, runEvent,
    bindEvent, methodEvent, propEvent, runVueEvent, routeToPage,
    getRouteParam, getValidator, emitValue, emitString,
    emitStringEvent, emitValueEvent) where

import Prelude

import Control.Monad.Except (runExcept)
import Control.Monad.Reader (ask)
import Data.Array (cons)
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import FRP.Event (Event, subscribe)
import FRP.Event.Extra (performEvent)
import Foreign (F)
import Foreign.Generic (class Decode, class Encode, decode, encode)
import Foreign.Index (readProp)
import Vue.Common (VueData(..), VueMethod(..), VueProp(..))
import Vue.Validator (Validator)
import Vue.VueInstance.Internal (Vue) as Vue
import Vue.VueInstance.Internal (Vue, VueInstance(..), doEmit, doEmitVal, getDisposables, getPropEvt, getVuePropUnsafe, routerPush, runVue, setProp, setupDisposables)

-- | setup an action to run when the component is destroyed
dispose :: forall a. Effect a -> Vue Unit
dispose act = do
    ds <- getDisposables
    setupDisposables $ cons (void act) ds

-- | helper function to subscribe an event and dispose the subscription
-- when the component is destroyed
doSubscribe :: forall a r. Event a -> (a -> Effect r) -> Vue Unit
doSubscribe evt func = liftEffect (subscribe evt func) >>= dispose

-- | subscribe an event and discard the result. The subscription will be
-- disposed when the component is destroyed
runEvent :: forall a. Event a -> Vue Unit
runEvent evt = doSubscribe evt (const $ pure unit)

-- | Bind an Event into a data field in the component
bindEvent :: forall a. Encode a => VueData a -> Event a -> Vue Unit
bindEvent (VueData {name}) evt = do
    vm <- ask
    doSubscribe evt (\v -> setProp name (encode v) vm)

-- | get the Event that will be fired when the defined method is called
methodEvent :: forall a. Decode a => VueMethod a -> Vue (Event a)
methodEvent (VueMethod name) = getPropEvt name

-- | get the Event that will be fired when the prop is updated
propEvent :: forall a. Decode a => VueProp a -> Vue (Event a)
propEvent (VueProp name) = getPropEvt name

runVueEvent :: forall a. Event (Vue a) -> Vue (Event a)
runVueEvent evt = do
    vm <- ask
    pure $ performEvent $ flip runVue vm <$> evt

-- | API to route to a new page
routeToPage :: String -> Vue Unit
routeToPage page = do
    (VueInstance vm) <- ask
    let r = runExcept $ readProp "$router" vm
    case r of
        Left err -> liftEffect $ logShow $ "error reading vm.$router: " <> show err
        Right router -> liftEffect $ routerPush page router

getRouteParam :: forall res. Decode res => String -> Vue (F res)
getRouteParam name = do
    (VueInstance vm) <- ask
    pure $ readProp "$route" vm >>= readProp "params" >>= readProp name >>= decode

getValidator :: Vue (F Validator)
getValidator = getVuePropUnsafe "$v"

emitString :: String -> Vue Unit
emitString v = ask >>= (liftEffect <<< doEmit v)

emitValue :: forall a. Encode a => String -> a -> Vue Unit
emitValue name v = ask >>= (liftEffect <<< doEmitVal name (encode v))

emitStringEvent :: Event String -> Vue Unit
emitStringEvent v = ask >>= (doSubscribe v <<< flip doEmit)

emitValueEvent :: forall a. Encode a => String -> Event a -> Vue Unit
emitValueEvent name vEvt = do
    vm <- ask
    doSubscribe vEvt \v -> doEmitVal name (encode v) vm
