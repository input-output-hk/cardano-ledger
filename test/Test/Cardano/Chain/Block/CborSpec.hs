{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Chain.Block.CborSpec
       ( spec
       ) where

import           Cardano.Prelude

import           Test.Hspec (Spec, describe)
import           Test.Hspec.QuickCheck (modifyMaxSuccess)

import qualified Cardano.Chain.Block as Block

import           Test.Cardano.Binary.Helpers (binaryTest)
import           Test.Cardano.Chain.Block.Arbitrary ()
import           Test.Cardano.Core.Arbitrary ()

spec :: Spec
spec = describe "Cbor.Bi instances" $ do
        describe "Block types defined in the core package" $ do
              modifyMaxSuccess (min 10) $ describe "GenericBlockHeader" $ do
                  describe "GenesisBlockHeader" $ do
                      binaryTest @Block.GenesisBlockHeader
                  describe "MainBlockHeader" $ do
                      binaryTest @Block.MainBlockHeader
              describe "GenesisBlockchain" $ do
                  describe "BodyProof" $ do
                      binaryTest @Block.GenesisExtraHeaderData
                      binaryTest @Block.GenesisExtraBodyData
                      binaryTest @Block.GenesisProof
                  describe "ConsensusData" $ do
                      binaryTest @Block.GenesisConsensusData
                  describe "Body" $ do
                      binaryTest @Block.GenesisBody
              describe "MainBlockchain" $ do
                  describe "BodyProof" $ do
                      binaryTest @Block.MainProof
                  describe "BlockSignature" $ do
                      binaryTest @Block.BlockSignature
                  describe "ConsensusData" $ do
                      binaryTest @Block.MainConsensusData
                  modifyMaxSuccess (min 10) $ describe "Body" $ do
                      binaryTest @Block.MainBody
                  describe "MainToSign" $ do
                      binaryTest @Block.MainToSign
                  describe "Extra data" $ do
                      binaryTest @Block.MainExtraHeaderData
                      binaryTest @Block.MainExtraBodyData
