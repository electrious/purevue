module Vue.PureComponent where

import Prelude

import Control.Monad.State (class MonadState, StateT, execStateT, modify_)
import Data.Array (cons)
import Data.Foldable (sequence_, traverse_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Generic (class Encode, encode)
import Vue.Common (VueData(..), VueMethod(..), VueProp(..), Name)
import Vue.VueInstance.Internal (Vue, VueInstance, defVueMethod, getDisposables, pushPropDef, runVue, setupDisposables)

-- | VueComponent record that should be the result provided to the
-- Vue component file.
type VueComponentRecord = {
    props         :: Array String,
    data          :: Unit -> Foreign,
    watch         :: Foreign,
    methods       :: Foreign,
    mounted       :: Effect Unit,
    beforeDestroy :: Effect Unit
}

foreign import buildDataRecord :: Array (VueData Foreign) -> Foreign
foreign import buildMethodRecord :: Array Name -> Foreign
foreign import buildWatchRecord :: Array Name -> Foreign
foreign import buildMountedFunc :: (VueInstance -> Effect Unit) -> Effect Unit
foreign import buildDestroyFunc :: (VueInstance -> Effect Unit) -> Effect Unit

-- | internal state to build the vue component
newtype VueComponent = VueComponent {
    props         :: Array String,
    dataFields    :: Array (VueData Foreign),
    methods       :: Array Name,
    mounted       :: Maybe (Vue Unit),
    beforeDestroy :: Maybe (Vue Unit)
}

-- | the monad to build a PureComponent in
newtype PureComponent a = PureComponent (StateT VueComponent Effect a)

derive newtype instance functorPureComponent :: Functor PureComponent
derive newtype instance applicativePureComponent :: Applicative PureComponent
derive newtype instance applyPureComponent :: Apply PureComponent
derive newtype instance bindPureComponent :: Bind PureComponent
derive newtype instance monadPureComponent :: Monad PureComponent
derive newtype instance monadStatePureComponent :: MonadState VueComponent PureComponent
derive newtype instance monadEffectPureComponent :: MonadEffect PureComponent

runPureComponent :: forall a. PureComponent a -> VueComponent -> Effect VueComponent
runPureComponent (PureComponent c) defC = execStateT c defC

-- | define the mount method of the component
mountWith :: forall a. Vue a -> PureComponent Unit
mountWith vueFunc = modify_ \(VueComponent s) -> VueComponent $ s { mounted = Just (void vueFunc) }

-- | define the beforeDestroy method of the component
destroyWith :: forall a. Vue a -> PureComponent Unit
destroyWith vueFunc = modify_ \(VueComponent s) -> VueComponent $ s { beforeDestroy = Just (void vueFunc) }

-- | define a Prop field in the Vue component
defProp :: forall a. Name -> PureComponent (VueProp a)
defProp name = do
    modify_ \(VueComponent s) -> VueComponent $ s { props = cons name s.props }
    pure $ VueProp name

-- | add a new Vue data reactive field to the component
defData :: forall a. Encode a => Name -> a -> PureComponent (VueData a)
defData name def = do
    let vd = VueData { name: name, value: def }
    modify_ \(VueComponent s) -> VueComponent $ s { dataFields = cons (encode <$> vd) s.dataFields }
    pure vd

-- | add a method to the pure vue component
defMethod :: forall a. Name -> PureComponent (VueMethod a)
defMethod name = do
    modify_ \(VueComponent s) -> VueComponent $ s { methods = cons name s.methods }
    pure $ VueMethod name

-- | Convert a PureComponent into the VueComponentRecord type that will be
-- provided to Vue.
pureComponent :: forall a. PureComponent a -> VueComponentRecord
pureComponent compBuilder = unsafePerformEffect do
    let defC = VueComponent {
                 props         : [],
                 dataFields    : [],
                 methods       : [],
                 mounted       : Nothing,
                 beforeDestroy : Nothing
               }
    
    -- run the builder
    (VueComponent c) <- runPureComponent compBuilder defC

    let dataFunc _ = buildDataRecord c.dataFields
        methodRec = buildMethodRecord c.methods
        watchRec = buildWatchRecord c.props

        mounted = buildMountedFunc \vc -> flip runVue vc do
                      setupDisposables []
                      -- define events and push methods for all props
                      traverse_ defVueMethod c.props
                      -- define methods and event on the vue instance after mounted
                      traverse_ defVueMethod c.methods
                      sequence_ c.mounted
                      traverse_ pushPropDef c.props

        toDestroy = buildDestroyFunc \vc -> flip runVue vc do
                        ds <- getDisposables
                        liftEffect $ sequence_ ds
                        sequence_ c.beforeDestroy
    pure {
        props         : c.props,
        data          : dataFunc,
        watch         : watchRec,
        methods       : methodRec,
        mounted       : mounted,
        beforeDestroy : toDestroy
    }
