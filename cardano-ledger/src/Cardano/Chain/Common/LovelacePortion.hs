{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NumDecimals                #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE UndecidableInstances       #-}

module Cardano.Chain.Common.LovelacePortion
  ( LovelacePortion
  , rationalToLovelacePortion
  , lovelacePortionToRational
  )
where

import Cardano.Prelude

import Control.Monad (fail)
import Control.Monad.Except (MonadError(..))
import Formatting (sformat, build, bprint, float, int)
import qualified Formatting.Buildable as B
import Text.JSON.Canonical (FromJSON(..), ToJSON(..))

import Cardano.Binary (FromCBOR(..), ToCBOR(..))


-- | LovelacePortion is some portion of Lovelace; it is interpreted as a fraction with
--   denominator of 'lovelacePortionDenominator'. The numerator must be in the
--   interval of [0, lovelacePortionDenominator].
--
--   Usually 'LovelacePortion' is used to determine some threshold expressed as
--   portion of total stake.
--
--   To multiply a lovelace portion by 'Lovelace', use 'applyLovelacePortionDown' (when
--   calculating number of lovelace) or 'applyLovelacePortionUp' (when calculating a
--   threshold).
newtype LovelacePortion = LovelacePortion
  { getLovelacePortion :: Word64
  } deriving (Show, Ord, Eq, Generic, HeapWords, NFData, NoUnexpectedThunks)

instance B.Buildable LovelacePortion where
  build cp@(LovelacePortion x) = bprint
    (int . "/" . int . " (approx. " . float . ")")
    x
    lovelacePortionDenominator
    (fromRational (lovelacePortionToRational cp) :: Double)

instance ToCBOR LovelacePortion where
  toCBOR = toCBOR . getLovelacePortion

instance FromCBOR LovelacePortion where
  fromCBOR = do
    nominator <- fromCBOR
    when (nominator > lovelacePortionDenominator) $
      fail "LovelacePortion: value out of bounds [0..1e15]"
    return (LovelacePortion nominator)

-- The Canonical and Aeson instances for LovelacePortion are inconsistent -
-- Canonical reads/writes an integer, but Aeson reads/write a Real in range [0,1]
-- This is because 'canonical-json' only supports numbers of type @Int54@.
instance Monad m => ToJSON m LovelacePortion where
  toJSON = toJSON . getLovelacePortion

instance MonadError SchemaError m => FromJSON m LovelacePortion where
  fromJSON val = do
    nominator <- fromJSON val
    when (nominator > lovelacePortionDenominator) $
      throwError SchemaError {
        seExpected = "LovelacePortion integer in bounds [0..1e15]",
        seActual   = Just (sformat build nominator)
      }
    pure (LovelacePortion nominator)

-- | Denominator used by 'LovelacePortion'.
lovelacePortionDenominator :: Word64
lovelacePortionDenominator = 1e15

rationalToLovelacePortion :: Rational -> LovelacePortion
rationalToLovelacePortion r
  | r >= 0 && r <= 1 = LovelacePortion
                         (ceiling (r * toRational lovelacePortionDenominator))
  | otherwise        = panic "rationalToLovelacePortion: out of range [0..1]"

lovelacePortionToRational :: LovelacePortion -> Rational
lovelacePortionToRational (LovelacePortion n) =
  toInteger n % toInteger lovelacePortionDenominator

