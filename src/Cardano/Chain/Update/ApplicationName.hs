{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE TemplateHaskell            #-}

module Cardano.Chain.Update.ApplicationName
       ( ApplicationName (..)
       , applicationNameMaxLength
       , checkApplicationName
       ) where

import           Cardano.Prelude

import           Control.Monad.Except (MonadError (throwError))
import           Data.Aeson (FromJSON (..))
import           Data.Aeson.TH (defaultOptions, deriveToJSON)
import           Data.Char (isAscii)
import qualified Data.Text as T
import           Formatting.Buildable (Buildable)

import           Cardano.Binary.Class (Bi (..))

newtype ApplicationName = ApplicationName
    { getApplicationName :: Text
    } deriving (Eq, Ord, Show, Generic, Typeable, ToString, Buildable, NFData)

instance Bi ApplicationName where
    encode appName = encode (getApplicationName appName)
    decode = ApplicationName <$> decode

instance FromJSON ApplicationName where
    -- FIXME does the defaultOptions derived JSON encode directly as text? Or
    -- as an object with a single key?
    parseJSON v = ApplicationName <$> parseJSON v

-- | Smart constructor of 'ApplicationName'.
checkApplicationName :: MonadError Text m => ApplicationName -> m ()
checkApplicationName (ApplicationName appName)
    | length appName > applicationNameMaxLength =
        throwError "ApplicationName: too long string passed"
    | T.any (not . isAscii) appName =
        throwError "ApplicationName: not ascii string passed"
    | otherwise = pure ()

applicationNameMaxLength :: Integral i => i
applicationNameMaxLength = 12

deriveToJSON defaultOptions ''ApplicationName
