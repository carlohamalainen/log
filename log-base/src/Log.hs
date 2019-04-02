-- | Structured logging solution with multiple backends.
--
-- @
-- {-\# LANGUAGE OverloadedStrings #-}
--
-- module Main where
--
-- import Log
-- import Log.Backend.ElasticSearch
--
-- import System.Random
--
-- main :: IO ()
-- main = do
--   let config = 'Log.Backend.ElasticSearch.ElasticSearchConfig' {
--         esServer  = "http://localhost:9200",
--         esIndex   = "logs",
--         esMapping = "log"
--         }
--   'Log.Backend.ElasticSearch.withElasticSearchLogger' config randomIO $ \\logger -> do
--     'runLogT' "main" logger $ do
--       'logTrace_' "foo"
-- @
module Log (
    -- * Documentation
    -- | 'Log.Class.MonadLog' type class of monads with logging capabilities.
    module Log.Class
    -- | 'Log.Data.LogMessage' and 'Log.Data.LogLevel' data definitions.
  , module Log.Types
    -- | 'Log.Logger.Logger' objects used to perform logging
    -- operations in 'Control.Monad.Trans.LogT'.
  , module Log.Logger
    -- | 'Control.Monad.Trans.LogT' monad transformer that adds
    -- logging capabilities to the underlying monad.
  , module Control.Monad.Trans.Log
   -- * Aeson re-exports
  , object
  , (.=)
  ) where

import Data.Aeson

import Control.Monad.Trans.Log
import Log.Class
import Log.Logger
import Log.Types
