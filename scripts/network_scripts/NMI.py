import numpy as np
import scipy as sc
from itertools import product
#a,b: two community structure vectors of size n;
# n: number of nodes
# values of vector: community of membership .i.e if element 3 is 2, node 3 belongs to cluster 2
def NMI(a,b):
	c_a = list(set(a))
	c_b =list(set(b))
	N=len(a)
	n,m =len(c_a),len(c_b)
	confusion =np.zeros((n,m))
	idx_a={y:x for x,y in enumerate (c_a)}
	idx_b={y:x for x,y in enumerate (c_b)}
	for c,d in zip(c_a,c_b):
		confusion[idx_a[c],idx_b[d]]+=1
		
	result,k_0,k_1 = 0,0,0
	for i,j in product(idx_a.values(),idx_b.values()):
		n_ij =float(confusion[i,j])
		n_i  =float(np.sum(confusion[i,:])) 
		n_j  =float(np.sum(confusion[:,j])) 
		
		k_0 +=n_i*np.log(n_i/float(N))
		k_1 +=n_j*np.log(n_j/float(N))
		
		
		if n_ij>0:
			result-=2*n_ij*np.log(n_ij*float(N)/(n_i*n_j))

	return result/(k_0+k_1	)
