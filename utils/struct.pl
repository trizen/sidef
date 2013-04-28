{
  Array  => {
              Array => {
                methods => [
                  { args => ["array"], doc => "Substract array 2 from array 1", name => "-" },
                  {
                    args => [],
                    doc  => "Remove and return the last element from the self array.",
                    name => "pop",
                  },
                ],
              },
            },
  Bool   => {
              Bool => {
                inherits => ["Convert"],
                methods  => [
                              { args => [], doc => "Return a true value.", name => "true" },
                              { args => [], doc => "Return a false value.", name => "false" },
                              {
                                args => [],
                                doc  => "Return true if the value is true.",
                                name => "is_true",
                              },
                              {
                                args => [],
                                doc  => "Return true if the value is false.",
                                name => "is_false",
                              },
                            ],
              },
            },
  Glob   => {
              Dir => {
                inherits => ["Convert"],
                methods  => [
                              { args => [], name => "parent" },
                              { args => [], name => "remove" },
                              { args => [], name => "remove_tree" },
                              { args => [], name => "create" },
                              { args => [], name => "create_tree" },
                            ],
              },
              File => {
                inherits => ["Convert"],
                methods  => [
                              { args => [], name => "size" },
                              { args => [], name => "exists" },
                              { args => [], name => "is_binary" },
                              { args => [], name => "is_text" },
                              { args => [], name => "is_file" },
                              { args => [], name => "name" },
                              { args => [], name => "basename" },
                              { args => [], name => "dirname" },
                              { args => [], name => "abs_name" },
                              { args => ["mode"], name => "open" },
                              { args => [], name => "open_r" },
                              { args => [], name => "open_w" },
                              { args => [], name => "open_a" },
                            ],
              },
              FileHandle => {
                methods => [
                  { args => ["string"], name => "write" },
                  { args => [], name => "readline" },
                  { args => [], name => "file" },
                  { args => [], name => "close" },
                ],
              },
              Pipe => {
                methods => [
                  { args => ["mode"], name => "open" },
                  { args => [], name => "open_r" },
                  { args => [], name => "open_w" },
                ],
              },
              PipeHandle => {
                methods => [
                  { args => [], name => "command" },
                  { args => [], name => "close" },
                ],
              },
            },
  Hash   => {
              Hash => {
                inherits => ["Convert"],
                methods  => [{ name => "keys" }, { name => "values" }],
              },
            },
  Number => {
              Float   => { inherits => ["Number"] },
              Integer => { inherits => ["Number"] },
              Number  => {
                           inherits => ["Convert"],
                           methods  => [
                                         { args => ["num"], doc => "Divide two numbers", name => "/" },
                                         { args => ["num"], name => "*" },
                                         { args => ["num"], name => "+" },
                                         { args => ["num"], name => "-" },
                                         { args => ["num"], name => "%" },
                                         { args => ["num"], name => "**" },
                                         { args => [], name => "sqrt" },
                                         { args => [], name => "abs" },
                                         { args => [], name => "int" },
                                         { args => [], name => "log" },
                                         { args => [], name => "log10" },
                                         { args => [], name => "log2" },
                                         { args => [], name => "next_power_of_two" },
                                       ],
                         },
            },
  Regex  => { Regex => { inherits => ["Convert"] } },
  String => {
              Double => {
                          inherits => ["String"],
                          methods  => [{ args => [], name => "apply_escapes" }],
                        },
              String => {
                          inherits => ["Convert"],
                          methods  => [
                                        { args => [], doc => "Uppercase a string.", name => "uc" },
                                        {
                                          args => [],
                                          doc  => "Uppercase the first letter of a string.",
                                          name => "ucfirst",
                                        },
                                        { args => [], doc => "Lowercase a string.", name => "lc" },
                                        { args => [], name => "lcfirst" },
                                        { args => [], name => "chop" },
                                        { args => [], name => "chomp" },
                                        { args => ["offs", "len", "repl"], name => "substr" },
                                        { args => ["delim, ..."], name => "join" },
                                        { args => [], name => "reverse" },
                                        { args => [], name => "say" },
                                        { args => [], name => "print" },
                                        { args => [], name => "stat_file" },
                                        { args => [], name => "stat_dir" },
                                      ],
                        },
            },
}