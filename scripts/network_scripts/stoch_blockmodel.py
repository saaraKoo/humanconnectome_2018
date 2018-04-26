import networkx as nx
import scipy as sc
import numpy as np
from itertools import product 
	

# Generate a random stochastic block matrix with planted community structure
## p: probability of connecting nodes within partition
## q: probability of connecting nodes within partition
## f: fraction of covered edge pairs
## partition: vector of partition memberships, with n nodes and r clusters 
def stoch_block(p,q,f,partition_vector):
	nodes= len(partition_vector)
	blocks =len(set(partition_vector))
	edge_count = int(np.floor(sc.misc.comb(nodes,2)*f))
	edge_list = []
	while len(edge_list) < edge_count:
		r = np.random.uniform()
		a,b = (np.random.randint(0,nodes),np.random.randint(0,nodes))
		if(a!=b):
			in_block = partition_vector[a] == partition_vector[b]
			if in_block:
				if r>=1-p:
					edge_list.append((a,b))
			else:
				if r>=1-q:
					edge_list.append((a,b)) 
	result = nx.Graph()	
	result.add_edges_from(edge_list)
	return result
	
	
