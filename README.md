The Sidef Programming Language
=======

Sidef is a modern, high-level, general-purpose programming language, inspired by Ruby, Perl 6 and Julia.

```
            **   **         ****   *           *********   *********
          * * ** * *        ****   **          ** ** **    ** ** **
           **   **          ****   ***         *********   *  *  *
  **        **        **    ****   *  *        ******      ******
* * *     * * *     * * *   ****   ** **       ** **       ** **
 **        **        **     ****   ******      ******      *  *
       **   **              ****   *  *  *     *********   ***
     * * ** * *             ****   ** ** **    ** ** **    **
      **   **               ****   *********   *********   *
```

* The main features of Sidef include:

    * object-oriented programming
    * functional programming
    * functional pattern matching
    * optional lazy evaluation
    * multiple dispatch
    * lexical scoping
    * lexical closures
    * keyword arguments
    * regular expressions
    * support for metaprogramming
    * support for using Perl modules
    * optional dynamic type checking
    * big integers, rationals, floats and complex numbers

### WWW

* Gitbook: http://trizen.gitbooks.io/sidef-lang
* Tutorial: https://github.com/trizen/sidef/wiki
* RosettaCode: http://rosettacode.org/wiki/Sidef

### EXAMPLES

* The [Y combinator](https://en.wikipedia.org/wiki/Fixed-point_combinator#Fixed_point_combinators_in_lambda_calculus):
```ruby
var y = ->(f) {->(g) {g(g)}(->(g) { f(->(*args) {g(g)(args...)})})}

var fac = ->(f) { ->(n) { n < 2 ? 1 : (n * f(n-1)) } }
say 10.of { |i| y(fac)(i) }     #=> [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

var fib = ->(f) { ->(n) { n < 2 ? n : (f(n-2) + f(n-1)) } }
say 10.of { |i| y(fib)(i) }     #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

* Approximation of the [gamma function](https://en.wikipedia.org/wiki/Gamma_function):
```ruby
define ℯ = Num.e
define τ = Num.tau
 
func Γ(t, r=50) {
    t < r ? (__FUNC__(t + 1) / t)
           : (sqrt(τ*t) * pow(t/ℯ + 1/(12*ℯ*t), t) / t)
}
 
for i in (1..10) {
    say ("%.14f" % Γ(i/3))
}
```

* ASCII generation of the [Sierpinksi triangle](https://en.wikipedia.org/wiki/Sierpinski_triangle):
```ruby
func sierpinski_triangle(n) {
    var triangle = ['*']
    { |i|
        var sp = (' ' * 2**i)
        triangle = (triangle.map {|x| sp + x + sp} +
                    triangle.map {|x| x + ' ' + x})
    } * n
    triangle.join("\n")
}

say sierpinski_triangle(4)
```
...producing:
```text
               *               
              * *              
             *   *             
            * * * *            
           *       *           
          * *     * *          
         *   *   *   *         
        * * * * * * * *        
       *               *       
      * *             * *      
     *   *           *   *     
    * * * *         * * * *    
   *       *       *       *   
  * *     * *     * *     * *  
 *   *   *   *   *   *   *   * 
* * * * * * * * * * * * * * * *
```

* ASCII generation of the [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set):
```ruby
func mandelbrot(z, r=20) {
    var c = z
    r.times {
        z = (z*z + c)
        return true if (z.abs > 2)
    }
    return false
}

for y in (1 `downto` -1 `by` 0.05) {
    for x in (-2 `upto` 0.5 `by` 0.0315) {
        print(mandelbrot(Complex(x, y)) ? ' ' : '#')
    }
    print "\n"
}
```
...producing:
```text
                                                                                
                                                            #                   
                                                        #  ###  #               
                                                        ########                
                                                       #########                
                                                         ######                 
                                             ##    ## ############  #           
                                              ### ###################      #    
                                              #############################     
                                              ############################      
                                          ################################      
                                           ################################     
                                         #################################### # 
                          #     #        ###################################    
                          ###########    ###################################    
                           ###########   #####################################  
                         ############## ####################################    
                        ####################################################    
                     ######################################################     
#########################################################################       
                     ######################################################     
                        ####################################################    
                         ############## ####################################    
                           ###########   #####################################  
                          ###########    ###################################    
                          #     #        ###################################    
                                         #################################### # 
                                           ################################     
                                          ################################      
                                              ############################      
                                              #############################     
                                              ### ###################      #    
                                             ##    ## ############  #           
                                                         ######                 
                                                       #########                
                                                        ########                
                                                        #  ###  #               
                                                            #                   
                                                                                
```

* For more examples, see:
   * [https://github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)

### REPL
The [read-eval-print loop](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) is available by executing `sidef -i`:
![sidef](https://user-images.githubusercontent.com/614513/32416918-e687f938-c259-11e7-8c06-a4f34241c087.png)

### AVAILABILITY

* CPAN: [https://metacpan.org/release/Sidef](https://metacpan.org/release/Sidef)
* PKGS.org: [https://pkgs.org/download/Sidef](https://pkgs.org/download/Sidef)
* Arch Linux: [https://aur.archlinux.org/packages/sidef/](https://aur.archlinux.org/packages/sidef/)
* Slackware: [https://slackbuilds.org/repository/14.2/perl/perl-Sidef/](https://slackbuilds.org/repository/14.2/perl/perl-Sidef/)

### LICENSE AND COPYRIGHT

* Copyright (C) 2013-2017 Daniel Șuteu, Ioana Fălcușan

This program is free software; you can redistribute it and/or modify it
under the terms of the *Artistic License (2.0)*. You may obtain a copy
of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
