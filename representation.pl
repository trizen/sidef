# 21->sqrt->func('item', 24->func2('option'));

{
 self => 21,
 call => [
          {
           name => 'sqrt',
           arg  => [],
          },
          {
           name => 'func',
           arg  => [
                   'item',
                   {
                    self => 24,
                    call => [
                             {
                              name => 'func2',
                              arg  => ['option'],
                             }
                            ],
                   },
                  ],
          }
         ],
}
