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
       let wordlst, rest = consume_until (hd :: tl) (fun c -> not (isalpha c)) in
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
  let lines = String.split_on_char '\n' contents
              |> List.rev |> List.tl |> List.rev in
  let rec aux line row =
    match line with
    | [] -> "\n"
    | line :: tl -> process_line line row ^ aux tl (row+1)
  in
  aux lines 1
;;

let () =
  let argv = Sys.argv
  and argc = Array.length Sys.argv in

  if argc < 2 then usage ()
  else
    List.iter (fun arg ->
        match is_dir arg with
        | true -> failwith "directory support not implemented"
        | false ->
           let _ = Printf.printf "[ccts]: File: %s\n" arg
           and _ = print_string "[ccts]: Replace all? (y/n): "
           and _ = match read_line () with | "Y" | "y" -> glbl_repl_all := true
                                           | _ -> glbl_repl_all := false
           and res = ccts arg in

           (* QAD solution for the extra newline bug. *)
           let res = String.to_seq res |> List.of_seq |> List.rev in
           let res = if List.hd res = '\n' then List.rev (List.tl res)
                     else res in
           let res = List.to_seq res |> String.of_seq in
           print_string res
           (* write_to_file arg res *)
           ) (List.tl (Array.to_list argv))
;;
