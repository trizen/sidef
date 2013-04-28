{
  Array   => {
               Array => {
                 methods => [
                   {
                     args    => ["array"],
                     doc     => "Substract the I<array> from the self array.",
                     name    => "-",
                     returns => "Array::Array",
                   },
                   {
                     args => [],
                     doc  => "Remove and return the last element from the self array.",
                     name => "pop",
                   },
                 ],
               },
             },
  Bool    => {
               Bool => {
                 inherits => ["Convert"],
                 methods  => [
                               {
                                 args    => [],
                                 doc     => "Returns a true value.",
                                 name    => "true",
                                 returns => "Bool::Bool",
                               },
                               {
                                 args    => [],
                                 doc     => "Returns a false value.",
                                 name    => "false",
                                 returns => "Bool::Bool",
                               },
                               {
                                 args => [],
                                 doc  => "Returns true if the value is true.",
                                 name => "is_true",
                               },
                               {
                                 args => [],
                                 doc  => "Returns true if the value is false.",
                                 name => "is_false",
                               },
                             ],
               },
             },
  Convert => {
               Convert => {
                 methods => [
                   {
                     args    => [],
                     doc     => "Converts the object into a string.",
                     name    => "to_s",
                     returns => "String::String",
                   },
                   {
                     args    => [],
                     doc     => "Converts the object into a double quoted string.",
                     name    => "to_sd",
                     returns => "String::Double",
                   },
                   {
                     args    => [],
                     doc     => "Converts the object into an integer.",
                     name    => "to_i",
                     returns => "Number::Integer",
                   },
                   { args => [], name => "to_f" },
                   { args => [], name => "to_file" },
                   { args => [], name => "to_dir" },
                   { args => [], name => "to_b" },
                   { args => [], name => "to_a" },
                 ],
               },
             },
  Glob    => {
               Dir => {
                 inherits => ["Convert"],
                 methods  => [
                               {
                                 args    => [],
                                 doc     => "Returns the parent of the self directory.",
                                 name    => "parent",
                                 returns => "Glob::Dir",
                               },
                               {
                                 args    => [],
                                 doc     => "Removes the self directory, only if the directory is empty.",
                                 name    => "remove",
                                 returns => "Bool::Bool",
                               },
                               {
                                 args    => [],
                                 doc     => "Removes the self directory tree, with all its content.",
                                 name    => "remove_tree",
                                 returns => "Bool::Bool",
                               },
                               {
                                 args    => [],
                                 doc     => "Creates the self directory.",
                                 name    => "create",
                                 returns => "Bool::Bool",
                               },
                               {
                                 args    => [],
                                 doc     => "Creates the self directory with needed parents.",
                                 name    => "create_tree",
                                 returns => "Bool::Bool",
                               },
                             ],
               },
               File => {
                 inherits => ["Convert"],
                 methods  => [
                               { args => [], name => "size", returns => "Number::Number" },
                               {
                                 args    => [],
                                 doc     => "Returns true if the self file exists.",
                                 name    => "exists",
                                 returns => "Bool::Bool",
                               },
                               { args => [], name => "is_binary", returns => "Bool::Bool" },
                               { args => [], name => "is_text", returns => "Bool::Bool" },
                               { args => [], name => "is_file", returns => "Bool::Bool" },
                               { args => [], name => "name", returns => "String::String" },
                               { args => [], name => "basename", returns => "String::String" },
                               { args => [], name => "dirname", returns => "Glob::Dir" },
                               { args => [], name => "abs_name", returns => "Glob::File" },
                               { args => ["mode"], name => "open", returns => "Glob::FileHandle" },
                               { args => [], name => "open_r", returns => "Glob::FileHandle" },
                               { args => [], name => "open_w", returns => "Glob::FileHandle" },
                               { args => [], name => "open_a", returns => "Glob::FileHandle" },
                             ],
               },
               FileHandle => {
                 methods => [
                   { args => ["string"], name => "write", returns => "Bool::Bool" },
                   { args => [], name => "readline", returns => "String::String" },
                   { args => [], name => "file", returns => "Glob::File" },
                   { args => [], name => "close", returns => "Bool::Bool" },
                 ],
               },
               Pipe => {
                 methods => [
                   { args => ["mode"], name => "open", returns => "Glob::PipeHandle" },
                   { args => [], name => "open_r", returns => "Glob::Pipe" },
                   { args => [], name => "open_w", returns => "Glob::Pipe" },
                 ],
               },
               PipeHandle => {
                 methods => [
                   { args => [], name => "command", returns => "String::String" },
                   { args => [], name => "close", returns => "Bool::Bool" },
                 ],
               },
             },
  Hash    => {
               Hash => {
                 inherits => ["Convert"],
                 methods  => [
                               { name => "keys", returns => "Array::Array" },
                               { name => "values", returns => "Array::Array" },
                             ],
               },
             },
  Number  => {
               Float   => { inherits => ["Number"] },
               Integer => { inherits => ["Number"] },
               Number  => {
                            inherits => ["Convert"],
                            methods  => [
                                          {
                                            args    => ["num"],
                                            doc     => "Divides the self number to I<num> and returns the result.",
                                            name    => "/",
                                            returns => "Number::Number",
                                          },
                                          { args => ["num"], name => "*", returns => "Number::Number" },
                                          { args => ["num"], name => "+", returns => "Number::Number" },
                                          { args => ["num"], name => "-", returns => "Number::Number" },
                                          { args => ["num"], name => "%", returns => "Number::Number" },
                                          { args => ["num"], name => "**", returns => "Number::Number" },
                                          {
                                            args    => [],
                                            doc     => "Returns the positive square root of the self number.",
                                            name    => "sqrt",
                                            returns => "Number::Float",
                                          },
                                          { args => [], name => "abs", returns => "Number::Number" },
                                          { args => [], name => "int", returns => "Number::Integer" },
                                          { args => [], name => "log", returns => "Number::Float" },
                                          { args => [], name => "log10", returns => "Number::Float" },
                                          { args => [], name => "log2", returns => "Number::Float" },
                                          {
                                            args    => [],
                                            doc     => "Returns the next power of two for the self number.",
                                            name    => "next_power_of_two",
                                            returns => "Number::Integer",
                                          },
                                        ],
                          },
             },
  Regex   => { Regex => { inherits => ["Convert"] } },
  String  => {
               Double => {
                           inherits => ["String"],
                           methods  => [
                                         { args => [], name => "apply_escapes", returns => "String::Double" },
                                       ],
                         },
               String => {
                           inherits => ["Convert"],
                           methods  => [
                                         {
                                           args    => [],
                                           doc     => "Uppercases the self string and returns it.",
                                           name    => "uc",
                                           returns => "String::String",
                                         },
                                         {
                                           args    => [],
                                           doc     => "Uppercases the first letter of the self string and returns the string.",
                                           name    => "ucfirst",
                                           returns => "String::String",
                                         },
                                         {
                                           args    => [],
                                           doc     => "Lowercases the self string and returns it.",
                                           name    => "lc",
                                           returns => "String::String",
                                         },
                                         { args => [], name => "lcfirst", returns => "String::String" },
                                         {
                                           args    => [],
                                           doc     => "Chops off the last character from the self string and returns it.",
                                           name    => "chop",
                                           returns => "String::String",
                                         },
                                         {
                                           args    => [],
                                           doc     => "Chops off the last character from the self string only if it is a newline character.",
                                           name    => "chomp",
                                           returns => "String::String",
                                         },
                                         {
                                           args    => ["offs", "len", "string"],
                                           doc     => "Extracts a substring out of the self string and returns it. First character is at offset zero. If I<offs> is negative, starts that far back from the end of the string. If I<len> is omitted, returns everything through the end of the string. If I<len> is negative, leaves that many characters off the end of the string.",
                                           name    => "substr",
                                           returns => "String::String",
                                         },
                                         { args => ["delim, ..."], name => "join", returns => "String::String" },
                                         { args => [], name => "reverse", returns => "String::String" },
                                         { args => [], name => "say", returns => "Bool::Bool" },
                                         { args => [], name => "print", returns => "Bool::Bool" },
                                         {
                                           args    => [],
                                           doc     => "Returns a file object for the self string.",
                                           name    => "stat_file",
                                           returns => "Glob::File",
                                         },
                                         { args => [], name => "stat_dir", returns => "Glob::Dir" },
                                       ],
                         },
             },
}