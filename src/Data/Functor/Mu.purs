module Data.Functor.Mu
  ( Mu(..)
  , roll
  , unroll
  , transMu
  ) where

import Prelude
import Data.TacitString as TS

import Data.Eq (class Eq1, eq1)
import Data.Newtype (class Newtype)
import Data.Ord (class Ord1, compare1)

-- | `Mu f` is the least fixed point of a functor `f`, when it exists.
newtype Mu f = In (f (Mu f))

-- | Rewrites a tree along a natural transformation.
transMu
  ∷ ∀ f g
  . (Functor g)
  ⇒ (∀ a. f a → g a)
  → Mu f
  → Mu g
transMu η =
  roll
    <<< map (transMu η)
    <<< η
    <<< unroll

roll :: forall f. f (Mu f) -> Mu f
roll = In

unroll :: forall f. Mu f -> f (Mu f)
unroll (In x) = x

derive instance newtypeMu :: Newtype (Mu f) _

-- | To implement `Eq`, we require `f` to have higher-kinded equality.
instance eqMu :: Eq1 f => Eq (Mu f) where
  eq (In x) (In y) = eq1 x y

-- | To implement `Ord`, we require `f` to have higher-kinded comparison.
instance ordMu :: (Eq1 f, Ord1 f) => Ord (Mu f) where
  compare (In x) (In y) = compare1 x y

-- | `Show` is compositional, so we only `f` to be able to show a single layer of structure.
-- Therefore, there is no need for `Show1`; we use `TacitString` in order to prevent
-- extra quotes from appearing.
instance showMu :: (Show (f TS.TacitString), Functor f) => Show (Mu f) where
  show (In x) = show $ x <#> (show >>> TS.hush)

-- | catamorphism: apply the function for the bottom up
cata :: forall f a. Functor f => (f a -> a) -> Mu f -> a
cata f =
  f
  <<< map (cata f)
  <<< unroll
