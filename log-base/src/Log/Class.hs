-- | The 'MonadLog' type class of monads with logging capabilities.
module Log.Class (
    UTCTime
  , MonadLog(..)
  , getLoggerIO
  , logAttention
  , logInfo
  , logTrace
  , logAttention_
  , logInfo_
  , logTrace_
  ) where

import Control.Monad.Trans
import Control.Monad.Trans.Control
import Data.Aeson
import Data.Aeson.Types
import Data.Time
import Effectful.Monad
import Prelude
import qualified Data.Text as T

import Log.Data
import Log.Logger
import qualified Log.Effect as E

-- | Represents the family of monads with logging capabilities. Each
-- 'MonadLog' carries with it some associated state (the logging
-- environment) that can be modified locally with 'localData' and
-- 'localDomain'.
class Monad m => MonadLog m where
  -- | Write a message to the log.
  logMessage
    :: LogLevel -- ^ Log level.
    -> T.Text   -- ^ Log message.
    -> Value    -- ^ Additional data associated with the message.
    -> m ()
  -- | Extend the additional data associated with each log message locally.
  localData   :: [Pair] -> m a -> m a
  -- | Extend the current application domain locally.
  localDomain :: T.Text -> m a -> m a
  -- | Get current 'LoggerEnv' object. Useful for construction of logging
  -- functions that work in a different monad, see 'getLoggerIO' as an example.
  getLoggerEnv :: m LoggerEnv

instance E.Log :> es => MonadLog (Eff es) where
  logMessage   = E.logMessage
  localData    = E.localData
  localDomain  = E.localDomain
  getLoggerEnv = E.getLoggerEnv

-- | Generic, overlapping instance.
instance {-# OVERLAPPABLE #-} (
    MonadLog m
  , Monad (t m)
  , MonadTransControl t
  ) => MonadLog (t m) where
    logMessage level message = lift . logMessage level message
    localData data_ m = controlT $ \run -> localData data_ (run m)
    localDomain domain m = controlT $ \run -> localDomain domain (run m)
    getLoggerEnv = lift getLoggerEnv

controlT :: (MonadTransControl t, Monad (t m), Monad m)
         => (Run t -> m (StT t a)) -> t m a
controlT f = liftWith f >>= restoreT . return

----------------------------------------

-- | Return an IO action that logs messages using the current 'MonadLog'
-- context. Useful for interfacing with libraries such as @aws@ or @amazonka@
-- that accept logging callbacks operating in IO.
getLoggerIO :: MonadLog m => m (UTCTime -> LogLevel -> T.Text -> Value -> IO ())
getLoggerIO = logMessageIO <$> getLoggerEnv

-- | Log a message and its associated data using current time as the
-- event time and the 'LogAttention' log level.
logAttention :: (MonadLog m, ToJSON a) => T.Text -> a -> m ()
logAttention msg = logMessage LogAttention msg . toJSON

-- | Log a message and its associated data using current time as the
-- event time and the 'LogInfo' log level.
logInfo :: (MonadLog m, ToJSON a) => T.Text -> a -> m ()
logInfo msg = logMessage LogInfo msg . toJSON

-- | Log a message and its associated data using current time as the
-- event time and the 'LogTrace' log level.
logTrace :: (MonadLog m, ToJSON a) => T.Text -> a -> m ()
logTrace msg = logMessage LogTrace msg . toJSON

-- | Like 'logAttention', but without any additional associated data.
logAttention_ :: MonadLog m => T.Text -> m ()
logAttention_ = (`logAttention` emptyObject)

-- | Like 'logInfo', but without any additional associated data.
logInfo_ :: MonadLog m => T.Text -> m ()
logInfo_ = (`logInfo` emptyObject)

-- | Like 'logTrace', but without any additional associated data.
logTrace_ :: MonadLog m => T.Text -> m ()
logTrace_ = (`logTrace` emptyObject)
