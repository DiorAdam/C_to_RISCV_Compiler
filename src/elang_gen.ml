open Ast
open Elang
open Prog
open Report
open Options
open Batteries
open Elang_print
open Utils

let tag_is_binop =
  function
  | Tadd -> true
  | Tsub -> true
  | Tmul -> true
  | Tdiv -> true
  | Tmod -> true
  | Txor -> true
  | Tcle -> true
  | Tclt -> true
  | Tcge -> true
  | Tcgt -> true
  | Tceq -> true
  | Tne  -> true
  | _    -> false

let binop_of_tag =
  function
  | Tadd -> Eadd
  | Tsub -> Esub
  | Tmul -> Emul
  | Tdiv -> Ediv
  | Tmod -> Emod
  | Txor -> Exor
  | Tcle -> Ecle
  | Tclt -> Eclt
  | Tcge -> Ecge
  | Tcgt -> Ecgt
  | Tceq -> Eceq
  | Tne -> Ecne
  | _ -> assert false

(* [make_eexpr_of_ast a] builds an expression corresponding to a tree [a]. If
   the tree is not well-formed, fails with an [Error] message. *)
let rec make_eexpr_of_ast (a: tree) : expr res =
  let res =
    match a with
      | IntLeaf x -> OK (Eint x)

      | Node(Tint, [e])-> make_eexpr_of_ast e

      | CharLeaf c -> OK (Evar (string_of_char_list [c]))

      | StringLeaf s -> OK (Evar s)

      | Node(t, [e1; e2]) when tag_is_binop t ->(
          make_eexpr_of_ast e1 >>= fun ex1 -> 
          make_eexpr_of_ast e2 >>= fun ex2 ->
            OK (Ebinop (binop_of_tag t, ex1, ex2)))

      | Node (Tneg, [e]) ->(
          make_eexpr_of_ast e >>= fun ex -> 
            OK (Eunop (Eneg, ex))
      )

      | Node (Tcall, [(StringLeaf fname); Node(Targs, argmts)]) ->(
        let f_fold argms ast_node = (
          argms >>= fun argums ->
          make_eexpr_of_ast ast_node >>= fun ex -> 
            OK (argums@[ex])
        ) in
        (List.fold_left f_fold (OK []) argmts) >>= fun arguments -> 
          OK (Ecall (fname, arguments))
      )

      | _ -> Error (Printf.sprintf "Unacceptable ast in make_eexpr_of_ast %s"
                      (string_of_ast a))
  in
  match res with
  | OK o -> res
  | Error msg -> Error (Format.sprintf "In make_eexpr_of_ast %s:\n%s"
                          (string_of_ast a) msg)
                        

let string_of_varexpr = function 
  | Evar s -> OK s
  | _ -> Error "The given expression is not a variable"

let rec make_einstr_of_ast (a: tree) : instr res =
  let res = 
    match a with

      | Node (Tassign, [Node (Tassignvar, [e1; e2] )]) -> (
          make_eexpr_of_ast e1 >>= string_of_varexpr >>= fun ex1 ->   
          make_eexpr_of_ast e2 >>= fun ex2 ->  
              OK (Iassign (ex1, ex2))
      )
      | Node (Tif, [expr; instr1; instr2]) ->(
          make_eexpr_of_ast expr >>= fun ex ->
            make_einstr_of_ast instr1 >>= fun i1 ->
              make_einstr_of_ast instr2 >>= fun i2 ->
                OK (Iif (ex, i1, i2))
      )
      | Node (Tif, [expr; instr1]) ->(
        make_eexpr_of_ast expr >>= fun ex ->
          make_einstr_of_ast instr1 >>= fun i1 ->
              OK (Iif (ex, i1, Iblock []))
    )
      | Node (Twhile, [expr; instr]) ->(
          make_eexpr_of_ast expr >>= fun ex ->
            make_einstr_of_ast instr >>= fun i ->
              OK (Iwhile (ex, i))
      )
      | Node (Tblock, instrs) ->( 
          let f_fold a instri = 
            make_einstr_of_ast instri >>= fun i ->
              a >>= fun l ->
                OK (l @ [i])
          in
          List.fold_left f_fold (OK []) instrs >>= fun instr_list ->
          OK (Iblock instr_list)
      )
      | Node (Treturn, [expr]) -> (
        make_eexpr_of_ast expr >>= fun ex ->
          OK (Ireturn ex)
      )
      | Node (Tprint, [expr]) ->(
        make_eexpr_of_ast expr >>= fun ex ->
          OK (Iprint ex)
      ) 
      
      | Node (Tcall, [(StringLeaf fname); Node(Targs, argmts)]) ->(
          make_eexpr_of_ast a >>= fun exp ->(
            match exp with 
              | Ecall (fn, argms) -> OK (Icall (fn, argms)) 
              | _ -> failwith (Printf.sprintf "Unacceptable ast in make_eexpr_of_ast %s"
                              (string_of_ast a))
          ) 
      )

      | _ -> Error (Printf.sprintf "Unacceptable ast in make_einstr_of_ast %s"
                      (string_of_ast a))
  in
  match res with
  | OK o -> res
  | Error msg -> Error (Format.sprintf "In make_einstr_of_ast %s:\n%s"
                          (string_of_ast a) msg)

let make_ident (a: tree) : string res =
  match a with
  | Node (Targ, [s]) ->
    OK (string_of_stringleaf s)
  | a -> Error (Printf.sprintf "make_ident: unexpected AST: %s"
                  (string_of_ast a))

let make_fundef_of_ast (a: tree) : (string * efun) res =
  match a with
  | Node (Tfundef, [StringLeaf fname; Node (Tfunargs, fargs); Node (Tfunbody, [fblock])]) ->
      list_map_res make_ident fargs >>= fun fargs ->
        make_einstr_of_ast fblock >>= fun fblock ->
          OK (fname, {
            funargs= fargs;
            funbody= fblock
          })
  | _ ->
    Error (Printf.sprintf "make_fundef_of_ast: Expected a Tfundef, got %s."
             (string_of_ast a))

let make_eprog_of_ast (a: tree) : eprog res =
  match a with
  | Node (Tlistglobdef, l) ->
    list_map_res (fun a -> make_fundef_of_ast a >>= fun (fname, efun) -> OK (fname, Gfun efun)) l
  | _ ->
    Error (Printf.sprintf "make_fundef_of_ast: Expected a Tlistglobdef, got %s."
             (string_of_ast a))

let pass_elang ast =
  match make_eprog_of_ast ast with
  | Error msg ->
    record_compile_result ~error:(Some msg) "Elang";
    Error msg
  | OK  ep ->
    dump !e_dump dump_e ep (fun file () ->
        add_to_report "e" "E" (Code (file_contents file))); OK ep


