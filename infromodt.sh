#!/bin/bash

#INSTALL@ /usr/local/bin/infromodt

      ODTS=`ls *.odt 2> /dev/null | wc -l `
      if [ $ODTS != 0 ] ; then
            for FILE in *.odt ; do
                  BASE=${FILE%%.odt}
                  odt2txt --width=-1 $FILE > temporary.txt
                  txt2in temporary.txt > $BASE.in
                  rm temporary.txt
            done
      fi

