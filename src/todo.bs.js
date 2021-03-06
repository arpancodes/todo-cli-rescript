// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Fs = require("fs");
var Curry = require("bs-platform/lib/js/curry.js");
var Belt_Int = require("bs-platform/lib/js/belt_Int.js");
var Belt_Array = require("bs-platform/lib/js/belt_Array.js");
var Belt_Option = require("bs-platform/lib/js/belt_Option.js");

var getToday = (function() {
  let date = new Date();
  return date
    .toISOString()
    .split("T")[0];
});

function returnInt(x) {
  if (x !== undefined) {
    return x;
  } else {
    return -1;
  }
}

function returnStr(x) {
  if (x !== undefined) {
    return x;
  } else {
    return "";
  }
}

var pending_todos_file = "todo.txt";

var completed_todos_file = "done.txt";

var help_string = "Usage :-\n$ ./todo add \"todo item\"  # Add a new todo\n$ ./todo ls               # Show remaining todos\n$ ./todo del NUMBER       # Delete a todo\n$ ./todo done NUMBER      # Complete a todo\n$ ./todo help             # Show usage\n$ ./todo report           # Statistics";

function readFile(filename) {
  if (!Fs.existsSync(filename)) {
    return [];
  }
  var text = Fs.readFileSync(filename, {
        encoding: "utf8",
        flag: "r"
      });
  return text.split("\n");
}

function appendToFile(filename, text) {
  Fs.appendFileSync(filename, text, {
        encoding: "utf8",
        flag: "a+"
      });
  
}

function writeFile(filename, lines) {
  Fs.writeFileSync(filename, lines, {
        encoding: "utf8",
        flag: "w"
      });
  
}

function updateFile(filename, updaterFn) {
  var contents = readFile(filename);
  var contents$1 = Curry._1(updaterFn, contents).join("\n");
  return writeFile(filename, contents$1);
}

function cmdHelp(param) {
  console.log(help_string);
  
}

function cmdLs(param) {
  var todos = readFile(pending_todos_file);
  if (todos.length === 0) {
    console.log("There are no pending todos!");
    return ;
  }
  var length = todos.length;
  console.log(Belt_Array.reduceWithIndex(Belt_Array.reverse(todos), "", (function (acc, x, i) {
              return acc + ("[" + String(length - i | 0) + "] " + x + "\n");
            })));
  
}

function cmdAddTodo(arg) {
  if (Belt_Option.isNone(arg)) {
    console.log("Error: Missing todo string. Nothing added!");
  } else {
    updateFile(pending_todos_file, (function (todos) {
            return Belt_Array.concat(todos, [Belt_Option.getExn(arg)]);
          }));
    console.log("Added todo: \"" + Belt_Option.getExn(arg) + "\"");
  }
  
}

function cmdDelTodo(arg) {
  if (Belt_Option.isNone(arg)) {
    console.log("Error: Missing NUMBER for deleting todo.");
    return ;
  }
  var number = Belt_Option.getExn(arg);
  return updateFile(pending_todos_file, (function (todos) {
                if (number < 1 || number > todos.length) {
                  console.log("Error: todo #" + String(number) + " does not exist. Nothing deleted.");
                  return todos;
                } else {
                  todos.splice(number, 1);
                  console.log("Deleted todo #" + String(number));
                  return todos;
                }
              }));
}

function cmdMarkDone(arg) {
  if (Belt_Option.isNone(arg)) {
    console.log("Error: Missing NUMBER for marking todo as done.");
    return ;
  }
  var todos = readFile(pending_todos_file);
  var number = Belt_Option.getExn(arg);
  if (number < 1 || number > todos.length) {
    console.log("Error: todo #" + String(number) + " does not exist.");
    return ;
  }
  var completedTodo = todos.splice(number, 1);
  writeFile(pending_todos_file, todos.join("\n"));
  var x = Belt_Array.get(completedTodo, 0);
  var completedTodo$1 = "x " + Curry._1(getToday, undefined) + " " + (
    x !== undefined ? x : ""
  ) + "\n";
  console.log(completedTodo$1);
  appendToFile(completed_todos_file, completedTodo$1);
  console.log("Marked todo #" + String(number) + " as done.");
  
}

function cmdReport(param) {
  var pending = readFile(pending_todos_file).length - 1 | 0;
  var completed = readFile(completed_todos_file).length - 1 | 0;
  console.log(Curry._1(getToday, undefined) + " Pending : " + String(pending) + " Completed : " + String(completed));
  
}

var command = Belt_Array.get(process.argv, 2);

var arg = Belt_Array.get(process.argv, 3);

function fireCommand(cmd) {
  switch (cmd) {
    case "add" :
        return cmdAddTodo(arg);
    case "del" :
        return cmdDelTodo(Belt_Option.flatMap(arg, Belt_Int.fromString));
    case "done" :
        return cmdMarkDone(Belt_Option.flatMap(arg, Belt_Int.fromString));
    case "helo" :
        console.log(help_string);
        return ;
    case "ls" :
        return cmdLs(undefined);
    case "report" :
        return cmdReport(undefined);
    default:
      console.log(help_string);
      return ;
  }
}

function start(param) {
  if (command !== undefined) {
    return fireCommand(command);
  } else {
    console.log(help_string);
    return ;
  }
}

start(undefined);

var encoding = "utf8";

exports.getToday = getToday;
exports.returnInt = returnInt;
exports.returnStr = returnStr;
exports.encoding = encoding;
exports.pending_todos_file = pending_todos_file;
exports.completed_todos_file = completed_todos_file;
exports.help_string = help_string;
exports.readFile = readFile;
exports.appendToFile = appendToFile;
exports.writeFile = writeFile;
exports.updateFile = updateFile;
exports.cmdHelp = cmdHelp;
exports.cmdLs = cmdLs;
exports.cmdAddTodo = cmdAddTodo;
exports.cmdDelTodo = cmdDelTodo;
exports.cmdMarkDone = cmdMarkDone;
exports.cmdReport = cmdReport;
exports.command = command;
exports.arg = arg;
exports.fireCommand = fireCommand;
exports.start = start;
/* command Not a pure module */
