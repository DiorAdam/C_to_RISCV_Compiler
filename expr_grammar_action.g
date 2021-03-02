tokens SYM_EOF SYM_IDENTIFIER<string> SYM_INTEGER<int> SYM_PLUS SYM_MINUS SYM_ASTERISK SYM_DIV SYM_MOD
tokens SYM_LPARENTHESIS SYM_RPARENTHESIS SYM_LBRACE SYM_RBRACE
tokens SYM_ASSIGN SYM_SEMICOLON SYM_RETURN SYM_IF SYM_WHILE SYM_ELSE SYM_COMMA SYM_PRINT
tokens SYM_EQUALITY SYM_NOTEQ SYM_LT SYM_LEQ SYM_GT SYM_GEQ
non-terminals S INSTR INSTRS LINSTRS ELSE EXPR FACTOR
non-terminals LPARAMS REST_PARAMS
non-terminals IDENTIFIER INTEGER
non-terminals FUNDEF FUNDEFS
non-terminals ADD_EXPRS ADD_EXPR
non-terminals MUL_EXPRS MUL_EXPR
non-terminals CMP_EXPRS CMP_EXPR
non-terminals EQ_EXPRS EQ_EXPR
axiom S
{

  open Symbols
  open Ast
  open BatPrintf
  open BatBuffer
  open Batteries
  open Utils

  (* TODO *)
  let resolve_associativity term other =
       (* TODO *)
    term

}

rules
S -> FUNDEFS SYM_EOF {  Node (Tlistglobdef, $1) }

IDENTIFIER -> SYM_IDENTIFIER    { StringLeaf($1) }
INTEGER -> SYM_INTEGER     { IntLeaf($1) }

FUNDEFS -> FUNDEF FUNDEFS   { $1::$2 }
FUNDEFS -> { [] }

FUNDEF -> IDENTIFIER SYM_LPARENTHESIS LPARAMS SYM_RPARENTHESIS INSTR   
          { Node (Tfundef, [$1] @ [Node (Tfunargs, $3)] @ [Node (Tfunbody, $5)] ) }

LPARAMS -> IDENTIFIER REST_PARAMS  { Node(Targ, [$1])::$2 }
LPARAMS -> { [] }

REST_PARAMS -> SYM_COMMA IDENTIFIER REST_PARAMS   { Node(Targ, [$2])::$3 }
REST_PARAMS -> { [] }

INSTR -> IDENTIFIER SYM_ASSIGN EXPR SYM_SEMICOLON   { Node (Tassign, [Node (Tassignvar, $1::$3 )])} 
INSTR -> SYM_IF SYM_LPARENTHESIS EXPR SYM_RPARENTHESIS LINSTRS ELSE  { Node (Tif, $3 @ [$5] @ $6) }
INSTR -> SYM_WHILE SYM_LPARENTHESIS EXPR SYM_RPARENTHESIS INSTR {Node (Twhile, $3 @ $5 )}
INSTR -> SYM_RETURN EXPR SYM_SEMICOLON  { Node (Treturn, $2) }
INSTR -> SYM_PRINT EXPR SYM_SEMICOLON   { Node (Tprint, $2) }
INSTR -> LINSTRS { $1 }

LINSTRS -> SYM_LBRACE INSTRS SYM_RBRACE   { Node (TBlock, $2) }

INSTRS -> INSTR INSTRS  { $1::$2 }
INSTRS -> { [] }

ELSE -> SYM_ELSE LINSTRS { [$2] }
ELSE -> { [] }

EXPR -> EQ_EXPR EQ_EXPRS  { $1::$2 }

ADD_EXPR -> MUL_EXPR MUL_EXPRS   { $1::$2 }
ADD_EXPR -> SYM_MINUS MUL_EXPR MUL_EXPRS  

ADD_EXPRS -> SYM_PLUS ADD_EXPR ADD_EXPRS
ADD_EXPRS -> SYM_MINUS ADD_EXPR ADD_EXPRS
ADD_EXPRS -> 

MUL_EXPR -> FACTOR

FACTOR -> INTEGER {$1}
FACTOR -> IDENTIFIER   {$1}
FACTOR -> SYM_LPARENTHESIS EXPR SYM_RPARENTHESIS

MUL_EXPRS -> SYM_ASTERISK MUL_EXPR MUL_EXPRS
MUL_EXPRS -> SYM_DIV MUL_EXPR MUL_EXPRS
MUL_EXPRS -> SYM_MOD MUL_EXPR MUL_EXPRS
MUL_EXPRS -> 

CMP_EXPR -> ADD_EXPR ADD_EXPRS

CMP_EXPRS -> SYM_GT CMP_EXPR CMP_EXPRS
CMP_EXPRS -> SYM_GEQ CMP_EXPR CMP_EXPRS
CMP_EXPRS -> SYM_LT CMP_EXPR CMP_EXPRS
CMP_EXPRS -> SYM_LEQ CMP_EXPR CMP_EXPRS
CMP_EXPRS -> 

EQ_EXPR -> CMP_EXPR CMP_EXPRS

EQ_EXPRS -> SYM_EQUALITY EQ_EXPR EQ_EXPRS
EQ_EXPRS -> SYM_NOTEQ EQ_EXPR EQ_EXPRS
EQ_EXPRS -> 














