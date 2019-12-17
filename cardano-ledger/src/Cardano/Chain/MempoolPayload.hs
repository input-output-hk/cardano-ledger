{-# LANGUAGE DeriveFunctor     #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}

module Cardano.Chain.MempoolPayload
  ( MempoolPayload (..)
  )
where

import Cardano.Prelude

import Cardano.Binary
  ( DecoderError(..)
  , FromCBORAnnotated(..)
  , ToCBOR(..)
  , decodeWord8
  , encodeListLen
  , enforceSize
  , AnnotatedDecoder(..)
  )
import qualified Cardano.Chain.Delegation as Delegation
import Cardano.Chain.UTxO (TxAux)
import qualified Cardano.Chain.Update as Update

-- | A payload which can be submitted into or between mempools via the
-- transaction submission protocol.
data MempoolPayload
  = MempoolTx !(TxAux)
  -- ^ A transaction payload (transaction and witness).
  | MempoolDlg !(Delegation.Certificate)
  -- ^ A delegation certificate payload.
  | MempoolUpdateProposal !(Update.Proposal)
  -- ^ An update proposal payload.
  | MempoolUpdateVote !(Update.Vote)
  -- ^ An update vote payload.
  deriving (Eq, Show)

instance ToCBOR MempoolPayload where
  toCBOR (MempoolTx tp) =
    encodeListLen 2 <> toCBOR (0 :: Word8) <> toCBOR tp
  toCBOR (MempoolDlg dp) =
    encodeListLen 2 <> toCBOR (1 :: Word8) <> toCBOR dp
  toCBOR (MempoolUpdateProposal upp) =
    encodeListLen 2 <> toCBOR (2 :: Word8) <> toCBOR upp
  toCBOR (MempoolUpdateVote upv) =
    encodeListLen 2 <> toCBOR (3 :: Word8) <> toCBOR upv

instance FromCBORAnnotated MempoolPayload where
  fromCBORAnnotated = AnnotatedDecoder $ do
    enforceSize "MempoolPayload" 2
    decodeWord8 >>= \case
      0   -> unwrapAnn $ MempoolTx             <$> fromCBORAnnotated
      1   -> unwrapAnn $ MempoolDlg            <$> fromCBORAnnotated
      2   -> unwrapAnn $ MempoolUpdateProposal <$> fromCBORAnnotated
      3   -> unwrapAnn $ MempoolUpdateVote     <$> fromCBORAnnotated
      tag -> cborError $ DecoderErrorUnknownTag "MempoolPayload" tag
