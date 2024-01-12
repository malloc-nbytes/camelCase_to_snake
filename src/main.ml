let usage () =
  let _ = print_endline "Usage:"
  and _ = print_endline "  ccts <files/dirs...>" in
  failwith "usage"
;;

let isalpha c =
  let c = int_of_char c in
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
;;

let file_to_str fp =
  let ch = open_in_bin fp in
  let s = really_input_string ch (in_channel_length ch) in
  let _ = close_in ch in s
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

let convert_word word = failwith "todo"

let confirm_input line start_col end_col =
  let _ = Printf.printf "%d %d\n" start_col end_col in
  let _ = print_endline line in
  false

let word_not_camelcase wordlst =
  let is_lowercase c = Char.lowercase_ascii c = c in
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

let process_line line =
  let rec aux lst col =
    match lst with
    | [] -> "\n"
    | hd :: tl when isalpha hd ->
       let wordlst, rest = consume_until (hd :: tl) (fun c -> not (isalpha c)) in
       let wordstr = List.to_seq wordlst |> String.of_seq in

       let wordlen = String.length wordstr in
       let end_col = col - 1 + String.length wordstr in

       if word_not_camelcase wordlst then
         wordstr ^ aux rest (col + wordlen)
       else
         (match confirm_input line col end_col with
          | true ->
             let new_word = convert_word wordlst in
             new_word ^ aux rest 0
          | false -> wordstr ^ aux rest (col + wordlen))

    | hd :: tl -> (String.make 1 hd) ^ (aux tl (col+1))
  in
  aux (line |> String.to_seq |> List.of_seq) 1

let ccts fp =
  let contents = file_to_str fp in
  let lines = String.split_on_char '\n' contents in
  let rec aux = function
    | [] -> "\n"
    | line :: tl -> process_line line ^ aux tl
  in
  aux lines

let () =
  let argv = Sys.argv
  and argc = Array.length Sys.argv in

  if argc < 2 then usage ()
  else
    List.iter (fun arg ->
        match is_dir arg with
        | true -> failwith "directory support not implemented"
        | false ->
           let res = ccts arg in
           let _ = print_endline "res:" in
           print_endline res
      ) (List.tl (Array.to_list argv))
;;
