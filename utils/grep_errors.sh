#!/bin/bash

perl -W ../bin/corvin -t "$@" 2> /tmp/errors-$$.txt
cat /tmp/errors-$$.txt | egrep '\b(?:Corvinus|corvin)\b' | grep -v ' redefined at ' | grep -v '^Deep recursion ' | grep -v '^Prototype mismatch' | grep -v ' used only once '
rm /tmp/errors-$$.txt
