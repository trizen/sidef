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
                                    self => bless(do{\(my $o = 1369790714)}, "Sidef::Types::Number::Integer"),
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
                              {
                                main => [
                                  {
                                    self => bless([
                                      {
                                        self => bless(do{\(my $o = 25)}, "Sidef::Types::String::String"),
                                      },
                                      {
                                        self => bless(do{\(my $o = 15)}, "Sidef::Types::String::String"),
                                      },
                                      {
                                        self => bless(do{\(my $o = 10)}, "Sidef::Types::String::String"),
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
                                    self => bless(do{\(my $o = "ascii_cuboid\\.sf")}, "Sidef::Types::String::Double"),
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
        self => bless({
          name  => "cuboid",
          type  => "func",
          value => bless({
                     main => [
                       {
                         self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         self => bless({ name => "x", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         self => bless({ name => "y", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         self => bless({ name => "z", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         self => bless({ name => "s", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         call => [
                                   {
                                     arg  => [
                                               {
                                                 main => [
                                                   {
                                                     self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
                                                   },
                                                 ],
                                               },
                                             ],
                                     name => {
                                               self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                                             },
                                   },
                                 ],
                         self => bless({ name => "c", type => "var", value => undef }, "Sidef::Variable::Variable"),
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
                                               self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                                             },
                                   },
                                 ],
                         self => bless({ name => "h", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         call => [
                                   {
                                     arg  => [
                                               {
                                                 main => [
                                                   {
                                                     self => bless(do{\(my $o = "|")}, "Sidef::Types::String::String"),
                                                   },
                                                 ],
                                               },
                                             ],
                                     name => {
                                               self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                                             },
                                   },
                                 ],
                         self => bless({ name => "v", type => "var", value => undef }, "Sidef::Variable::Variable"),
                       },
                       {
                         call => [
                                   {
                                     arg  => [
                                               {
                                                 main => [
                                                   {
                                                     self => bless(do{\(my $o = "/")}, "Sidef::Types::String::String"),
                                                   },
                                                 ],
                                               },
                                             ],
                                     name => {
                                               self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                                             },
                                   },
                                 ],
                         self => bless({ name => "d", type => "var", value => undef }, "Sidef::Variable::Variable"),
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
                                     arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                 arg  => [{ main => [{ self => 'fix' }] }],
                                                                 name => {
                                                                           self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
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
                                     arg  => [{ main => [{ self => 'fix' }] }],
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
                         self => bless(do{\(my $o = " ")}, "Sidef::Types::String::String"),
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
                                                                 arg  => [{ main => [{ self => 'fix' }] }],
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
                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                     },
                                     {
                                       call => [
                                                 {
                                                   arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                               name => {
                                                                                         self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                                                                       },
                                                                             },
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
                                                   arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                               name => {
                                                                                         self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
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
                                                   arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                                                                                       arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                       name => {
                                                                                                                                                 self => bless(do{\(my $o = ">")}, "Sidef::Types::String::String"),
                                                                                                                                               },
                                                                                                                                     },
                                                                                                                                     {
                                                                                                                                       arg  => [
                                                                                                                                                 {
                                                                                                                                                   main => [
                                                                                                                                                     {
                                                                                                                                                       self => bless({
                                                                                                                                                         main => [
                                                                                                                                                           {
                                                                                                                                                             self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                                           },
                                                                                                                                                           {
                                                                                                                                                             call => [
                                                                                                                                                                       {
                                                                                                                                                                         arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                                         name => {
                                                                                                                                                                                   self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
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
                                                                                                                                                 self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                                               },
                                                                                                                                     },
                                                                                                                                     {
                                                                                                                                       arg  => [
                                                                                                                                                 {
                                                                                                                                                   main => [
                                                                                                                                                     {
                                                                                                                                                       self => bless({
                                                                                                                                                         main => [
                                                                                                                                                           {
                                                                                                                                                             self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                                           },
                                                                                                                                                           {
                                                                                                                                                             self => bless(do{\(my $o = 1)}, "Sidef::Types::Number::Integer"),
                                                                                                                                                           },
                                                                                                                                                         ],
                                                                                                                                                       }, "Sidef::Types::Block::Code"),
                                                                                                                                                     },
                                                                                                                                                   ],
                                                                                                                                                 },
                                                                                                                                               ],
                                                                                                                                       name => {
                                                                                                                                                 self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
                                                                                                                                               },
                                                                                                                                     },
                                                                                                                                   ],
                                                                                                                           self => 'fix',
                                                                                                                         },
                                                                                                                       ],
                                                                                                                     },
                                                                                                                   ],
                                                                                                           name => {
                                                                                                                     self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
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
                                                                                         self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                                                                       },
                                                                             },
                                                                             {
                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                               name => {
                                                                                         self => bless(do{\(my $o = "==")}, "Sidef::Types::String::String"),
                                                                                       },
                                                                             },
                                                                             {
                                                                               arg  => [
                                                                                         {
                                                                                           main => [
                                                                                             {
                                                                                               self => bless({
                                                                                                 main => [
                                                                                                   {
                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                   },
                                                                                                   { self => 'fix' },
                                                                                                 ],
                                                                                               }, "Sidef::Types::Block::Code"),
                                                                                             },
                                                                                           ],
                                                                                         },
                                                                                       ],
                                                                               name => {
                                                                                         self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                       },
                                                                             },
                                                                             {
                                                                               arg  => [
                                                                                         {
                                                                                           main => [
                                                                                             {
                                                                                               self => bless({
                                                                                                 main => [
                                                                                                   {
                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                   },
                                                                                                   {
                                                                                                     call => [
                                                                                                               {
                                                                                                                 arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                 name => {
                                                                                                                           self => bless(do{\(my $o = ">")}, "Sidef::Types::String::String"),
                                                                                                                         },
                                                                                                               },
                                                                                                               {
                                                                                                                 arg  => [
                                                                                                                           {
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({
                                                                                                                                   main => [
                                                                                                                                     {
                                                                                                                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                     },
                                                                                                                                     { self => 'fix' },
                                                                                                                                   ],
                                                                                                                                 }, "Sidef::Types::Block::Code"),
                                                                                                                               },
                                                                                                                             ],
                                                                                                                           },
                                                                                                                         ],
                                                                                                                 name => {
                                                                                                                           self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                         },
                                                                                                               },
                                                                                                               {
                                                                                                                 arg  => [
                                                                                                                           {
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({
                                                                                                                                   main => [
                                                                                                                                     {
                                                                                                                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                     },
                                                                                                                                     { self => 'fix' },
                                                                                                                                   ],
                                                                                                                                 }, "Sidef::Types::Block::Code"),
                                                                                                                               },
                                                                                                                             ],
                                                                                                                           },
                                                                                                                         ],
                                                                                                                 name => {
                                                                                                                           self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                                                         self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                       self => bless(do{\(my $o = " ")}, "Sidef::Types::String::String"),
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
                                                     call => [
                                                               {
                                                                 arg  => [{ main => [{ self => 'fix' }] }],
                                                                 name => {
                                                                           self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
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
                                     arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                 arg  => [
                                                                           {
                                                                             main => [
                                                                               {
                                                                                 call => [
                                                                                           {
                                                                                             arg  => [{ main => [{ self => 'fix' }] }],
                                                                                             name => {
                                                                                                       self => bless(do{\(my $o = "<")}, "Sidef::Types::String::String"),
                                                                                                     },
                                                                                           },
                                                                                           {
                                                                                             arg  => [
                                                                                                       {
                                                                                                         main => [
                                                                                                           {
                                                                                                             self => bless({
                                                                                                               main => [
                                                                                                                 {
                                                                                                                   self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                 },
                                                                                                                 { self => 'fix' },
                                                                                                               ],
                                                                                                             }, "Sidef::Types::Block::Code"),
                                                                                                           },
                                                                                                         ],
                                                                                                       },
                                                                                                     ],
                                                                                             name => {
                                                                                                       self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                     },
                                                                                           },
                                                                                           {
                                                                                             arg  => [
                                                                                                       {
                                                                                                         main => [
                                                                                                           {
                                                                                                             self => bless({
                                                                                                               main => [
                                                                                                                 {
                                                                                                                   self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                 },
                                                                                                                 {
                                                                                                                   call => [
                                                                                                                             {
                                                                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                               name => {
                                                                                                                                         self => bless(do{\(my $o = "==")}, "Sidef::Types::String::String"),
                                                                                                                                       },
                                                                                                                             },
                                                                                                                             {
                                                                                                                               arg  => [
                                                                                                                                         {
                                                                                                                                           main => [
                                                                                                                                             {
                                                                                                                                               self => bless({
                                                                                                                                                 main => [
                                                                                                                                                   {
                                                                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                                   },
                                                                                                                                                   { self => 'fix' },
                                                                                                                                                 ],
                                                                                                                                               }, "Sidef::Types::Block::Code"),
                                                                                                                                             },
                                                                                                                                           ],
                                                                                                                                         },
                                                                                                                                       ],
                                                                                                                               name => {
                                                                                                                                         self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                                       },
                                                                                                                             },
                                                                                                                             {
                                                                                                                               arg  => [
                                                                                                                                         {
                                                                                                                                           main => [
                                                                                                                                             {
                                                                                                                                               self => bless({
                                                                                                                                                 main => [
                                                                                                                                                   {
                                                                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                                   },
                                                                                                                                                   { self => 'fix' },
                                                                                                                                                 ],
                                                                                                                                               }, "Sidef::Types::Block::Code"),
                                                                                                                                             },
                                                                                                                                           ],
                                                                                                                                         },
                                                                                                                                       ],
                                                                                                                               name => {
                                                                                                                                         self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                                                                       self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                                                                           arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                           name => {
                                                                                                                     self => bless(do{\(my $o = "<")}, "Sidef::Types::String::String"),
                                                                                                                   },
                                                                                                         },
                                                                                                         {
                                                                                                           arg  => [
                                                                                                                     {
                                                                                                                       main => [
                                                                                                                         {
                                                                                                                           self => bless({
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                               },
                                                                                                                               { self => 'fix' },
                                                                                                                             ],
                                                                                                                           }, "Sidef::Types::Block::Code"),
                                                                                                                         },
                                                                                                                       ],
                                                                                                                     },
                                                                                                                   ],
                                                                                                           name => {
                                                                                                                     self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                   },
                                                                                                         },
                                                                                                         {
                                                                                                           arg  => [
                                                                                                                     {
                                                                                                                       main => [
                                                                                                                         {
                                                                                                                           self => bless({
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                               },
                                                                                                                               { self => 'fix' },
                                                                                                                             ],
                                                                                                                           }, "Sidef::Types::Block::Code"),
                                                                                                                         },
                                                                                                                       ],
                                                                                                                     },
                                                                                                                   ],
                                                                                                           name => {
                                                                                                                     self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                     call => [
                                                               {
                                                                 arg  => [{ main => [{ self => 'fix' }] }],
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
                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                     },
                                     {
                                       call => [
                                                 {
                                                   arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                               name => {
                                                                                         self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
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
                                                   arg  => [{ main => [{ self => 'fix' }] }],
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
                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                               name => {
                                                                                         self => bless(do{\(my $o = ">")}, "Sidef::Types::String::String"),
                                                                                       },
                                                                             },
                                                                             {
                                                                               arg  => [
                                                                                         {
                                                                                           main => [
                                                                                             {
                                                                                               self => bless({
                                                                                                 main => [
                                                                                                   {
                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                   },
                                                                                                   {
                                                                                                     call => [
                                                                                                               {
                                                                                                                 arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                 name => {
                                                                                                                           self => bless(do{\(my $o = ">=")}, "Sidef::Types::String::String"),
                                                                                                                         },
                                                                                                               },
                                                                                                               {
                                                                                                                 arg  => [
                                                                                                                           {
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({
                                                                                                                                   main => [
                                                                                                                                     {
                                                                                                                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                     },
                                                                                                                                     {
                                                                                                                                       call => [
                                                                                                                                                 {
                                                                                                                                                   arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                   name => {
                                                                                                                                                             self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                                                                                                                                           },
                                                                                                                                                 },
                                                                                                                                                 {
                                                                                                                                                   arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                   name => {
                                                                                                                                                             self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
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
                                                                                                                           self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                         },
                                                                                                               },
                                                                                                               {
                                                                                                                 arg  => [
                                                                                                                           {
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({
                                                                                                                                   main => [
                                                                                                                                     {
                                                                                                                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
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
                                                                                                                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                                               name => {
                                                                                                                                                                                         self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
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
                                                                                                                                                   arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                   name => {
                                                                                                                                                             self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
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
                                                                                                                           self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                                                         self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                       },
                                                                             },
                                                                             {
                                                                               arg  => [
                                                                                         {
                                                                                           main => [
                                                                                             {
                                                                                               self => bless({
                                                                                                 main => [
                                                                                                   {
                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
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
                                                                                                                 arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                 name => {
                                                                                                                           self => bless(do{\(my $o = ">")}, "Sidef::Types::String::String"),
                                                                                                                         },
                                                                                                               },
                                                                                                               {
                                                                                                                 arg  => [
                                                                                                                           {
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({
                                                                                                                                   main => [
                                                                                                                                     {
                                                                                                                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                     },
                                                                                                                                     {
                                                                                                                                       call => [
                                                                                                                                                 {
                                                                                                                                                   arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                   name => {
                                                                                                                                                             self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
                                                                                                                                                           },
                                                                                                                                                 },
                                                                                                                                                 {
                                                                                                                                                   arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                   name => {
                                                                                                                                                             self => bless(do{\(my $o = "+")}, "Sidef::Types::String::String"),
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
                                                                                                                           self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                         },
                                                                                                               },
                                                                                                               {
                                                                                                                 arg  => [
                                                                                                                           {
                                                                                                                             main => [
                                                                                                                               {
                                                                                                                                 self => bless({
                                                                                                                                   main => [
                                                                                                                                     {
                                                                                                                                       self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
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
                                                                                                                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                                               name => {
                                                                                                                                                                                         self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
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
                                                                                                                                                                   call => [
                                                                                                                                                                             {
                                                                                                                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                                               name => {
                                                                                                                                                                                         self => bless(do{\(my $o = "-")}, "Sidef::Types::String::String"),
                                                                                                                                                                                       },
                                                                                                                                                                             },
                                                                                                                                                                             {
                                                                                                                                                                               arg  => [{ main => [{ self => 'fix' }] }],
                                                                                                                                                                               name => {
                                                                                                                                                                                         self => bless(do{\(my $o = "==")}, "Sidef::Types::String::String"),
                                                                                                                                                                                       },
                                                                                                                                                                             },
                                                                                                                                                                             {
                                                                                                                                                                               arg  => [
                                                                                                                                                                                         {
                                                                                                                                                                                           main => [
                                                                                                                                                                                             {
                                                                                                                                                                                               self => bless({
                                                                                                                                                                                                 main => [
                                                                                                                                                                                                   {
                                                                                                                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                                                                                   },
                                                                                                                                                                                                   { self => 'fix' },
                                                                                                                                                                                                 ],
                                                                                                                                                                                               }, "Sidef::Types::Block::Code"),
                                                                                                                                                                                             },
                                                                                                                                                                                           ],
                                                                                                                                                                                         },
                                                                                                                                                                                       ],
                                                                                                                                                                               name => {
                                                                                                                                                                                         self => bless(do{\(my $o = "?")}, "Sidef::Types::String::String"),
                                                                                                                                                                                       },
                                                                                                                                                                             },
                                                                                                                                                                             {
                                                                                                                                                                               arg  => [
                                                                                                                                                                                         {
                                                                                                                                                                                           main => [
                                                                                                                                                                                             {
                                                                                                                                                                                               self => bless({
                                                                                                                                                                                                 main => [
                                                                                                                                                                                                   {
                                                                                                                                                                                                     self => bless({ name => "_", type => "var", value => undef }, "Sidef::Variable::Variable"),
                                                                                                                                                                                                   },
                                                                                                                                                                                                   { self => 'fix' },
                                                                                                                                                                                                 ],
                                                                                                                                                                                               }, "Sidef::Types::Block::Code"),
                                                                                                                                                                                             },
                                                                                                                                                                                           ],
                                                                                                                                                                                         },
                                                                                                                                                                                       ],
                                                                                                                                                                               name => {
                                                                                                                                                                                         self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                                                                                           self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                                                                         self => bless(do{\(my $o = ":")}, "Sidef::Types::String::String"),
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
                                       self => 'fix',
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
                                                     call => [
                                                               {
                                                                 arg  => [{ main => [{ self => 'fix' }] }],
                                                                 name => {
                                                                           self => bless(do{\(my $o = "*")}, "Sidef::Types::String::String"),
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
                                     arg  => [{ main => [{ self => 'fix' }] }],
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
                     ],
                   }, "Sidef::Types::Block::Code"),
        }, "Sidef::Variable::Variable"),
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
                                                          self => bless(do{\(my $o = "\\\\")}, "Sidef::Types::String::String"),
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
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
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
                                                          self => bless(do{\(my $o = "\\\\")}, "Sidef::Types::String::String"),
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
                                                          self => bless(do{\(my $o = "\\\\")}, "Sidef::Types::String::String"),
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
                                                          self => bless(do{\(my $o = "\\\\")}, "Sidef::Types::String::String"),
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
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "=")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => bless({ name => "s", type => "var", value => undef }, "Sidef::Variable::Variable"),
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
                                                  self => bless(do{\(my $o = "to_i")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_i")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                  {
                                    call => [
                                              {
                                                name => {
                                                  self => bless(do{\(my $o = "to_i")}, "Sidef::Types::String::String"),
                                                },
                                              },
                                            ],
                                    self => 'fix',
                                  },
                                  { self => 'fix' },
                                ],
                              },
                            ],
                    name => {
                              self => bless(do{\(my $o = "call")}, "Sidef::Types::String::String"),
                            },
                  },
                ],
        self => 'fix',
      },
    ],
  };
  $a->{main}[5]{self}{value}{main}[9]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[9]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[9]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[9]{call}[2]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[6]{self};
  $a->{main}[5]{self}{value}{main}[9]{call}[3]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[10]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[0]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[8]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[3]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[8]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[4]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[4]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[4]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[4]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[4]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[4]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[8]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[7]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[10]{self}{main}[2]{call}[5]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[10]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[6]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[7]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[8]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{self}{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[11]{call}[2]{arg}[0]{main}[0]{self}{main}[0]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[11]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[12]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[12]{self}{main}[0]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[7]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[12]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[8]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[12]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[12]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[7]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[12]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[12]{self}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[8]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{call}[3]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[4]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{call}[2]{arg}[0]{main}[0]{self}{main}[1]{self} = $a->{main}[5]{self}{value}{main}[2]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{call}[2]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[3]{self};
  $a->{main}[5]{self}{value}{main}[12]{self}{main}[2]{self} = $a->{main}[5]{self}{value}{main}[7]{self};
  $a->{main}[5]{self}{value}{main}[13]{call}[0]{arg}[0]{main}[0]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[1]{self};
  $a->{main}[5]{self}{value}{main}[13]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[6]{self};
  $a->{main}[5]{self}{value}{main}[13]{call}[1]{arg}[0]{main}[0]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[5]{self}{value}{main}[13]{self} = $a->{main}[5]{self}{value}{main}[5]{self};
  $a->{main}[6]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[7]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[8]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[9]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[1]{self};
  $a->{main}[10]{call}[0]{arg}[0]{main}[0]{self} = $a->{main}[6]{self};
  $a->{main}[10]{call}[0]{arg}[0]{main}[1]{self} = $a->{main}[7]{self};
  $a->{main}[10]{call}[0]{arg}[0]{main}[2]{self} = $a->{main}[8]{self};
  $a->{main}[10]{call}[0]{arg}[0]{main}[3]{self} = $a->{main}[9]{self};
  $a->{main}[10]{self} = $a->{main}[5]{self};
  $a;
}