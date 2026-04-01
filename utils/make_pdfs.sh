#!/bin/bash

markdown2pdf='markdown2pdf.pl'
version=26.04

which $markdown2pdf
echo $version

$markdown2pdf NUMBER_THEORY_REFERENCE.md --title="Sidef Programming Language - Number Theory Reference ($version)" 'sidef-number-theory-reference.pdf' --mathjax --html
$markdown2pdf NUMBER_THEORY_TUTORIAL.md --title="Sidef Programming Language - Number Theory Tutorial ($version)" 'sidef-number-theory-tutorial.pdf' --mathjax --html
$markdown2pdf NUMBER_THEORY_GUIDE.md --title="Sidef Programming Language - Number Theory Guide ($version)" 'sidef-number-theory-guide.pdf' --mathjax --html
$markdown2pdf COMPUTATIONAL_ALGEBRA_GUIDE.md --title="Sidef Programming Language - Computational Algebra Guide ($version)" 'sidef-computational-algebra-guide.pdf' --mathjax --html
$markdown2pdf SIDEF_ADVANCED_GUIDE.md --title="Sidef Programming Language - Advanced Guide ($version)" 'sidef-advanced-guide.pdf'
$markdown2pdf SIDEF_BEGINNER_GUIDE.md --title="Sidef Programming Language - Beginner's Guide ($version)" 'sidef-beginner-guide.pdf'
