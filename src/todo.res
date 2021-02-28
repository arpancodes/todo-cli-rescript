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

let isEmpty: 'a => bool = %raw(`
function(x) {
  return !Boolean(x)
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
    let todos = Js.Array.mapi((todo, index) => `[${Belt.Int.toString(length - index)}] ${todo}`, Belt.Array.reverse(todos))
    Js.log(Js.Array.joinWith("\n", todos))
  }
}


let cmdAddTodo = (text) => {
  if (isEmpty(text)) {
    Js.log("Error: Missing todo string. Nothing added!")
  } else {
    updateFile(pending_todos_file, todos => Belt.Array.concat(todos, [text]))
    Js.log(`Added todo: "${text}"`)
  }
}



let cmdDelTodo = (number: int) => {
  if (number < 0) {
    Js.log(`Error: Missing NUMBER for deleting todo.`)
  } else {
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


let cmdMarkDone = (number: int) => {
  if (number < 0) {
    Js.log(`Error: Missing NUMBER for marking todo as done.`)
  } else {
    let todos = readFile(pending_todos_file)

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


type process = {
  argv: array<string>
}

@bs.val external process: process = "process"



let argv = process.argv
let command = returnStr(Belt.Array.get(argv, 2));
let arg = returnStr(Belt.Array.get(argv, 3));

let start = () =>{
  if(isEmpty(command)){
    cmdHelp()
  } else {
    switch command {
    | "ls" => cmdLs()
    | "add" => cmdAddTodo(arg)
    | "del" => cmdDelTodo(returnInt(Belt.Int.fromString(arg)))
    | "done" => cmdMarkDone(returnInt(Belt.Int.fromString(arg)))
    | "help" => cmdHelp()
    | "report" => cmdReport()
    | _ => cmdHelp()
    }
  }
}
start()
