#!/bin/bash

perl -W ../bin/sidef -t "$@" 2> /tmp/errors-$$.txt
cat /tmp/errors-$$.txt | egrep '\b(Sidef|sidef)\b' | grep -v ' redefined at ' | grep -v '^Deep recursion ' | grep -v '^Prototype mismatch' | grep -v ' used only once ' |  grep -v '^Useless use of a constant'
rm /tmp/errors-$$.txt
