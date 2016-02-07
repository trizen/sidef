#!/bin/sh

alias perltidy='perltidy -l=127 -f -kbl=1 -bbb -bbc -bbs -b -ple -bt=2 -pt=2 -sbt=2 -bvt=0 -sbvt=1 -cti=1 -bar -lp -anl';
which perltidy;
cd ..;
for i in $(git status | grep '^[[:cntrl:]]*modified:' | egrep '(\.(t|pm)|sidef)$' | perl -nE 'say +(split)[-1]'); do echo $i; perltidy -b $i; done
