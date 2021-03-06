(*
  This file is part of scilla.

  Copyright (c) 2018 - present Zilliqa Research Pvt. Ltd.
  
  scilla is free software: you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation, either version 3 of the License, or (at your option) any later
  version.
 
  scilla is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 
  You should have received a copy of the GNU General Public License along with
  scilla.  If not, see <http://www.gnu.org/licenses/>.
*)

open MonadUtil
open Syntax

val subst_type_in_type: string -> typ -> typ -> typ
val subst_type_in_literal: 'a ident -> typ -> literal -> literal
val subst_type_in_expr: 'a ident -> typ -> 'a expr_annot -> 'a expr_annot

(* An inferred type with possible qualifiers *)
type 'rep inferred_type = {
  tp   : typ;
  qual : 'rep
} [@@deriving sexp]

(* Qualifiers to type inference with additional information *)
module type QualifiedTypes = sig
  type t
  val mk_qualified_type : typ -> t inferred_type      
end

module type MakeTEnvFunctor = functor
  (Q: QualifiedTypes)
  (R : Rep)
  -> sig
  (* Resolving results *)
  type resolve_result
  val rr_loc : resolve_result -> loc
  val rr_rep : resolve_result -> R.rep
  val rr_typ : resolve_result -> Q.t inferred_type
  val rr_pp  : resolve_result -> string
  val mk_qual_tp : typ -> Q.t inferred_type
  
  module TEnv : sig
    type t
    (* Make new type environment *)
    val mk : t
    (* Add to type environment *)
    val addT : t -> R.rep ident -> typ -> t
    (* Add to many type bindings *)
    val addTs : t -> (R.rep ident * typ) list -> t
    (* Add type variable to the environment *)
    val addV : t -> R.rep ident -> t
    (* Check type for well-formedness in the type environment *)
    val is_wf_type : t -> typ -> (unit, string) eresult
    (* Resolve the identifier *)    
    val resolveT : ?lopt:(R.rep option) -> t -> string ->
      (resolve_result, string) eresult
    (* Copy the environment *)
    val copy : t -> t
    (* Convert to list *)
    val to_list : t -> (string * resolve_result) list
    (* Get type variables *)
    val tvars : t -> (string * R.rep) list
    (* Print the type environment *)
    val pp : ?f:(string * resolve_result -> bool) -> t -> string        
  end
end

module PlainTypes : QualifiedTypes
module MakeTEnv : MakeTEnvFunctor

val literal_type : literal -> (typ, string) eresult

(* Useful generic types *)
val fun_typ : typ -> typ -> typ
val tvar : string -> typ
val tfun_typ : string -> typ -> typ
val map_typ : typ -> typ -> typ

(****************************************************************)
(*                       Type sanitization                      *)
(****************************************************************)

val is_storable_type : typ -> bool
val is_ground_type : typ -> bool

(****************************************************************)
(*             Utility function for matching types              *)
(****************************************************************)

val type_equiv : typ -> typ -> bool
val type_equiv_list : typ list -> typ list -> bool

val assert_type_equiv : typ -> typ -> (unit, string) eresult

(* Applying a function type *)
val fun_type_applies : typ -> typ list -> (typ, string) eresult

(* Applying a type function *)
val elab_tfun_with_args : typ -> typ list -> (typ, string) eresult

val pp_typ_list : typ list -> string  

(****************************************************************)
(*                        Working with ADTs                     *)
(****************************************************************)

(*  Apply type substitution  *)
val apply_type_subst : (string * typ) list -> typ -> typ

(*  Get elaborated type for a constructor and list of type arguments *)    
val elab_constr_type : string -> typ list -> (typ, string) eresult  

(* For a given instantiated ADT and a construtor name, get type *
   assignemnts. This is the main working horse of type-checking
   pattern-matching. *)    
val constr_pattern_arg_types : typ -> string -> (typ list, string) eresult  

val validate_param_length : string -> int -> int -> (unit, string) eresult

val assert_all_same_type : typ list -> (unit, string) eresult

(****************************************************************)
(*                  Better error reporting                      *)
(****************************************************************)

val wrap_with_info : string -> ('a, string) eresult -> ('a, string) eresult

val wrap_err : 'rep expr -> ('rep ident -> loc) -> ?opt:string ->
  ('a, string) eresult -> ('a, string) eresult

val wrap_serr : ('srep, 'erep) stmt -> ('erep ident -> loc) -> ?opt:string ->
  ('a, string) eresult -> ('a, string) eresult

(****************************************************************)
(*                  Built-in typed entities                     *)
(****************************************************************)

val blocknum_name : string
