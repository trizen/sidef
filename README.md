# The Sidef Programming Language

<div align="center">

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

**A modern, high-level programming language for versatile general-purpose applications**

[Website](https://github.com/trizen/sidef) • [Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) • [Documentation](https://trizen.gitbook.io/sidef-lang/) • [Try Online](https://tio.run/#sidef) • [Discussions](https://github.com/trizen/sidef/discussions)

[![CPAN](https://img.shields.io/badge/CPAN-Sidef-blue)](https://metacpan.org/release/Sidef)
[![License](https://img.shields.io/badge/License-Artistic%202.0-green.svg)](https://www.perlfoundation.org/artistic-license-20.html)

</div>

---

## 🌟 Overview

Sidef is a modern, expressive programming language that combines the elegance of Ruby, the versatility of Raku, and the mathematical capabilities of Julia. Designed for both beginners and advanced programmers, Sidef offers a rich feature set for diverse programming paradigms.

## ✨ Key Features

<table>
<tr>
<td>

**Programming Paradigms**
- Object-oriented programming
- Functional programming
- Functional pattern matching
- Multiple dispatch

</td>
<td>

**Language Features**
- Optional lazy evaluation
- Lexical scoping & closures
- Keyword arguments
- Regular expressions

</td>
</tr>
<tr>
<td>

**Integration & Performance**
- Seamless Perl module integration
- Optional dynamic type checking
- Efficient execution model

</td>
<td>

**Numeric Computing**
- Big integers
- Rational numbers
- Arbitrary precision floats
- Complex numbers

</td>
</tr>
</table>

## 🚀 Quick Start

### Installation

**Via CPAN:**
```bash
cpan Sidef
```

**Platform-specific:**
- **Arch Linux**: [AUR package](https://aur.archlinux.org/packages/sidef/)
- **Slackware**: [SlackBuilds](https://slackbuilds.org/repository/15.0/perl/perl-Sidef/)
- **Other systems**: See [pkgs.org](https://pkgs.org/download/perl-Sidef)

### Hello World

```ruby
say "Hello, World!"
```

### Try It Online

Experiment with Sidef instantly at **[Try It Online](https://tio.run/#sidef)** without any installation.

## 📚 Documentation & Learning Resources

### Tutorials
- **[Beginner's Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md)** ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf)) - Start your Sidef journey
- **[Number Theory Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/NUMBER_THEORY_TUTORIAL.md)** ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-number-theory.pdf)) - Mathematical programming with Sidef

### Reference Materials
- **[Sidef GitBook](https://trizen.gitbook.io/sidef-lang/)** ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-book.pdf)) - Comprehensive language guide
- **[RosettaCode Examples](https://rosettacode.org/wiki/Sidef)** - Practical code examples

## 💬 Community & Support

Have questions or need help? Join the conversation:

- **[Discussion Forum](https://github.com/trizen/sidef/discussions/categories/q-a)** - Q&A and community discussions
- **[GitHub Issues](https://github.com/trizen/sidef/issues)** - Bug reports and feature requests

## 🎯 Code Examples

### The Y Combinator

Demonstrating functional programming with the [Y combinator](https://en.wikipedia.org/wiki/Fixed-point_combinator#Fixed-point_combinators_in_lambda_calculus):

```ruby
var y = ->(f) {->(g) {g(g)}(->(g) { f(->(*args) {g(g)(args...)})})}

var fac = ->(f) { ->(n) { n < 2 ? 1 : (n * f(n-1)) } }
say 10.of { |i| y(fac)(i) }     #=> [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

var fib = ->(f) { ->(n) { n < 2 ? n : (f(n-2) + f(n-1)) } }
say 10.of { |i| y(fib)(i) }     #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

### Sierpinski Triangle

ASCII generation of the [Sierpinski triangle](https://en.wikipedia.org/wiki/Sierpinski_triangle):

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

<details>
<summary>Show Output</summary>

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
</details>

### Mandelbrot Set

ASCII visualization of the [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set):

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

<details>
<summary>Show Output</summary>

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
</details>

### More Examples

Explore an extensive collection of Sidef programs at **[github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)**

## 🖥️ Interactive Mode

Sidef includes a REPL (Read-Eval-Print Loop) for interactive programming:

![Sidef Interactive Mode](https://user-images.githubusercontent.com/614513/39590990-123bd3ea-4f0b-11e8-9717-abc0ec48622e.png)

## 📦 Distribution Availability

| Platform | Package | Link |
|----------|---------|------|
| **CPAN** | `Sidef` | [metacpan.org](https://metacpan.org/release/Sidef) |
| **Package Search** | Multiple distributions | [pkgs.org](https://pkgs.org/download/perl-Sidef) |
| **Arch Linux** | `sidef` (AUR) | [AUR Package](https://aur.archlinux.org/packages/sidef/) |
| **Slackware** | `perl-Sidef` | [SlackBuilds.org](https://slackbuilds.org/repository/15.0/perl/perl-Sidef/) |

## 🤝 Contributing

Contributions are welcome! Whether it's:
- Reporting bugs
- Suggesting new features
- Improving documentation
- Submitting pull requests

Please visit the [GitHub repository](https://github.com/trizen/sidef) to get involved.

## 📄 License and Copyright

**Copyright © 2013-2026 Daniel Șuteu, Ioana Fălcușan**

This program is free software; you can redistribute it and/or modify it under the terms of the **Artistic License (2.0)**.

**Full license**: [perlfoundation.org/artistic-license-20.html](https://www.perlfoundation.org/artistic-license-20.html)

### Key License Points

- Use, modification, and distribution governed by the Artistic License
- Modified versions must comply with license requirements
- No trademark or logo usage rights granted
- Includes patent license for necessary claims
- Patent litigation terminates license

**Warranty Disclaimer**: THE PACKAGE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. See full license for details.

---

<div align="center">

**Made with ❤️ by the Sidef community**

[⭐ Star us on GitHub](https://github.com/trizen/sidef) • [📖 Read the docs](https://trizen.gitbook.io/sidef-lang/) • [💬 Join discussions](https://github.com/trizen/sidef/discussions)

</div>
