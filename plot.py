#!/usr/bin/env python

import fileinput
import numpy
import pylab
labels=[];
for line in fileinput.input():
  (label,foo,datastr)=line.partition(":")
  labels.append(label)
  data = numpy.array(datastr.split(","))
  pylab.plot(range(len(data)),data,label=label)
  pylab.hold(True)

pylab.legend()
pylab.show()
          
