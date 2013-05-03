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
                                    self => bless(do{\(my $o = "::")}, "Sidef::Types::String::Double"),
                                  },
                                  {
                                    call => [{ name => "uc" }],
                                    self => bless(do{\(my $o = "b")}, "Sidef::Types::String::Double"),
                                  },
                                  {
                                    self => bless(do{\(my $o = "c")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => "join",
                  },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "a")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = "sidef")}, "Sidef::Types::Glob::File")],
                    name => "=",
                  },
                ],
        self => bless({ name => "file", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              { name => "size" },
                                              {
                                                arg  => [bless(do{\(my $o = 1024)}, "Sidef::Types::Number::Integer")],
                                                name => "/",
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                ],
                              },
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "size_kb", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "Size of sidef in bytes: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 1024)}, "Sidef::Types::Number::Integer")],
                    name => "*",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => 'fix',
      },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "size of file 'sidef': \$size_kb KB\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              { main => [{ call => [{ name => "open_r" }], self => 'fix' }] },
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "fh", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "say" }],
        self => bless(do{\(my $o = "\\n** Reading one line from 'sidef':")}, "Sidef::Types::String::Double"),
      },
      {
        call => [{ name => "readline" }, { name => "print" }],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [{ name => "stat_file" }],
                                    self => bless(do{\(my $o = "sidef")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => "=",
                  },
                ],
        self => 'fix',
      },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "\\nFile name is: ")}, "Sidef::Types::String::Double"),
      },
      { call => [{ name => "name" }, { name => "say" }], self => 'fix' },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "Full path is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              { main => [{ call => [{ name => "abs_name" }], self => 'fix' }] },
                            ],
                    name => "=",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless({ name => "abs_path", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "Dir name is:  ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [{ name => "dirname" }, { name => "to_s" }, { name => "say" }],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "RaNdOm StRiNg")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                  { name => "lc" },
                ],
        self => bless({ name => "x", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [{ name => "lc" }],
                                    self => bless(do{\(my $o = "RaNdOm StRiNg")}, "Sidef::Types::String::Double"),
                                  },
                                ],
                              },
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "y", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "\\LRaNdOm StRiNg")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "z", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "Sidef")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "lang", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "say" }],
        self => bless(do{\(my $o = "\\nJust another \$lang hacker,")}, "Sidef::Types::String::Double"),
      },
      {
        call => [{ name => "say" }],
        self => bless(do{\(my $o = "\\nescaped variable: \\\$var\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "this is a test -- \$y -- \\n")}, "Sidef::Types::String::String"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "single", type => "var" }, "Sidef::Variable::Variable"),
      },
      { call => [{ name => "say" }], self => 'fix' },
      {
        call => [{ name => "say" }],
        self => { main => [{ call => [{ name => "to_sd" }], self => 'fix' }] },
      },
      { call => [{ name => "say" }], self => 'fix' },
      { call => [{ name => "say" }], self => 'fix' },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "Ioana")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "name", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "Hello, \$name! How are you? :)\\n")}, "Sidef::Types::String::Double"),
      },
      { call => [{ name => "uc" }, { name => "say" }], self => 'fix' },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer")],
                    name => "+",
                  },
                  {
                    arg  => [bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer")],
                    name => "/",
                  },
                  { name => "to_s" },
                  { name => "say" },
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
                                                arg  => [bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer")],
                                                name => "/",
                                              },
                                            ],
                                    self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => "+",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = 6)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer")],
                    name => "/",
                  },
                  {
                    arg  => [bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer")],
                    name => "*",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = 12)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "\\\\tthis is a creepy string\\\\n\\n")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "creepy", type => "var" }, "Sidef::Variable::Variable"),
      },
      { call => [{ name => "print" }], self => 'fix' },
      {
        call => [{ name => "apply_escapes" }, { name => "print" }],
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
                    name => "substr",
                  },
                  { name => "say" },
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
                    name => "substr",
                  },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "Hello, World")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 42)}, "Sidef::Types::Number::Integer")],
                    name => "=",
                  },
                ],
        self => bless({ name => "num", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "print" }],
        self => bless(do{\(my $o = "Next power of two after number \$num is: ")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  { name => "next_power_of_two" },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "^_^ Sidef ^_^")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                  { name => "say" },
                ],
        self => bless({ name => "init", type => "var" }, "Sidef::Variable::Variable"),
      },
      { call => [{ name => "uc" }, { name => "say" }], self => 'fix' },
      {
        call => [{ name => "say" }],
        self => bless(do{\(my $o = "\\n\\uvariable interpolation ==> \\L\$init\\\\\\\\\\E <== is Working\\n")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "Hello, World!")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "hello", type => "var" }, "Sidef::Variable::Variable"),
      },
      { call => [{ name => "say" }], self => 'fix' },
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
                    name => "=",
                  },
                ],
        self => 'fix',
      },
      { call => [{ name => "print" }], self => 'fix' },
      {
        call => [
                  {
                    arg  => [
                              {
                                main => [
                                  {
                                    call => [
                                              {
                                                arg  => [bless(do{\(my $o = 23)}, "Sidef::Types::Number::Integer")],
                                                name => "-",
                                              },
                                            ],
                                    self => bless(do{\(my $o = 43)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "diff", type => "var" }, "Sidef::Variable::Variable"),
      },
      { call => [{ name => "to_s" }, { name => "say" }], self => 'fix' },
      {
        call => [{ name => "to_s" }, { name => "say" }],
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
                                                              name => "/",
                                                            },
                                                          ],
                                                  self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                },
                                              ],
                                            },
                                          ],
                                  name => "/",
                                },
                              ],
                      self => bless(do{\(my $o = 42)}, "Sidef::Types::Number::Integer"),
                    },
                  ],
                },
      },
      {
        call => [{ name => "to_s" }, { name => "say" }],
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
                                                                name => "+",
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
        call => [{ name => "to_s" }, { name => "say" }],
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
                                  name => "/",
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
                                                                            name => "*",
                                                                          },
                                                                        ],
                                                                self => bless(do{\(my $o = 4.3)}, "Sidef::Types::Number::Float"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => "-",
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
                  { name => "abs" },
                  { name => "sqrt" },
                  { name => "to_s" },
                  { name => "say" },
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
                    name => "/",
                  },
                  { name => "to_s" },
                  { name => "say" },
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
                                                                            name => "/",
                                                                          },
                                                                        ],
                                                                self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                              },
                                                            ],
                                                          },
                                                        ],
                                                name => "*",
                                              },
                                            ],
                                    self => bless(do{\(my $o = 18)}, "Sidef::Types::Number::Integer"),
                                  },
                                ],
                              },
                            ],
                    name => "/",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = 24)}, "Sidef::Types::Number::Integer"),
      },
      {
        call => [{ name => "lc" }, { name => "uc" }, { name => "say" }],
        self => bless(do{\(my $o = "StRinG")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  { name => "int" },
                  { name => "log10" },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = 44.2)}, "Sidef::Types::Number::Float"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 3.14)}, "Sidef::Types::Number::Float")],
                    name => "=",
                  },
                ],
        self => bless({ name => "pi", type => "const" }, "Sidef::Variable::Variable"),
      },
      { call => [{ name => "to_s" }, { name => "say" }], self => 'fix' },
      {
        call => [{ name => "pop" }, { name => "to_s" }, { name => "say" }],
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
                        call => [{ name => "uc" }],
                        self => bless(do{\(my $o = "x")}, "Sidef::Types::String::Double"),
                      },
                      {
                        call => [
                                  {
                                    arg  => [bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer")],
                                    name => "*",
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
                                        arg  => [bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer")],
                                        name => "+",
                                      },
                                    ],
                            self => bless(do{\(my $o = 4)}, "Sidef::Types::Number::Integer"),
                          },
                        ], "Sidef::Types::Array::Array"),
                      },
                      {
                        call => [{ name => "uc" }],
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
                              bless([
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
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "array", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless([
                                {
                                  self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                },
                                {
                                  self => bless(do{\(my $o = 2)}, "Sidef::Types::Number::Integer"),
                                },
                              ], "Sidef::Types::Array::Array"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "array2", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless([{ self => 'fix' }, { self => 'fix' }], "Sidef::Types::Array::Array"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "left", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [{ name => "pop" }, { name => "to_s" }, { name => "say" }],
        self => 'fix',
      },
      {
        call => [{ name => "pop" }, { name => "to_s" }, { name => "say" }],
        self => 'fix',
      },
      {
        call => [{ name => "pop" }, { name => "say" }],
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
                              bless([
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
                                  call => [{ name => "lc" }],
                                  self => bless(do{\(my $o = "Y")}, "Sidef::Types::String::Double"),
                                },
                              ], "Sidef::Types::Array::Array"),
                            ],
                    name => "-",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless([
                  {
                    self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                  },
                  {
                    call => [{ name => "uc" }],
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
                              bless([
                                {
                                  self => bless(do{\(my $o = "w")}, "Sidef::Types::String::Double"),
                                },
                                {
                                  call => [{ name => "uc" }],
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
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "arr_1", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless([
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
                                  call => [{ name => "lc" }],
                                  self => bless(do{\(my $o = "Y")}, "Sidef::Types::String::Double"),
                                },
                              ], "Sidef::Types::Array::Array"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "arr_2", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  { arg => ['fix'], name => "-" },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => 'fix',
      },
      {
        call => [
                  {
                    arg  => [
                              bless([
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
                            ],
                    name => "+",
                  },
                  { name => "to_s" },
                  { name => "say" },
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
                    name => "matches",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?i:TEST)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = "one two three")}, "Sidef::Types::String::Double"),
                            ],
                    name => "=~",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?^:[123])")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = bless(do{\(my $o = "(?^:(\\w+))")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                            ],
                    name => "=~",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "--string--")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = bless(do{\(my $o = "(?^:^\\d+ \\w+ \\d+\$)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                            ],
                    name => "=",
                  },
                ],
        self => bless({ name => "regex", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  { arg => ['fix'], name => "=~" },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "03 May 2013")}, "Sidef::Types::String::Double"),
      },
      { call => [{ name => "to_s" }, { name => "say" }], self => 'fix' },
      {
        call => [
                  {
                    arg  => [
                              bless([
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
                            ],
                    name => "=~",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?^:item)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [{ name => "say" }],
        self => bless(do{\(my $o = "\\n=>> Variable interpolation f\xDFr regular expressions:")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer")],
                    name => "*",
                  },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = "\\w")}, "Sidef::Types::String::String")],
                    name => "=",
                  },
                ],
        self => bless({ name => "re", type => "var" }, "Sidef::Variable::Variable"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = bless(do{\(my $o = "(?^:\\d\$re)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                            ],
                    name => "=~",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "test")}, "Sidef::Types::String::Double"),
      },
      {
        call => [
                  {
                    arg  => [
                              bless(do{\(my $o = bless(do{\(my $o = "(?^:\\d\$re)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
                            ],
                    name => "=~",
                  },
                  { name => "to_s" },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "3d")}, "Sidef::Types::String::Double"),
      },
      {
        call => [{ name => "to_s" }, { name => "say" }],
        self => bless(do{\(my $o = bless(do{\(my $o = "(?^:\\d\$re)")}, "Sidef::Types::String::String"))}, "Sidef::Types::Regex::Regex"),
      },
      {
        call => [
                  {
                    arg  => [bless(do{\(my $o = 80)}, "Sidef::Types::Number::Integer")],
                    name => "*",
                  },
                  { name => "say" },
                ],
        self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
      },
      {
        call => [{ name => "say" }],
        self => bless(do{\(my $o = "Chinese characters: \x{6587}\x{5316}\x{4EA4}\x{6D41}\x{5B66}\x{9662}")}, "Sidef::Types::String::Double"),
      },
    ],
  };
  $a->{main}[2]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[4]{self} = $a->{main}[2]{self};
  $a->{main}[6]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[8]{self} = $a->{main}[6]{self};
  $a->{main}[9]{self} = $a->{main}[1]{self};
  $a->{main}[11]{self} = $a->{main}[1]{self};
  $a->{main}[13]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[15]{self} = $a->{main}[13]{self};
  $a->{main}[23]{self} = $a->{main}[22]{self};
  $a->{main}[24]{self}{main}[0]{self} = $a->{main}[22]{self};
  $a->{main}[25]{self} = $a->{main}[16]{self};
  $a->{main}[26]{self} = $a->{main}[17]{self};
  $a->{main}[29]{self} = $a->{main}[27]{self};
  $a->{main}[34]{self} = $a->{main}[33]{self};
  $a->{main}[35]{self} = $a->{main}[33]{self};
  $a->{main}[40]{self} = $a->{main}[38]{self};
  $a->{main}[42]{self} = $a->{main}[41]{self};
  $a->{main}[45]{self} = $a->{main}[44]{self};
  $a->{main}[46]{self} = $a->{main}[44]{self};
  $a->{main}[47]{self} = $a->{main}[44]{self};
  $a->{main}[49]{self} = $a->{main}[48]{self};
  $a->{main}[59]{self} = $a->{main}[58]{self};
  $a->{main}[63]{call}[0]{arg}[0][0]{self} = $a->{main}[61]{self};
  $a->{main}[63]{call}[0]{arg}[0][1]{self} = $a->{main}[62]{self};
  $a->{main}[64]{self} = $a->{main}[63]{self};
  $a->{main}[65]{self} = $a->{main}[61]{self};
  $a->{main}[70]{call}[0]{arg}[0] = $a->{main}[69]{self};
  $a->{main}[70]{self} = $a->{main}[68]{self};
  $a->{main}[76]{call}[0]{arg}[0] = $a->{main}[75]{self};
  $a->{main}[77]{self} = $a->{main}[75]{self};
  $a;
}