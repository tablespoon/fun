#!/usr/bin/python

trials=10000000

from random import random
def calc():
	counter=0
	for i in xrange(trials):
		if random()**2 + random()**2 <= 1:
			counter+=1
	return float(counter)/trials*4


print calc()
