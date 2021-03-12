/*
Sample JS implementation of Todo CLI that you can attempt to port:
https://gist.github.com/jasim/99c7b54431c64c0502cfe6f677512a87
*/

/* Returns date with the format: 2021-02-04 */
let getToday: unit => string = %raw(`
function() {
  let date = new Date();
  return new Date(date.getTime() - (date.getTimezoneOffset() * 60000))
    .toISOString()
    .split("T")[0];
}
  `)



let returnInt = (x: option<int>) =>
  switch x {
  | Some(y) => y
  | None => -1
  }

let returnStr = (x: option<string>) =>
switch x {
| Some(y) => y
| None => ""
}

type fsConfig = {encoding: string, flag: string}

/* https://nodejs.org/api/fs.html#fs_fs_existssync_path */
@bs.module("fs") external existsSync: string => bool = "existsSync"

/* https://nodejs.org/api/fs.html#fs_fs_readfilesync_path_options */
@bs.module("fs")
external readFileSync: (string, fsConfig) => string = "readFileSync"

/* https://nodejs.org/api/fs.html#fs_fs_writefilesync_file_data_options */
@bs.module("fs")
external appendFileSync: (string, string, fsConfig) => unit = "appendFileSync"

@bs.module("fs")
external writeFileSync: (string, string, fsConfig) => unit = "writeFileSync"

/* https://nodejs.org/api/os.html#os_os_eol */
@bs.module("os") external eol: string = "eol"

let encoding = "utf8"

/*
NOTE: The code below is provided just to show you how to use the
date and file functions defined above. Remove it to begin your implementation.
*/

let pending_todos_file = "todo.txt"
let completed_todos_file = "done.txt"

let help_string = `Usage :-
$ ./todo add "todo item"  # Add a new todo
$ ./todo ls               # Show remaining todos
$ ./todo del NUMBER       # Delete a todo
$ ./todo done NUMBER      # Complete a todo
$ ./todo help             # Show usage
$ ./todo report           # Statistics`


let readFile = (filename) => {
  if !existsSync(filename) {
    []
  } else {
    let text = readFileSync(filename, {encoding: "utf8", flag: "r"})
    Js.String.split("\n", text)
  }
}

let appendToFile = (filename, text) => {
  appendFileSync(filename, text, {encoding: "utf8", flag: "a+"});
}

let writeFile = (filename, lines) => {
  writeFileSync(filename, lines, {encoding: "utf8", flag: "w"});
}

let updateFile = (filename, updaterFn: array<string> => array<string>) => {
  let contents = readFile(filename)
  let contents = Js.Array.joinWith("\n", updaterFn(contents))
  writeFile(filename, contents)
}

let cmdHelp = () => {
  Js.log(help_string);
}

let cmdLs = () => {
  let todos = readFile(pending_todos_file)
  if (Js.Array.length(todos) == 0) {
    Js.log("There are no pending todos!")
  } else{
  let length = Js.Array.length(todos)
   todos
    ->Belt.Array.reverse
    ->Belt.Array.reduceWithIndex("", (acc, x, i) => acc ++ `[${(length - i)->Belt.Int.toString}] ${x}\n`)
    ->Js.log
  }
}


let cmdAddTodo = (arg: option<string>) => {
  if (Belt.Option.isNone(arg)) {
    Js.log("Error: Missing todo string. Nothing added!")
  } else {
    updateFile(pending_todos_file, todos => Belt.Array.concat(todos, [Belt.Option.getExn(arg)]))
    Js.log(`Added todo: "${Belt.Option.getExn(arg)}"`)
  }
}



let cmdDelTodo = (arg: option<int>) => {
  if (Belt.Option.isNone(arg)) {
    Js.log(`Error: Missing NUMBER for deleting todo.`)
  } else {
    let number = arg->Belt.Option.getExn
    updateFile(pending_todos_file, todos => {
      let todosUpdated = if (number < 1 || number > Js.Array.length(todos)) {
        Js.log(`Error: todo #${Belt.Int.toString(number)} does not exist. Nothing deleted.`)
        todos
      } else {
        let _ = Js.Array.spliceInPlace(~pos=number, ~remove=1, ~add=[], todos)
        Js.log(`Deleted todo #${Belt.Int.toString(number)}`)
        todos
      }
      todosUpdated
    })
  }
}


let cmdMarkDone = (arg: option<int>) => {
  if (arg->Belt.Option.isNone) {
    Js.log(`Error: Missing NUMBER for marking todo as done.`)
  } else {
    let todos = readFile(pending_todos_file)
    let number = Belt.Option.getExn(arg)
    if (number < 1 || number > Js.Array.length(todos)) {
      Js.log(`Error: todo #${Belt.Int.toString(number)} does not exist.`)
    } else {
      let completedTodo = Js.Array.spliceInPlace(~pos=number, ~remove=1, ~add=[], todos)
      writeFile(pending_todos_file, Js.Array.joinWith("\n", todos))
      let completedTodo = `x ${getToday()} ` ++ returnStr(completedTodo->Belt.Array.get(0)) ++ "\n"
      Js.log(completedTodo)
      appendToFile(completed_todos_file, completedTodo)
      Js.log(`Marked todo #${Belt.Int.toString(number)} as done.`)
    }
  }
}

let cmdReport = () => {
  let pending = Js.Array.length(readFile(pending_todos_file)) - 1
  let completed = Js.Array.length(readFile(completed_todos_file)) - 1
  Js.log(`${getToday()} Pending : ${Belt.Int.toString(pending)} Completed : ${Belt.Int.toString(completed)}`)
}


@val @scope("process") external argv: array<string> = "argv"


let command: option<string> = argv->Belt.Array.get(2)
let arg: option<string> = argv->Belt.Array.get(3)

let fireCommand = (cmd) => {
  switch cmd {
    | "ls" => cmdLs()
    | "helo" => cmdHelp()
    | "add" => cmdAddTodo(arg)
    | "del" => arg->Belt.Option.flatMap(Belt.Int.fromString)->cmdDelTodo
    | "done" => arg->Belt.Option.flatMap(Belt.Int.fromString)->cmdMarkDone
    | "report" => cmdReport()
    | _ => cmdHelp()
  }
}

let start = () =>{
    switch command {
    | Some(cmd) => fireCommand(cmd)
    | None => cmdHelp()
  }
}


start()
