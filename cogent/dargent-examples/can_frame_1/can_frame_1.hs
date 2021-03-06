--
-- Copyright 2019, Data61
-- Commonwealth Scientific and Industrial Research Organisation (CSIRO)
-- ABN 41 687 119 230.
--
-- This software may be distributed and modified according to the terms of
-- the GNU General Public License version 2. Note that NO WARRANTY is provided.
-- See "LICENSE_GPLv2.txt" for details.
--
-- @TAG(DATA61_GPL)
--

{-# LANGUAGE TemplateHaskell, QuasiQuotes, CPP, TupleSections #-}

module Main where

import Cogent.C (cgen)
import Cogent.Common.Types (Sigil(..))
import Cogent.Core (untypeD)
import Cogent.Dargent.Surface
import Cogent.Desugar (desugar)
import Cogent.Inference as Core (tc)
import Cogent.Mono (mono)
import Cogent.Normal (normal)
import Cogent.Quote
import Cogent.Surface
import Cogent.TypeCheck as Surface (tc)
import Text.PrettyPrint.ANSI.Leijen as L (pretty, putDoc)
#if MIN_VERSION_mainland_pretty(0,6,0)
import Text.PrettyPrint.Mainland as M (putDoc, line, (</>))
import Text.PrettyPrint.Mainland.Class as M (ppr)
#else
import Text.PrettyPrint.Mainland as M (ppr, putDoc, line, (</>))
#endif


tySArr = [decl|type SArr|]
tyCanId = [decl|type CanId = { id : U32, eff : U32, rtr : U32, err : U32 }|]
tyCanFrame = [decl|type CanFrame = { ident : CanId, prio : U8, dlc : U8, data : SArr }|]

tyCanId' = let TypeDec n vs t = tyCanId
               RT (TRecord rp fs _) = stripLocT t
            in TypeDec n vs $ dummyLocT $ RT $ TRecord rp fs (Boxed False $ Just (Layout lCanId))
tyCanFrame' = let TypeDec n vs t = tyCanFrame
                  RT (TRecord rp fs _) = stripLocT t
               in TypeDec n vs $ dummyLocT $ RT $ TRecord rp fs (Boxed False $ Just (Layout lCanFrame))

_b = Bits
_B = Bytes

canMaxDlc = 8

lCanId = [dexpr| record { id  : 29b
                        , eff : 1b at 30b
                        , rtr : 1b at 31b
                        , err : 1b at 32b
                        } |]

-- Dargent cannot mention constant definitions in Cogent / zilinc
lCanFrame = DLRecord [ ("ident", noPos, DLPrim (_B 8))
                     , ("prio" , noPos, DLOffset (DLPrim (_b 2)) (_B 8))
                     , ("dlc"  , noPos, DLOffset (DLPrim (_b 4)) (_B 8 `Add` _b 2))
                     , ("data" , noPos, DLOffset (DLPrim (_B canMaxDlc)) (_B 9))
                     ]

prog' = [decls|
can_EID_BITS : U32
can_EID_BITS = 18

can_EID_MASK : U32
can_EID_MASK = 0x3FFFF

get_sid_eid : CanFrame! -> (U32, U32)
get_sid_eid cframe =
  let eff = cframe.ident.eff
  and id = cframe.ident.id
   in if | eff /= 0 -> let sid = id >>  can_EID_BITS
                       and eid = id .&. can_EID_MASK
                        in (sid, eid)
         | else -> (id, 0)

|]

prog = tySArr : tyCanId' : tyCanFrame' : prog'

main = do
  ((resTc, _), tcSt) <- Surface.tc (map (noPos,) prog) []
  case resTc of
    Nothing -> error "Surface Tc failed"
    Just (tcProg, _) -> do
      L.putDoc $ L.pretty tcProg
      let ((dsProg, _), _) = desugar tcProg [] []
      case Core.tc dsProg of
        Left err -> error "Core Tc failed"
        Right (dsProg', _) -> do
          let anProg = normal $ map untypeD dsProg'
          case Core.tc anProg of
            Left err -> error "Core Tc failed"
            Right (anProg', _) -> do
              let ((fnMono, tyMono), (_, mnProg, _)) = mono anProg' [] Nothing
                  (h,c,_,_,_,_,_) = cgen "can_frame_1.h" [] "" "" mnProg Nothing [] ""
               in M.putDoc (ppr h </> M.line </> ppr c </> M.line)

