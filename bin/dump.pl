do {
  my $a = {
    main => [
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 1369434950)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "START_TIME", type => "const", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              { main => [{ self => bless([], "Sidef::Types::Array::Array") }] },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "ARGV", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "linux")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "OSNAME", type => "const", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "stat_file")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "sidef")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "EXEC", type => "const", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "stat_file")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "script\\.sf")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "SCRIPT", type => "const", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "::")}, "Sidef::Types::String::Double"),
                                  },
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "b")}, "Sidef::Types::String::Double"),
                                  },
                                  {
                                    self => bless(do{\(my $o = "c")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "a")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "sidef")}, "Sidef::Types::Glob::File"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "file", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "size")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 1024)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "size_kb", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Size of sidef in bytes: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 1024)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "size of file 'sidef': \$size_kb KB\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "open_r")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "fh", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\n** Reading one line from 'sidef':")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "readline")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "stat_file")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "sidef")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\nFile name is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "name")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Full path is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "abs_name")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless({ name => "abs_path", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Dir name is:  ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "dirname")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "RaNdOm StRiNg")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "lc")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless({ name => "x", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "lc")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "RaNdOm StRiNg")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "y", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "\\LRaNdOm StRiNg")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "z", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "Sidef")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "lang", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\nJust another \$lang hacker,")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\nescaped variable: \\\$var\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "this is a test -- \$y -- \\n")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "single", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      call => [
                                {
                                  name => {
                                    self => bless(do{\(my $o = "to_sd")}, "Sidef::Types::String::String"),
                                  },
                                },
                              ],
                      self => 'fix',
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "Ioana")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "name", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Hello, \$name! How are you? :)\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = 12)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "\\\\tthis is a creepy string\\\\n\\n")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "creepy", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "apply_escapes")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                                  },
                                  {
                                    self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "substr")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Hello, World")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = -5)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "substr")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Hello, World")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 42)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "num", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Next power of two after number \$num is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "next_power_of_two")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "^_^ Sidef ^_^")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless({ name => "init", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\n\\uvariable interpolation ==> \\L\$init\\\\\\\\\\E <== is Working\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "Hello, World!")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "hello", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "Goodbye, World!\\n")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "print")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 23)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = 43)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "diff", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  call => [
                                                            {
                                                              arg  => [
                                                                        {
                                                                          main => [
                                                                            {
                                                                              self => bless(do{\(my $o = "1.0")}, "Sidef::Types::Number::Float"),
                                                                            },
                                                                          ],
                                                                        },
                                                                      ],
                                                              name => {
                                                                        self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                                                      },
                                                            },
                                                          ],
                                                  self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = 42)}, "Sidef::Types::Number::Integer"),
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      self => {
                        main => [
                          {
                            self => {
                              main => [
                                {
                                  self => {
                                    main => [
                                      {
                                        self => {
                                          main => [
                                            {
                                              self => {
                                                main => [
                                                  {
                                                    call => [
                                                              {
                                                                arg  => [
                                                                          {
                                                                            main => [
                                                                              {
                                                                                self => bless(do{\(my $o = 40)}, "Sidef::Types::Number::Integer"),
                                                                              },
                                                                            ],
                                                                          },
                                                                        ],
                                                                name => {
                                                                          self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                                                        },
                                                              },
                                                            ],
                                                    self => bless(do{\(my $o = 60)}, "Sidef::Types::Number::Integer"),
                                                  },
                                                ],
                                              },
                                            },
                                          ],
                                        },
                                      },
                                    ],
                                  },
                                },
                              ],
                            },
                          },
                        ],
                      },
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                call => [
                                                                          {
                                                                            arg  => [
                                                                                      {
                                                                                        main => [
                                                                                          {
                                                                                            self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                                                          },
                                                                                        ],
                                                                                      },
                                                                                    ],
                                                                            name => {
                                                                                      self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                                                                    },
                                                                          },
                                                                        ],
                                                                self => bless(do{\(my $o = 4.3)}, "Sidef::Types::Number::Float"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = 42)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "abs")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "sqrt")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = -81)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = 10)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                call => [
                                                                          {
                                                                            arg  => [
                                                                                      {
                                                                                        main => [
                                                                                          {
                                                                                            self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                                                          },
                                                                                        ],
                                                                                      },
                                                                                    ],
                                                                            name => {
                                                                                      self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                                                                    },
                                                                          },
                                                                        ],
                                                                self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = 18)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = 24)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "lc")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "StRinG")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "int")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "log10")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = 44.2)}, "Sidef::Types::Number::Float"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 3.14)}, "Sidef::Types::Number::Float"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "pi", type => "const", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "pop")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless([
                  {
                    self => bless(do{\(my $o = "test")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = 44)}, "Sidef::Types::Number::Integer"),
                  },
                  {
                    self => bless(do{\(my $o = 123)}, "Sidef::Types::Number::Integer"),
                  },
                  {
                    self => bless([
                      {
                        self => bless(do{\(my $o = "aa")}, "Sidef::Types::String::Double"),
                      },
                      {
                        self => bless(do{\(my $o = "bb")}, "Sidef::Types::String::Double"),
                      },
                    ], "Sidef::Types::Array::Array"),
                  },
                  {
                    self => bless([
                      {
                        call => [
                                  {
                                    name => {
                                      self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                                    },
                                  },
                                ],
                        self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                      },
                      {
                        call => [
                                  {
                                    arg  => [
                                              {
                                                main => [
                                                  {
                                                    self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                  },
                                                ],
                                              },
                                            ],
                                    name => {
                                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                            },
                                  },
                                ],
                        self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                      },
                      {
                        self => bless([
                          {
                            self => bless(do{\(my $o = 32)}, "Sidef::Types::Number::Integer"),
                          },
                          {
                            call => [
                                      {
                                        arg  => [
                                                  {
                                                    main => [
                                                      {
                                                        self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                      },
                                                    ],
                                                  },
                                                ],
                                        name => {
                                                  self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                                },
                                      },
                                    ],
                            self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                          },
                        ], "Sidef::Types::Array::Array"),
                      },
                      {
                        call => [
                                  {
                                    name => {
                                      self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                                    },
                                  },
                                ],
                        self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                      },
                    ], "Sidef::Types::Array::Array"),
                  },
                ], "Sidef::Types::Array::Array"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                      },
                                      {
                                        self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                      },
                                      {
                                        self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "array", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                      },
                                      {
                                        self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "array2", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([{ self => 'fix' }, { self => 'fix' }], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "left", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "pop")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "pop")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "pop")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      self => bless([
                        {
                          self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                        },
                        {
                          self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                        },
                        {
                          self => bless(do{\(my $o = "z")}, "Sidef::Types::String::Double"),
                        },
                      ], "Sidef::Types::Array::Array"),
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless([
                                          {
                                            self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                          },
                                        ], "Sidef::Types::Array::Array"),
                                      },
                                      {
                                        call => [
                                                  {
                                                    name => {
                                                      self => bless(do{\(my $o = "lc")}, "Sidef::Types::String::String"),
                                                    },
                                                  },
                                                ],
                                        self => bless(do{\(my $o = "Y")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless([
                  {
                    self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                  },
                  {
                    call => [
                              {
                                name => {
                                  self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                                },
                              },
                            ],
                    self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                  },
                  {
                    self => bless([
                      {
                        self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                      },
                    ], "Sidef::Types::Array::Array"),
                  },
                  {
                    self => bless(do{\(my $o = "IT")}, "Sidef::Types::String::Double"),
                  },
                ], "Sidef::Types::Array::Array"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        call => [
                                                  {
                                                    name => {
                                                      self => bless(do{\(my $o = "uc")}, "Sidef::Types::String::String"),
                                                    },
                                                  },
                                                ],
                                        self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                      },
                                      {
                                        self => bless([
                                          {
                                            self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                          },
                                        ], "Sidef::Types::Array::Array"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "IT")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "arr_1", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless([
                                          {
                                            self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                          },
                                        ], "Sidef::Types::Array::Array"),
                                      },
                                      {
                                        call => [
                                                  {
                                                    name => {
                                                      self => bless(do{\(my $o = "lc")}, "Sidef::Types::String::String"),
                                                    },
                                                  },
                                                ],
                                        self => bless(do{\(my $o = "Y")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "arr_2", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [{ main => [{ self => 'fix' }] }],
                    name => {
                              self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "London")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "Berlin")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless([
                  {
                    self => bless(do{\(my $o = "Paris")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = "Berlin")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = "Atena")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = "London")}, "Sidef::Types::String::Double"),
                  },
                ], "Sidef::Types::Array::Array"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "d")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "e")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "f")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless([
                  {
                    self => bless(do{\(my $o = "a")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = "b")}, "Sidef::Types::String::Double"),
                  },
                  {
                    self => bless(do{\(my $o = "c")}, "Sidef::Types::String::Double"),
                  },
                ], "Sidef::Types::Array::Array"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "For testing.")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "matches")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?i:TEST)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "one two three")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=~")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?^:[123])")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = bless(do{\(my $o = "(?^:(\\w+))")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=~")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "--string--")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = bless(do{\(my $o = "(?^:^\\d+ \\w+ \\d+\$)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "regex", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [{ main => [{ self => 'fix' }] }],
                    name => {
                              self => bless(do{\(my $o = "=~")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "03 May 2013")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "str")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless([
                                          {
                                            self => bless(do{\(my $o = 123)}, "Sidef::Types::Number::Integer"),
                                          },
                                          {
                                            self => bless([
                                              {
                                                self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                                              },
                                              {
                                                self => bless(do{\(my $o = "item")}, "Sidef::Types::String::Double"),
                                              },
                                              {
                                                self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                                              },
                                            ], "Sidef::Types::Array::Array"),
                                          },
                                          {
                                            self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
                                          },
                                        ], "Sidef::Types::Array::Array"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "boo")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=~")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?^:item)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\n=>> Variable interpolation f\xDFr regular expressions:")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "\\w")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "re", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = bless(do{\(my $o = "(?^:\\d\$re)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=~")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "test")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = bless(do{\(my $o = "(?^:\\d\$re)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=~")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "3d")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?^:\\d\$re)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Chinese characters: \x{6587}\x{5316}\x{4EA4}\x{6D41}\x{5B66}\x{9662}")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "\\n=>> Methods as expressions:\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  call => [
                                                            {
                                                              name => {
                                                                self => {
                                                                  main => [
                                                                    {
                                                                      call => [
                                                                                {
                                                                                  name => {
                                                                                    self => bless(do{\(my $o = "shift")}, "Sidef::Types::String::String"),
                                                                                  },
                                                                                },
                                                                              ],
                                                                      self => bless([
                                                                                {
                                                                                  self => bless(do{\(my $o = "sqrt")}, "Sidef::Types::String::Double"),
                                                                                },
                                                                              ], "Sidef::Types::Array::Array"),
                                                                    },
                                                                  ],
                                                                },
                                                              },
                                                            },
                                                            {
                                                              name => {
                                                                self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                              },
                                                            },
                                                          ],
                                                  self => bless(do{\(my $o = 81)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = "sqrt of 81 is: ")}, "Sidef::Types::String::Double"),
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "sqrt")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "sqrt_method", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => {
                  main => [
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  call => [
                                                            { name => { self => 'fix' } },
                                                            {
                                                              name => {
                                                                self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                              },
                                                            },
                                                          ],
                                                  self => bless(do{\(my $o = 25)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = "sqrt of 25 is: ")}, "Sidef::Types::String::Double"),
                    },
                  ],
                },
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "substr")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "method_name", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                              {
                                                                self => bless(do{\(my $o = 12)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => { self => 'fix' },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "Sidef is awesome!")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "super ")}, "Sidef::Types::String::Double"),
                                  },
                                  {
                                    self => bless(do{\(my $o = 9)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "insert")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Ioana")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Your OS name is: \$OSNAME")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "The name of this script is: \$SCRIPT\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "..")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "range_array", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "reverse")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = ", ")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = ". BOOM!")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "original")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "defined", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "modified")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = ":=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  { self => bless(do{\(my $o = undef)}, "Sidef::Types::Nil::Nil") },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "modified")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = ":=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "sidef")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "chars", type => "char", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "len")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Number of chars: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "i", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    ind  => [bless([{ self => 'fix' }], "Sidef::Types::Array::Array")],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "'")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "chars[\$i] is '")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "g")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "r")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "a")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "f")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "e")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "zero")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "one")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "two")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "three")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "four")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "nums", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = -1)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = -2)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = -3)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = -4)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = -5)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "unu")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "doi")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "trei")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "patru")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                {
                                                  self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = 8)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "doi")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "trei")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "patru")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "cinci")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "\x{219}ase")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = " ")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "beg")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless([
                                          {
                                            self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                                          },
                                          {
                                            self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                                          },
                                          {
                                            self => bless(do{\(my $o = "z")}, "Sidef::Types::String::Double"),
                                          },
                                        ], "Sidef::Types::Array::Array"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "end")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "nes", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "m")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "n")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "o")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "one")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "two")}, "Sidef::Types::String::Double"),
                                      },
                                      {
                                        self => bless(do{\(my $o = "three")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "doi")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              { main => [{ self => bless([], "Sidef::Types::Array::Array") }] },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "array_test", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "elem1")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "elem2")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "ord")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "a")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "ord('a') ==  ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "ord")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => bless(do{\(my $o = "c")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "byte", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 32)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "chr")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "byte '\$byte' made uppercase, is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "\x{219}arpe")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "bytes", type => "byte", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    ind  => [
                                              bless([
                                                {
                                                  self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                                                },
                                                {
                                                  self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ], "Sidef::Types::Array::Array"),
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "The character '\x{219}' is composed of two bytes: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    ind  => [
                                              bless([
                                                {
                                                  self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ], "Sidef::Types::Array::Array"),
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = " (")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "chr")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    ind  => [
                                              bless([
                                                {
                                                  self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ], "Sidef::Types::Array::Array"),
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = ")")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "Then comes the character 'a', which is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 200)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 154)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "\x{219}op\xE2rl\x{103}")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "sidef", type => "char", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "join")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless({
                                      main => [
                                        {
                                          call => [
                                                    {
                                                      name => {
                                                        self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                                                      },
                                                    },
                                                  ],
                                          self => bless(do{\(my $o = "first")}, "Sidef::Types::String::Double"),
                                        },
                                        {
                                          call => [
                                                    {
                                                      name => {
                                                        self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                                                      },
                                                    },
                                                  ],
                                          self => bless(do{\(my $o = "block")}, "Sidef::Types::String::Double"),
                                        },
                                        {
                                          call => [
                                                    {
                                                      arg  => [
                                                                {
                                                                  main => [
                                                                    {
                                                                      self => bless([
                                                                        {
                                                                          self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                                        },
                                                                        {
                                                                          self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                                                        },
                                                                        {
                                                                          self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                                                                        },
                                                                      ], "Sidef::Types::Array::Array"),
                                                                    },
                                                                  ],
                                                                },
                                                              ],
                                                      name => {
                                                                self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                                                              },
                                                    },
                                                  ],
                                          self => bless({ name => "private", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                        },
                                        {
                                          call => [
                                                    {
                                                      name => {
                                                        self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                                                      },
                                                    },
                                                    {
                                                      name => {
                                                        self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                                                      },
                                                    },
                                                  ],
                                          ind  => [
                                                    bless([
                                                      {
                                                        self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                      },
                                                    ], "Sidef::Types::Array::Array"),
                                                  ],
                                          self => 'fix',
                                        },
                                        {
                                          self => bless(do{\(my $o = "end of block")}, "Sidef::Types::String::Double"),
                                        },
                                      ],
                                    }, "Sidef::Types::Block::Code"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "block", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "true")}, "Sidef::Types::Bool::Bool"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "if")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = "false")}, "Sidef::Types::Bool::Bool"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "if")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "to_s")}, "Sidef::Types::String::String"),
                    },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [
                                                          {
                                                            main => [
                                                              {
                                                                self => bless(do{\(my $o = 5)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => {
                                                          self => bless(do{\(my $o = "..")}, "Sidef::Types::String::String"),
                                                        },
                                              },
                                            ],
                                    self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "for")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({
                  main => [
                    {
                      call => [
                                {
                                  name => {
                                    self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                                  },
                                },
                              ],
                      self => bless(do{\(my $o = "Sidef rocks!!!")}, "Sidef::Types::String::Double"),
                    },
                  ],
                }, "Sidef::Types::Block::Code"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        self => bless({ name => "index", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless({
                                      main => [
                                        {
                                          call => [
                                                    {
                                                      arg  => [
                                                                {
                                                                  main => [
                                                                    {
                                                                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                                    },
                                                                  ],
                                                                },
                                                              ],
                                                      name => {
                                                                self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                                                              },
                                                    },
                                                  ],
                                          self => 'fix',
                                        },
                                        {
                                          call => [
                                                    {
                                                      arg  => [
                                                                {
                                                                  main => [
                                                                    {
                                                                      self => bless(do{\(my $o = 10)}, "Sidef::Types::Number::Integer"),
                                                                    },
                                                                  ],
                                                                },
                                                              ],
                                                      name => {
                                                                self => bless(do{\(my $o = "<")}, "Sidef::Types::String::String"),
                                                              },
                                                    },
                                                  ],
                                          self => 'fix',
                                        },
                                        {
                                          call => [
                                                    {
                                                      name => {
                                                        self => bless(do{\(my $o = "++")}, "Sidef::Types::String::String"),
                                                      },
                                                    },
                                                  ],
                                          self => 'fix',
                                        },
                                      ],
                                    }, "Sidef::Types::Block::Code"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "for")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({
                  main => [
                    {
                      call => [
                                {
                                  arg  => [
                                            {
                                              main => [
                                                { self => 'fix' },
                                                {
                                                  self => {
                                                    main => [
                                                      {
                                                        call => [
                                                                  {
                                                                    arg  => [
                                                                              {
                                                                                main => [
                                                                                  {
                                                                                    call => [
                                                                                              {
                                                                                                arg  => [
                                                                                                          {
                                                                                                            main => [
                                                                                                              {
                                                                                                                self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                                                                              },
                                                                                                            ],
                                                                                                          },
                                                                                                        ],
                                                                                                name => {
                                                                                                          self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                                                                                        },
                                                                                              },
                                                                                            ],
                                                                                    self => 'fix',
                                                                                  },
                                                                                ],
                                                                              },
                                                                            ],
                                                                    name => {
                                                                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                                                            },
                                                                  },
                                                                  {
                                                                    arg  => [
                                                                              {
                                                                                main => [
                                                                                  {
                                                                                    self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                                                                  },
                                                                                ],
                                                                              },
                                                                            ],
                                                                    name => {
                                                                              self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                                                            },
                                                                  },
                                                                ],
                                                        self => 'fix',
                                                      },
                                                    ],
                                                  },
                                                },
                                              ],
                                            },
                                          ],
                                  name => {
                                            self => bless(do{\(my $o = "printf")}, "Sidef::Types::String::String"),
                                          },
                                },
                              ],
                      self => bless(do{\(my $o = "** Sum of 0 to %d is: %d\\n")}, "Sidef::Types::String::Double"),
                    },
                  ],
                }, "Sidef::Types::Block::Code"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                            },
                  },
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless([
                                          {
                                            self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                                          },
                                          {
                                            self => bless(do{\(my $o = "y")}, "Sidef::Types::String::Double"),
                                          },
                                          {
                                            self => bless(do{\(my $o = "z")}, "Sidef::Types::String::Double"),
                                          },
                                        ], "Sidef::Types::Array::Array"),
                                      },
                                    ], "Sidef::Types::Array::Array"),
                                  },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "arr_test", type => "var", value => undef }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    name => {
                      self => bless(do{\(my $o = "say")}, "Sidef::Types::String::String"),
                    },
                  },
                ],
        ind  => [
                  bless([
                    {
                      self => bless(do{\(my $o = 0)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                  bless([
                    {
                      self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                    },
                  ], "Sidef::Types::Array::Array"),
                ],
        self => 'fix',
      },
    ],
  };
  $a->{main}[7]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[6]{self};
  $a->{main}[9]{self} = $a->{main}[7]{self};
  $a->{main}[11]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[6]{self};
  $a->{main}[13]{self} = $a->{main}[11]{self};
  $a->{main}[14]{self} = $a->{main}[6]{self};
  $a->{main}[16]{self} = $a->{main}[6]{self};
  $a->{main}[18]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[6]{self};
  $a->{main}[20]{self} = $a->{main}[18]{self};
  $a->{main}[28]{self} = $a->{main}[27]{self};
  $a->{main}[29]{self}{main}[0]{self} = $a->{main}[27]{self};
  $a->{main}[30]{self} = $a->{main}[21]{self};
  $a->{main}[31]{self} = $a->{main}[22]{self};
  $a->{main}[34]{self} = $a->{main}[32]{self};
  $a->{main}[39]{self} = $a->{main}[38]{self};
  $a->{main}[40]{self} = $a->{main}[38]{self};
  $a->{main}[45]{self} = $a->{main}[43]{self};
  $a->{main}[47]{self} = $a->{main}[46]{self};
  $a->{main}[50]{self} = $a->{main}[49]{self};
  $a->{main}[51]{self} = $a->{main}[49]{self};
  $a->{main}[52]{self} = $a->{main}[49]{self};
  $a->{main}[54]{self} = $a->{main}[53]{self};
  $a->{main}[64]{self} = $a->{main}[63]{self};
  $a->{main}[68]{call}[0]{arg}[0]{main}[0]{self}[0]{self} = $a->{main}[66]{self};
  $a->{main}[68]{call}[0]{arg}[0]{main}[0]{self}[1]{self} = $a->{main}[67]{self};
  $a->{main}[69]{self} = $a->{main}[68]{self};
  $a->{main}[70]{self} = $a->{main}[66]{self};
  $a->{main}[75]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[74]{self};
  $a->{main}[75]{self} = $a->{main}[73]{self};
  $a->{main}[82]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[81]{self};
  $a->{main}[83]{self} = $a->{main}[81]{self};
  $a->{main}[96]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{name}{self} = $a->{main}[95]{self};
  $a->{main}[98]{call}[0]{arg}[0]{main}[0]{call}[0]{name}{self} = $a->{main}[97]{self};
  $a->{main}[104]{self} = $a->{main}[103]{self};
  $a->{main}[107]{self} = $a->{main}[106]{self};
  $a->{main}[108]{self} = $a->{main}[106]{self};
  $a->{main}[109]{self} = $a->{main}[106]{self};
  $a->{main}[110]{self} = $a->{main}[106]{self};
  $a->{main}[111]{self} = $a->{main}[106]{self};
  $a->{main}[114]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[113]{self};
  $a->{main}[115]{self} = $a->{main}[113]{self};
  $a->{main}[117]{call}[0]{arg}[0]{main}[0]{ind}[0][0]{self} = $a->{main}[116]{self};
  $a->{main}[117]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[113]{self};
  $a->{main}[118]{self} = $a->{main}[113]{self};
  $a->{main}[119]{self} = $a->{main}[113]{self};
  $a->{main}[120]{self} = $a->{main}[113]{self};
  $a->{main}[121]{self} = $a->{main}[113]{self};
  $a->{main}[122]{self} = $a->{main}[113]{self};
  $a->{main}[123]{self} = $a->{main}[113]{self};
  $a->{main}[126]{self} = $a->{main}[125]{self};
  $a->{main}[127]{self} = $a->{main}[125]{self};
  $a->{main}[128]{self} = $a->{main}[125]{self};
  $a->{main}[129]{self} = $a->{main}[125]{self};
  $a->{main}[131]{self} = $a->{main}[125]{self};
  $a->{main}[132]{self} = $a->{main}[125]{self};
  $a->{main}[133]{self} = $a->{main}[125]{self};
  $a->{main}[134]{self} = $a->{main}[125]{self};
  $a->{main}[135]{self} = $a->{main}[125]{self};
  $a->{main}[136]{self} = $a->{main}[125]{self};
  $a->{main}[137]{self} = $a->{main}[125]{self};
  $a->{main}[138]{self} = $a->{main}[125]{self};
  $a->{main}[139]{self} = $a->{main}[125]{self};
  $a->{main}[142]{self} = $a->{main}[141]{self};
  $a->{main}[143]{self} = $a->{main}[141]{self};
  $a->{main}[144]{self} = $a->{main}[141]{self};
  $a->{main}[145]{self} = $a->{main}[141]{self};
  $a->{main}[147]{self} = $a->{main}[141]{self};
  $a->{main}[148]{self} = $a->{main}[141]{self};
  $a->{main}[149]{self} = $a->{main}[141]{self};
  $a->{main}[150]{self} = $a->{main}[141]{self};
  $a->{main}[151]{self} = $a->{main}[141]{self};
  $a->{main}[154]{self} = $a->{main}[153]{self};
  $a->{main}[155]{self} = $a->{main}[153]{self};
  $a->{main}[156]{self} = $a->{main}[153]{self};
  $a->{main}[157]{self} = $a->{main}[153]{self};
  $a->{main}[158]{self} = $a->{main}[153]{self};
  $a->{main}[159]{self} = $a->{main}[153]{self};
  $a->{main}[164]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[163]{self};
  $a->{main}[167]{self} = $a->{main}[166]{self};
  $a->{main}[168]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[166]{self};
  $a->{main}[169]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[166]{self};
  $a->{main}[169]{call}[2]{arg}[0]{main}[0]{self} = $a->{main}[166]{self};
  $a->{main}[170]{self} = $a->{main}[166]{self};
  $a->{main}[171]{self} = $a->{main}[166]{self};
  $a->{main}[172]{self} = $a->{main}[166]{self};
  $a->{main}[175]{self} = $a->{main}[174]{self};
  $a->{main}[176]{self} = $a->{main}[174]{self};
  $a->{main}[177]{self} = $a->{main}[174]{self};
  $a->{main}[178]{self} = $a->{main}[174]{self};
  $a->{main}[179]{self} = $a->{main}[174]{self};
  $a->{main}[180]{self} = $a->{main}[174]{self};
  $a->{main}[181]{self} = $a->{main}[174]{self};
  $a->{main}[183]{call}[0]{arg}[0]{main}[0]{self}{main}[3]{self} = $a->{main}[183]{call}[0]{arg}[0]{main}[0]{self}{main}[2]{self};
  $a->{main}[184]{self} = $a->{main}[183]{self};
  $a->{main}[185]{self} = $a->{main}[183]{self};
  $a->{main}[186]{self} = $a->{main}[183]{call}[0]{arg}[0]{main}[0]{self}{main}[2]{self};
  $a->{main}[191]{call}[0]{arg}[0]{main}[0]{self}{main}[0]{self} = $a->{main}[190]{self};
  $a->{main}[191]{call}[0]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[190]{self};
  $a->{main}[191]{call}[0]{arg}[0]{main}[0]{self}{main}[2]{self} = $a->{main}[190]{self};
  $a->{main}[191]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[190]{self};
  $a->{main}[191]{self}{main}[0]{call}[0]{arg}[0]{main}[1]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[190]{self};
  $a->{main}[191]{self}{main}[0]{call}[0]{arg}[0]{main}[1]{self}{main}[0]{self} = $a->{main}[190]{self};
  $a->{main}[194]{self} = $a->{main}[193]{self};
  $a;
}