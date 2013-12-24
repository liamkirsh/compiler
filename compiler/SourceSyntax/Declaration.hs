module SourceSyntax.Declaration where

import Data.Binary
import qualified SourceSyntax.Expression as Expr
import SourceSyntax.Type
import SourceSyntax.PrettyPrint
import Text.PrettyPrint as P

data Declaration tipe var
    = Definition (Expr.Def tipe var)
    | Datatype String [String] [(String,[Type])] [Derivation]
    | TypeAlias String [String] Type [Derivation]
    | ImportEvent String (Expr.LExpr tipe var) String Type
    | ExportEvent String String Type
    | Fixity Assoc Int String
      deriving (Eq, Show)

data Assoc = L | N | R
    deriving (Eq)

data Derivation = Json | Binary | RecordConstructor
    deriving (Eq, Show)

instance Binary Derivation where
  get = do n <- getWord8
           return $ case n of
             0 -> Json
             1 -> Binary
             2 -> RecordConstructor

  put derivation =
      case derivation of
        Json              -> putWord8 0
        Binary            -> putWord8 1
        RecordConstructor -> putWord8 2

instance Show Assoc where
    show assoc =
        case assoc of
          L -> "left"
          N -> "non"
          R -> "right"

instance Pretty (Declaration t v) where
  pretty decl =
    case decl of
      Definition def -> pretty def

      Datatype tipe tvars ctors deriveables ->
          P.hang (P.text "data" <+> P.text tipe <+> P.hsep (map P.text tvars)) 4
               (P.sep $ zipWith join ("=" : repeat "|") ctors) <+> prettyDeriving deriveables
          where
            join c ctor = P.text c <+> prettyCtor ctor
            prettyCtor (name, tipes) =
                P.hang (P.text name) 2 (P.sep (map prettyParens tipes))

      TypeAlias name tvars tipe deriveables ->
          alias <+> prettyDeriving deriveables
          where
            name' = P.text name <+> P.hsep (map P.text tvars)
            alias = P.hang (P.text "type" <+> name' <+> P.equals) 4 (pretty tipe)

      -- TODO: Actually write out the contained data in these cases.
      ImportEvent _ _ _ _ -> P.text (show decl)
      ExportEvent _ _ _   -> P.text (show decl)
      Fixity _ _ _        -> P.text (show decl)

prettyDeriving deriveables =
    case deriveables of
      []  -> P.empty
      [d] -> P.text "deriving" <+> P.text (show d)
      ds  -> P.text "deriving" <+>
             P.parens (P.hsep $ P.punctuate P.comma $ map (P.text . show) ds)
