{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module FFI where

import Foreign
import Foreign.Ptr
import Foreign.C.String
import Foreign.C.Types

import Util

#include "wa_wrapper_pp_inferred.c"

#enum Tag, Tag, TAG_ENUM_Break, TAG_ENUM_Error, TAG_ENUM_Iterate, TAG_ENUM_Success

data CWordArray a = CWordArray { len :: CInt, values :: Ptr a }

data Ct1 = Ct1 { p1 :: Ptr (CWordArray Cu8)
               , p2 :: Ptr (CWordArray Cu8)
               , p3 :: Cu32
               , p4 :: Cu32
               , p5 :: Cu32 }

data Ct2 = Ct2 { p1 :: Ptr (CWordArray Cu8), p2 :: Cu32 }

data Ct3 = Ct3 { p1 :: Ptr CSysState, p2 :: Ptr (CWordArray Cu8) }

data Ct4 = Ct4 { p1 :: Ptr CSysState, p2 :: Cu32 }

data Ct5 = Ct5 { tag :: Ctag_t, error :: Ptr CSysState, success :: Ct3 }



instance Storable a => Storable (CWordArray a) where
  sizeOf    _ = 16
  alignment _ = 8
  peek ptr = CWordArray <$> (\p -> peekByteOff p 0 ) ptr
                        <*> (\p -> peekByteOff p 8 ) ptr
  poke ptr (CWordArray f1 f2) = do
    (\p -> pokeByteOff p 0 ) ptr f1
    (\p -> pokeByteOff p 8 ) ptr f2

instance Storable Ct1 where
  sizeOf    _ = (#size t1)
  alignment _ = (#alignment t1)
  peek ptr = Ct1 <$> (#peek t1, p1) ptr
                 <*> (#peek t1, p2) ptr
                 <*> (#peek t1, p3) ptr
                 <*> (#peek t1, p4) ptr
                 <*> (#peek t1, p5) ptr
  poke ptr (Ct1 p1 p2 p3 p4 p5) = do
    (#poke t1, p1) ptr p1
    (#poke t1, p2) ptr p2
    (#poke t1, p3) ptr p3
    (#poke t1, p4) ptr p4
    (#poke t1, p5) ptr p5

instance Storable Ct2 where
  sizeOf    _ = (#size t2)
  alignment _ = (#alignment t2)
  peek ptr = Ct2 <$> (#peek t2, p1) ptr <*> (#peek t2, p2) ptr
  poke ptr (Ct2 p1 p2) = do
    (#poke t2, p1) ptr p1
    (#poke t2, p2) ptr p2

instance Storable Ct3 where
  sizeOf    _ = (#size t3)
  alignment _ = (#alignment t3)
  peek ptr = Ct3 <$> (#peek t3, p1) ptr <*> (#peek t3, p2) ptr
  poke ptr (Ct3 p1 p2) = do
    (#poke t3, p1) ptr p1
    (#poke t3, p2) ptr p2

instance Storable Ct4 where
  sizeOf    _ = (#size t4)
  alignment _ = (#alignment t4)
  peek ptr = Ct4 <$> (#peek t4, p1) ptr <*> (#peek t4, p2) ptr
  poke ptr (Ct4 p1 p2) = do
    (#poke t4, p1) ptr p1
    (#poke t4, p2) ptr p2

instance Storable Ct5 where
  sizeOf    _ = (#size t5)
  alignment _ = (#alignment t5)
  peek ptr = Ct5 <$> (#peek t5, tag) ptr <*> (#peek t5, Error) ptr <*> (#peek t5, Success)
  poke ptr (Ct5 f1 f2 f3) = do
    (#poke t5, tag    ) ptr f1
    (#poke t5, Error  ) ptr f2
    (#poke t5, Success) ptr f3
