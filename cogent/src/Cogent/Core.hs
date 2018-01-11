--
-- Copyright 2017, NICTA
--
-- This software may be distributed and modified according to the terms of
-- the GNU General Public License version 2. Note that NO WARRANTY is provided.
-- See "LICENSE_GPLv2.txt" for details.
--
-- @TAG(NICTA_GPL)
--

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{- LANGUAGE DeriveDataTypeable -}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{- LANGUAGE InstanceSigs -}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LambdaCase #-}
#if __GLASGOW_HASKELL__ < 709
{-# LANGUAGE OverlappingInstances #-}
#endif
{-# LANGUAGE PatternGuards #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ViewPatterns #-}
{-# OPTIONS_GHC -fno-warn-orphans -fno-warn-missing-signatures #-}

module Cogent.Core where

import Cogent.Common.Syntax
import Cogent.Common.Types
import Cogent.Util
import Cogent.Vec hiding (splitAt, length, zipWith, zip, unzip)
import qualified Cogent.Vec as Vec

import Control.Arrow hiding ((<+>))
-- import Data.Data hiding (Refl)
#if __GLASGOW_HASKELL__ < 709
import Data.Traversable(traverse)
#endif
import Text.PrettyPrint.ANSI.Leijen as L hiding (tupled, indent, (<$>))
import qualified Text.PrettyPrint.ANSI.Leijen as L ((<$>))

data Type t
  = TVar (Fin t)
  | TVarBang (Fin t)
  | TCon TypeName [Type t] Sigil
  | TFun (Type t) (Type t)
  | TPrim PrimInt
  | TString
  | TSum [(TagName, (Type t, Bool))]  -- True means taken (since 2.0.4)
  | TProduct (Type t) (Type t)
  | TRecord [(FieldName, (Type t, Bool))] Sigil  -- True means taken
  | TUnit
  deriving (Show, Eq, Ord)

data SupposedlyMonoType = forall (t :: Nat). SMT (Type t)

isTFun :: Type t -> Bool
isTFun (TFun {}) = True
isTFun _ = False

isUnboxed :: Type t -> Bool
isUnboxed (TCon _ _ Unboxed) = True
isUnboxed (TRecord _ Unboxed) = True
isUnboxed _ = False

data FunNote = NoInline | InlineMe | MacroCall | InlinePlease  -- order is important, larger value has stronger precedence
             deriving (Bounded, Eq, Ord, Show)

data Expr t v a e
  = Variable (Fin v, a)
  | Fun FunName [Type t] FunNote  -- here do we want to keep partial application and infer again? / zilinc
  | Op Op [e t v a]
  | App (e t v a) (e t v a)
  | Con TagName (e t v a)
  | Unit
  | ILit Integer PrimInt
  | SLit String
  | Let a (e t v a) (e t ('Suc v) a)
  | LetBang [(Fin v, a)] a (e t v a) (e t ('Suc v) a)
  | Tuple (e t v a) (e t v a)
  | Struct [(FieldName, e t v a)]  -- unboxed record
  | If (e t v a) (e t v a) (e t v a)   -- technically no longer needed as () + () == Bool
  | Case (e t v a) TagName (Likelihood, a, e t ('Suc v) a) (Likelihood, a, e t ('Suc v) a)
  | Esac (e t v a)
  | Split (a, a) (e t v a) (e t ('Suc ('Suc v)) a)
  | Member (e t v a) FieldIndex
  | Take (a, a) (e t v a) FieldIndex (e t ('Suc ('Suc v)) a)
  | Put (e t v a) FieldIndex (e t v a)
  | Promote (Type t) (e t v a)
deriving instance (Show a, Show (e t v a), Show (e t ('Suc ('Suc v)) a), Show (e t ('Suc v) a)) => Show (Expr t v a e)
  -- constraint no smaller than header, thus UndecidableInstances

data UntypedExpr t v a = E  (Expr t v a UntypedExpr) deriving (Show)
data TypedExpr   t v a = TE { exprType :: Type t , exprExpr :: Expr t v a TypedExpr } deriving (Show)

data FunctionType = forall t. FT (Vec t Kind) (Type t) (Type t)
deriving instance Show FunctionType

data Attr = Attr { inlineDef :: Bool, fnMacro :: Bool } deriving (Eq, Ord, Show)

instance Monoid Attr where
  mempty = Attr False False
  (Attr a1 a2) `mappend` (Attr a1' a2') = Attr (a1 || a1') (a2 || a2')

data Definition e a
  = forall t. (Pretty a, Pretty (e t ('Suc 'Zero) a)) => FunDef  Attr FunName (Vec t (TyVarName, Kind)) (Type t) (Type t) (e t ('Suc 'Zero) a)
  | forall t. (Pretty a, Pretty (e t ('Suc 'Zero) a)) => AbsDecl Attr FunName (Vec t (TyVarName, Kind)) (Type t) (Type t)
  | forall t. (Pretty a, Pretty (e t ('Suc 'Zero) a)) => TypeDef TypeName (Vec t TyVarName) (Maybe (Type t))
deriving instance Show a => Show (Definition TypedExpr a)
deriving instance Show a => Show (Definition UntypedExpr a)

type CoreConst e = (VarName, e 'Zero 'Zero VarName)

getDefinitionId :: Definition e a -> String
getDefinitionId (FunDef  _ fn _ _ _ _) = fn
getDefinitionId (AbsDecl _ fn _ _ _  ) = fn
getDefinitionId (TypeDef tn _ _    ) = tn

getFuncId :: Definition e a -> Maybe FunName
getFuncId (FunDef  _ fn _ _ _ _) = Just fn
getFuncId (AbsDecl _ fn _ _ _  ) = Just fn
getFuncId _ = Nothing

getTypeVarNum :: Definition e a -> Int
getTypeVarNum (FunDef  _ _ tvs _ _ _) = Vec.toInt $ Vec.length tvs
getTypeVarNum (AbsDecl _ _ tvs _ _  ) = Vec.toInt $ Vec.length tvs
getTypeVarNum (TypeDef _ tvs _    ) = Vec.toInt $ Vec.length tvs

isDefinitionId :: String -> Definition e a -> Bool
isDefinitionId n d = n == getDefinitionId d

isFuncId :: String -> Definition e a -> Bool
isFuncId n (FunDef  _ fn _ _ _ _) = n == fn
isFuncId n (AbsDecl _ fn _ _ _  ) = n == fn
isFuncId _ _ = False

isAbsFun :: Definition e a -> Bool
isAbsFun (AbsDecl {}) = True
isAbsFun _ = False

isConFun :: Definition e a -> Bool
isConFun (FunDef {}) = True
isConFun _ = False

isTypeDef :: Definition e a -> Bool
isTypeDef (TypeDef {}) = True
isTypeDef _ = False

isAbsTyp :: Definition e a -> Bool
isAbsTyp (TypeDef _ _ Nothing) = True
isAbsTyp _ = False

traverseE :: (Applicative f) => (forall t v. e1 t v a -> f (e2 t v a)) -> Expr t v a e1 -> f (Expr t v a e2)
traverseE f (Variable v)         = pure $ Variable v
traverseE f (Fun fn tys nt)      = pure $ Fun fn tys nt
traverseE f (Op opr es)          = Op opr <$> traverse f es
traverseE f (App e1 e2)          = App <$> f e1 <*> f e2
traverseE f (Con cn e)           = Con cn <$> f e
traverseE f (Unit)               = pure $ Unit
traverseE f (ILit i pt)          = pure $ ILit i pt
traverseE f (SLit s)             = pure $ SLit s
traverseE f (Let a e1 e2)        = Let a  <$> f e1 <*> f e2
traverseE f (LetBang vs a e1 e2) = LetBang vs a <$> f e1 <*> f e2
traverseE f (Tuple e1 e2)        = Tuple <$> f e1 <*> f e2
traverseE f (Struct fs)          = Struct <$> traverse (traverse f) fs
traverseE f (If e1 e2 e3)        = If <$> f e1 <*> f e2 <*> f e3
traverseE f (Case e tn (l1,a1,e1) (l2,a2,e2)) = Case <$> f e <*> pure tn <*> ((l1, a1,) <$> f e1)  <*> ((l2, a2,) <$> f e2)
traverseE f (Esac e)             = Esac <$> (f e)
traverseE f (Split a e1 e2)      = Split a <$> (f e1) <*> (f e2)
traverseE f (Member rec fld)     = Member <$> (f rec) <*> pure fld
traverseE f (Take a rec fld e)   = Take a <$> (f rec) <*> pure fld <*> (f e)
traverseE f (Put rec fld v)      = Put <$> (f rec) <*> pure fld <*> (f v)
traverseE f (Promote ty e)       = Promote ty <$> (f e)

-- pre-order fold over Expr wrapper
foldEPre :: (Monoid b) => (forall t v. e1 t v a -> Expr t v a e1) -> (forall t v. e1 t v a -> b) -> e1 t v a -> b
foldEPre unwrap f e = case unwrap e of
  Variable{}          -> f e
  Fun{}               -> f e
  (Op _ es)           -> mconcat $ f e : map (foldEPre unwrap f) es
  (App e1 e2)         -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (Con _ e1)          -> f e `mappend` foldEPre unwrap f e1
  Unit                -> f e
  ILit{}              -> f e
  SLit{}              -> f e
  (Let _ e1 e2)       -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (LetBang _ _ e1 e2) -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (Tuple e1 e2)       -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (Struct fs)         -> mconcat $ f e : map (foldEPre unwrap f . snd) fs
  (If e1 e2 e3)       -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2, foldEPre unwrap f e3]
  (Case e1 _ (_,_,e2) (_,_,e3)) -> mconcat $ [f e, foldEPre unwrap f e1, foldEPre unwrap f e2, foldEPre unwrap f e3]
  (Esac e1)           -> f e `mappend` foldEPre unwrap f e1
  (Split _ e1 e2)     -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (Member e1 _)       -> f e `mappend` foldEPre unwrap f e1
  (Take _ e1 _ e2)    -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (Put e1 _ e2)       -> mconcat [f e, foldEPre unwrap f e1, foldEPre unwrap f e2]
  (Promote _ e1)      -> f e `mappend` foldEPre unwrap f e1

fmapE :: (forall t v. e1 t v a -> e2 t v a) -> Expr t v a e1 -> Expr t v a e2
fmapE f (Variable v)         = Variable v
fmapE f (Fun fn tys nt)      = Fun fn tys nt
fmapE f (Op opr es)          = Op opr (map f es)
fmapE f (App e1 e2)          = App (f e1) (f e2)
fmapE f (Con cn e)           = Con cn (f e)
fmapE f (Unit)               = Unit
fmapE f (ILit i pt)          = ILit i pt
fmapE f (SLit s)             = SLit s
fmapE f (Let a e1 e2)        = Let a (f e1) (f e2)
fmapE f (LetBang vs a e1 e2) = LetBang vs a (f e1) (f e2)
fmapE f (Tuple e1 e2)        = Tuple (f e1) (f e2)
fmapE f (Struct fs)          = Struct (map (second f) fs)
fmapE f (If e1 e2 e3)        = If (f e1) (f e2) (f e3)
fmapE f (Case e tn (l1,a1,e1) (l2,a2,e2)) = Case (f e) tn (l1, a1, f e1) (l2, a2, f e2)
fmapE f (Esac e)             = Esac (f e)
fmapE f (Split a e1 e2)      = Split a (f e1) (f e2)
fmapE f (Member rec fld)     = Member (f rec) fld
fmapE f (Take a rec fld e)   = Take a (f rec) fld (f e)
fmapE f (Put rec fld v)      = Put (f rec) fld (f v)
fmapE f (Promote ty e)       = Promote ty (f e)

untypeE :: TypedExpr t v a -> UntypedExpr t v a
untypeE (TE _ e) = E $ fmapE untypeE e

untypeD :: Definition TypedExpr a -> Definition UntypedExpr a
untypeD (FunDef  attr fn ts ti to e) = FunDef  attr fn ts ti to (untypeE e)
untypeD (AbsDecl attr fn ts ti to  ) = AbsDecl attr fn ts ti to
untypeD (TypeDef tn ts mt) = TypeDef tn ts mt

instance (Functor (e t v), Functor (e t ('Suc v)), Functor (e t ('Suc ('Suc v)))) => Functor (Flip (Expr t v) e) where
  fmap f (Flip (Variable v)         ) = Flip $ Variable (second f v)
  fmap f (Flip (Fun fn tys nt)      ) = Flip $ Fun fn tys nt
  fmap f (Flip (Op opr es)          ) = Flip $ Op opr (map (fmap f) es)
  fmap f (Flip (App e1 e2)          ) = Flip $ App (fmap f e1) (fmap f e2)
  fmap f (Flip (Con cn e)           ) = Flip $ Con cn (fmap f e)
  fmap f (Flip (Unit)               ) = Flip $ Unit
  fmap f (Flip (ILit i pt)          ) = Flip $ ILit i pt
  fmap f (Flip (SLit s)             ) = Flip $ SLit s
  fmap f (Flip (Let a e1 e2)        ) = Flip $ Let (f a) (fmap f e1) (fmap f e2)
  fmap f (Flip (LetBang vs a e1 e2) ) = Flip $ LetBang (map (second f) vs) (f a) (fmap f e1) (fmap f e2)
  fmap f (Flip (Tuple e1 e2)        ) = Flip $ Tuple (fmap f e1) (fmap f e2)
  fmap f (Flip (Struct fs)          ) = Flip $ Struct (map (second $ fmap f) fs)
  fmap f (Flip (If e1 e2 e3)        ) = Flip $ If (fmap f e1) (fmap f e2) (fmap f e3)
  fmap f (Flip (Case e tn (l1,a1,e1) (l2,a2,e2))) = Flip $ Case (fmap f e) tn (l1, f a1, fmap f e1) (l2, f a2, fmap f e2)
  fmap f (Flip (Esac e)             ) = Flip $ Esac (fmap f e)
  fmap f (Flip (Split a e1 e2)      ) = Flip $ Split ((f *** f) a) (fmap f e1) (fmap f e2)
  fmap f (Flip (Member rec fld)     ) = Flip $ Member (fmap f rec) fld
  fmap f (Flip (Take a rec fld e)   ) = Flip $ Take ((f *** f) a) (fmap f rec) fld (fmap f e)
  fmap f (Flip (Put rec fld v)      ) = Flip $ Put (fmap f rec) fld (fmap f v)
  fmap f (Flip (Promote ty e)       ) = Flip $ Promote ty (fmap f e)

instance Functor (TypedExpr t v) where
  fmap f (TE t e) = TE t $ ffmap f e

-- instance Functor (Definition TypedExpr) where
--   fmap f (FunDef  attr fn ts ti to e) = FunDef  attr fn ts ti to (fmap f e)
--   fmap f (AbsDecl attr fn ts ti to)   = AbsDecl attr fn ts ti to
--   fmap f (TypeDef tn ts mt)      = TypeDef tn ts mt
-- 
-- stripNameTD :: Definition TypedExpr VarName -> Definition TypedExpr ()
-- stripNameTD = fmap $ const ()


-- /////////////////////////////////////////////////////////////////////////////
-- Core-lang pretty-printing

indentation, ifIndentation :: Int
indentation = 3
ifIndentation = 3
position = string
varName = string
primop = blue . (pretty :: Op -> Doc)
keyword = bold . string
typevar = blue . string
typename = blue . bold . string
literal = dullcyan
typesymbol = cyan . string
kind = bold . typesymbol
funName = dullyellow . string
fieldName = magenta . string
fieldIndex = magenta . string . ('.':) . show
tagName = dullmagenta . string
symbol = string
kindsig = red . string
commaList = encloseSep empty empty (comma L.<> space)
dotList = encloseSep empty empty (symbol ".")
tupled = encloseSep lparen rparen (comma L.<> space)
tupled1 [x] = x
tupled1 x = encloseSep lparen rparen (comma L.<> space) x
typeargs x = encloseSep lbracket rbracket (comma L.<> space) x
err = red . string
comment = black . string
context = black . string
letbangvar = dullgreen . string
record = encloseSep (lbrace L.<> space) (space L.<> rbrace) (comma L.<> space)
variant = encloseSep (langle L.<> space) rangle (symbol "|" L.<> space) . map (L.<> space)
indent = nest indentation

level :: Associativity -> Int
level (LeftAssoc i) = i
level (RightAssoc i) = i
level (NoAssoc i) = i
level (Prefix) = 0

levelE :: Expr t v a e -> Int
levelE (Op opr [_,_]) = level (associativity opr)
levelE (ILit {}) = 0
levelE (Variable {}) = 0
levelE (Fun {}) = 0
levelE (App {}) = 1
levelE (Tuple {}) = 0
levelE (Con {}) = 0
levelE (Esac {}) = 0
levelE (Member {}) = 0
levelE (Take {}) = 0
levelE (Put {}) = 1
levelE (Promote {}) = 0
levelE _ = 100

class Pretty a => PrettyP a where
  prettyP :: Int -> a -> Doc

instance (Pretty (Expr t v a e)) => PrettyP (Expr t v a e) where
  prettyP l x | levelE x < l   = pretty x
              | otherwise = parens (pretty x)

instance (Pretty a, Pretty (TypedExpr t v a)) => PrettyP (TypedExpr t v a) where
  prettyP i (TE _ x) = prettyP i x
instance (Pretty a, Pretty (UntypedExpr t v a)) => PrettyP (UntypedExpr t v a) where
  prettyP i (E x) = prettyP i x

instance Pretty Likelihood where
  pretty Likely = symbol "=>"
  pretty Unlikely = symbol "~>"
  pretty Regular = symbol "->"

-- prettyL :: Likelihood -> Doc
-- prettyL Likely = symbol "+%"
-- prettyL Regular = empty
-- prettyL Unlikely = symbol "-%"

prettyV = dullblue  . string . ("_v" ++) . show . finInt
prettyT = dullgreen . string . ("_t" ++) . show . finInt

instance Pretty a => Pretty (TypedExpr t v a) where
  pretty (TE _ e) = pretty e
instance Pretty a => Pretty (UntypedExpr t v a) where
  pretty (E e) = pretty e

instance (Pretty a, PrettyP (e t v a), Pretty (e t ('Suc v) a), Pretty (e t ('Suc ('Suc v)) a))
         => Pretty (Expr t v a e) where
  pretty (Op opr [a,b])
     | LeftAssoc  l <- associativity opr = prettyP (l+1) a <+> primop opr <+> prettyP l b
     | RightAssoc l <- associativity opr = prettyP l a <+> primop opr <+> prettyP (l+1)  b
     | NoAssoc    l <- associativity opr = prettyP l a <+> primop opr <+> prettyP l  b
  pretty (Op opr [e]) = primop opr <+> prettyP 1 e
  pretty (Op opr es)  = primop opr <+> tupled (map pretty es)
  pretty (ILit i pt) = literal (string $ show i) <+> symbol "::" <+> pretty pt
  pretty (SLit s) = literal $ string s
  pretty (Variable x) = pretty (snd x) L.<> angles (prettyV $ fst x)
  pretty (Fun fn ins nt) = pretty nt L.<> funName fn <+> pretty ins
  pretty (App a b) = prettyP 2 a <+> prettyP 1 b
  pretty (Let a e1 e2) = align (keyword "let" <+> pretty a <+> symbol "=" <+> pretty e1 L.<$>
                                keyword "in" <+> pretty e2)
  pretty (LetBang bs a e1 e2) = align (keyword "let!" <+> tupled (map (prettyV . fst) bs) <+> pretty a <+> symbol "=" <+> pretty e1 L.<$>
                                       keyword "in" <+> pretty e2)
  pretty (Unit) = tupled []
  pretty (Tuple e1 e2) = tupled (map pretty [e1, e2])
  pretty (Struct fs) = symbol "#" L.<> record (map (\(n,e) -> fieldName n <+> symbol "=" <+> pretty e) fs)
  pretty (Con tn e) = tagName tn <+> prettyP 1 e
  pretty (If c t e) = group . align $ (keyword "if" <+> pretty c
                                       L.<$> indent (keyword "then" </> align (pretty t))
                                       L.<$> indent (keyword "else" </> align (pretty e)))
  pretty (Case e tn (l1,_,a1) (l2,_,a2)) = align (keyword "case" <+> pretty e <+> keyword "of"
                                                  L.<$> indent (tagName tn <+> pretty l1 <+> align (pretty a1))
                                                  L.<$> indent (symbol "*" <+> pretty l2 <+> align (pretty a2)))
  pretty (Esac e) = keyword "esac" <+> parens (pretty e)
  pretty (Split _ e1 e2) = align (keyword "split" <+> pretty e1 L.<$>
                                  keyword "in" <+> pretty e2)
  pretty (Member x f) = prettyP 1 x L.<> symbol "." L.<> fieldIndex f
  pretty (Take (a,b) rec f e) = align (keyword "take" <+> tupled [pretty a, pretty b] <+> symbol "="
                                                      <+> prettyP 1 rec <+> record (fieldIndex f:[]) L.<$>
                                       keyword "in" <+> pretty e)
  pretty (Put rec f v) = prettyP 1 rec <+> record [fieldIndex f <+> symbol "=" <+> pretty v]
  pretty (Promote t e) = prettyP 1 e <+> symbol "::" <+> pretty t

instance Pretty FunNote where
  pretty NoInline = empty
  pretty InlineMe = comment "{-# INLINE #-}" <+> empty
  pretty MacroCall = comment "{-# FNMACRO #-}" <+> empty
  pretty InlinePlease = comment "inline" <+> empty

instance Pretty (Type t) where
  pretty (TVar v) = prettyT v
  pretty (TVarBang v) = prettyT v L.<> typesymbol "!"
  pretty (TPrim pt) = pretty pt
  pretty (TString) = typename "String"
  pretty (TUnit) = typename "()"
  pretty (TProduct t1 t2) = tupled (map pretty [t1, t2])
  pretty (TSum alts) = variant (map (\(n,(t,_)) -> tagName n <+> pretty t) alts)  -- FIXME: cogent.1
  pretty (TFun t1 t2) = prettyT' t1 <+> typesymbol "->" <+> pretty t2
     where prettyT' e@(TFun {}) = parens (pretty e)
           prettyT' e           = pretty e
  pretty (TRecord fs s) = record (map (\(f,(t,b)) -> fieldName f <+> symbol ":" L.<> prettyTaken b <+> pretty t) fs) L.<> pretty s
  pretty (TCon tn [] s) = typename tn L.<> pretty s
  pretty (TCon tn ts s) = typename tn L.<> pretty s <+> typeargs (map pretty ts)

prettyTaken :: Bool -> Doc
prettyTaken True  = symbol "*"
prettyTaken False = empty

instance Pretty Sigil where
  pretty Writable = empty
  pretty ReadOnly = typesymbol "!"
  pretty Unboxed  = typesymbol "#"

#if __GLASGOW_HASKELL__ < 709
instance Pretty (TyVarName, Kind) where
#else
instance {-# OVERLAPPING #-} Pretty (TyVarName, Kind) where
#endif
  pretty (v,k) = pretty v L.<> typesymbol ":<" L.<> pretty k

instance Pretty Kind where
  pretty (K False False False) = string "()"
  pretty (K e s d) = if e then kind "E" else empty L.<>
                         if s then kind "S" else empty L.<>
                         if d then kind "D" else empty

instance Pretty a => Pretty (Vec t a) where
  pretty Nil = empty
  pretty (Cons x Nil) = pretty x
  pretty (Cons x xs) = pretty x L.<> string "," <+> pretty xs

instance Pretty (Definition e a) where
  pretty (FunDef _ fn ts t rt e) = funName fn <+> symbol ":" <+> brackets (pretty ts) L.<> symbol "." <+>
                                   parens (pretty t) <+> symbol "->" <+> parens (pretty rt) <+> symbol "=" L.<$>
                                   pretty e
  pretty (AbsDecl _ fn ts t rt) = funName fn <+> symbol ":" <+> brackets (pretty ts) L.<> symbol "." <+>
                                  parens (pretty t) <+> symbol "->" <+> parens (pretty rt)
  pretty (TypeDef tn ts Nothing) = keyword "type" <+> typename tn <+> pretty ts
  pretty (TypeDef tn ts (Just t)) = keyword "type" <+> typename tn <+> pretty ts <+>
                                    symbol "=" <+> pretty t


