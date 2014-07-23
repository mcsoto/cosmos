# this is a script that acts as the Cosmos interpreter
# it is not the actual interpreter but using it can sometimes be quicker than building an executable every time you modify the language
# requires Python-SWIP and SWI-Prolog 7+

import argparse
from pyswip import Prolog
import os
import sys

write = sys.stdout.write

#Program args
parser = argparse.ArgumentParser()

parser.add_argument('-f',
                   help='Write to file.')
parser.add_argument('-n',
                   help='Number of answers.')
parser.add_argument('--module',
                   help='Name of module to compile. Shortcut for "-c module.cosmos -o module.pl"')
parser.add_argument('-s',
                   help='Blah.')
parser.add_argument('-q',
                   help='Blah.')
parser.add_argument('-i',
                   help='Open the interpreter.', action="store_true")

args = parser.parse_args()

p = Prolog()

if args.module:
	module = args.module
else:
	module = 'cosmos'
	#raise "Required --module flag."

#Prolog Query
i = 0
if args.n:
	n = int(args.n)
else:
	n = float('inf')
	
#p.consult(module+'.pl')
p.consult('cosmos.pl')
pl_query = None
if args.q:
	q = args.q
	query = p.query("cosmos_env(T),catch(cosmos_run_query(T,\""+q+"\",X,_,\""+module+'\",_),E,X=E)')
	answer=next(query)
	pl_query = answer['X']
else:
	q = 'main(x)'

# run cosmos file
if args.f:
	filename = args.f
	s='cosmos_env(T),catch(cosmos_run_file(T,"'+filename+'",X),E,X=E)'
	print(s)
	query = p.query(s)
	ans=next(query)
	code=ans['X']
	print(code)
	#p.assertz(code)
	module='temp'
	#(the following is a hack)
	#write code to some dummy file
	tempfile = 'temp.pl'
	#f=open(tempfile,'w')
	#f.write(code)
	#f.close()
	#now consult this file
	#p=Prolog()
	print(p)
	p.consult('cosmos.pl') #this errors? wat
	p.consult('temp.pl')
	exit()
	

# compile some specified cosmos file
if args.module:
	#predicate compile_module(T,module,X) translates module.cosmos into Prolog code and writes to file module.pl (X = code)
	s = "cosmos_env(T),catch(cosmos_compile_module(T,\""+module+'\",X,[]),E,Y=E),(string(Y)->true;Y="right")'
	query=p.query(s)
	while True:
		try:
			answer = next(query)
			
			if(answer.has_key('Y') and answer['Y']!='right'):
				print 'CosmosError: '+str(answer['Y'])
				exit()
			ans = str(answer['X'])
			print "\ncode = " + ans
			break
		except Exception as e:
			x=e.args
			print('PrologError??')
			exit()


if pl_query!=None:
	print('---\nquerying: '+pl_query)
	print('module: '+module)
	query=p.query(pl_query)
	if args.f == None: # module is not already loaded
		p.consult(''+module+'.pl') # consults module before querying it
	print('>> '+q)
	while True:
		try:
			answer = next(query)
			ans = str(answer['_x'])
			print "| x = " + ans #str(convert(answer['X']))
			
			i += 1
			if i>=n:
				break
			#break
		except StopIteration as e:
			break
		except Exception as e:
			x=e.args
			print('RuntimeError')
			break

# open interpreter
if args.i:
	print "Cosmos 0.00"
	
	while True:
		write(">> ")
		q = raw_input()
		
		query = p.query("cosmos_env(T),catch(cosmos_run_query(T,\""+q+"\",X,_,\""+module+'\", _),E,X=E)')
		answer=next(query)
		pl_query = answer['X']
		#print('generated query: '+pl_query)
		query=p.query(pl_query)
		p.consult(''+module+'.pl')
		#print('-- '+q)
		while True:
			try:
				answer = next(query)
				vec = [x for x in answer if x[0]=='_']
				nvars = len(vec)
				if(nvars==0):
					print "true"
				else:
					write("| ")
					i=0
					for x in vec:
						ans = str(answer[x])
						write(str(x)[1:]+" = " + ans) #str(convert(answer['X']))
						i += 1
						if(i!=nvars):
							write(' and ')
					write('\n')
					
				#break
			except StopIteration as e:
				break
			except Exception as e:
				x=e.args
				print('RuntimeError')
				break
			