(* MIT License *)

(* Copyright (c) 2024 malloc-nbytes *)

(* Permission is hereby granted, free of charge, to any person obtaining a copy *)
(* of this software and associated documentation files (the "Software"), to deal *)
(* in the Software without restriction, including without limitation the rights *)
(* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell *)
(* copies of the Software, and to permit persons to whom the Software is *)
(* furnished to do so, subject to the following conditions: *)

(* The above copyright notice and this permission notice shall be included in all *)
(* copies or substantial portions of the Software. *)

(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR *)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE *)
(* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER *)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, *)
(* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE *)
(* SOFTWARE. *)

(* Used to determine whether or not to replace all matches *)
let glbl_repl_all : bool ref = ref false

let usage () =
  let _ = print_endline "Usage:"
  and _ = print_endline "  ccts <files/dirs...>" in
  failwith "usage"
;;

let isalpha c =
  let c = int_of_char c in
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
;;

let isnum c =
  let c = int_of_char c in
  let c = c - int_of_char '0' in
  (c >= 0) && (c <= 9)
;;

let isalnum c = isalpha c || isnum c ;;

let is_lowercase c = Char.lowercase_ascii c = c;;

let file_to_str fp =
  let ch = open_in_bin fp in
  let s = really_input_string ch (in_channel_length ch) in
  let _ = close_in ch in s
;;

let write_to_file filename content =
  let channel = open_out filename in
  output_string channel content;
  close_out channel
;;

let is_dir fp =
  try
    let stats = Unix.lstat fp in
    stats.st_kind = Unix.S_DIR
  with Unix.Unix_error (Unix.ENOENT, _, _) -> failwith (Printf.sprintf "%s is not a file/dir" fp)
;;

let consume_until lst predicate =
  let rec aux lst acc =
    match lst with
    | [] -> acc, []
    | hd :: tl when predicate hd -> acc, (hd :: tl)
    | hd :: tl -> aux tl (acc @ [hd]) in
  aux lst []
;;

let rec convert_word wordlst =
  match wordlst with
  | [] -> ""
  | hd :: tl when not (is_lowercase hd) ->
     "_" ^ (String.make 1 (Char.lowercase_ascii hd)) ^ (convert_word tl)
  | hd :: tl -> String.make 1 hd ^ convert_word tl
;;

let confirm_input line start_col end_col row =
  let _ = Printf.printf "[ccts]: Line %d\n" row
  and _ = print_endline line in
  let rec f i =
    match i with
    | k when k < start_col-1 -> let _ = print_string " " in f (i+1)
    | k when k >= start_col-1 && k <= end_col-1 -> let _ = print_string "^" in f (i+1)
    | _ -> print_endline "" in
  let _ = f 0
  and _ = print_string "[ccts]: replace? (y/n): " in
  read_line ()
;;

let word_not_camelcase wordlst =
  match wordlst with
  | [] -> true
  | [x] -> true
  | hd :: _ when Char.uppercase_ascii hd = hd -> true
  | _ ->
     (* helloWorld -> is camelcase *)
     (* hello_worlD -> not camelcase *)
     let last = List.rev wordlst |> List.hd in
     if not @@ is_lowercase last then
       let last_char_chopped_lst = List.rev wordlst |> List.tl |> List.rev in
       List.for_all (fun c -> is_lowercase c) last_char_chopped_lst
     else
       List.for_all (fun c -> is_lowercase c) wordlst
;;

let process_line line row =
  let rec aux lst col =
    match lst with
    | [] -> "\n"
    | hd :: tl when hd = '\n' -> aux tl (col+1)
    | hd :: tl when isalpha hd ->
       let wordlst, rest = consume_until (hd :: tl) (fun c -> (not (isalnum c))) in
       let wordstr = List.to_seq wordlst |> String.of_seq in

       let wordlen = String.length wordstr in
       let end_col = col - 1 + String.length wordstr in

       let f () =
         let new_word = convert_word wordlst in
         new_word ^ aux rest (col+wordlen) in

       if word_not_camelcase wordlst then
         wordstr ^ aux rest (col + wordlen)
       else
         if !glbl_repl_all = true then f ()
         else
           (match confirm_input line col end_col row with
            | "y" | "Y" -> f ()
            | _ -> wordstr ^ aux rest @@ col + wordlen)

    | hd :: tl -> (String.make 1 hd) ^ (aux tl @@ col+1)
  in
  aux (line |> String.to_seq |> List.of_seq) 1
;;

let ccts fp =
  let contents = file_to_str fp in
  let lines = String.split_on_char '\n' contents in
  let rec aux line row =
    match line with
    | [] -> ""
    | line :: tl ->
       let s = process_line line row in
       s ^ aux tl (row+1)
  in
  aux lines 1
;;

let get_dir_contents dir =
  try
    let items = Sys.readdir dir in
    Array.to_list items
  with
  | Sys_error msg ->
    let _ = Printf.printf "[Error]: %s\n" msg in []
;;

let rec kill_all_camels_in_file filepath =
  match is_dir filepath with
  | true ->
     let items = get_dir_contents filepath in
     List.iter (fun item -> kill_all_camels_in_file (Filename.concat filepath item)) items
  | false ->
     let _ = Printf.printf "[ccts]: File: %s\n" filepath
     and _ = print_string "[ccts]: Replace all? ((y)es/(n)o/(c)ustom): " in
     (match read_line () with
      | "Y" | "y" -> let _ = glbl_repl_all := true in
                     write_to_file filepath (ccts filepath)
      | "C" | "c" -> let _ = glbl_repl_all := false in
                     write_to_file filepath (ccts filepath)
      | _ -> ())
;;

let () =
  let argv = Sys.argv
  and argc = Array.length Sys.argv in
  if argc < 2 then usage ()
  else List.iter (fun arg -> kill_all_camels_in_file arg) (Array.to_list argv |> List.tl)
;;
