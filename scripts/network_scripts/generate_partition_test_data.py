import networkx as nx
import scipy as sc
import numpy as np
import generate_dummy_network
from  stoch_blockmodel import stoch_block
import os
import pickle as pkl
from itertools import product
"""Genertate_partition_test_data.py
This script generates the partition test data.
A pickle file for the parameters: (p,q) -pairs,f, and true partition.
For each (p,q)-pair n_rep graphs are generated. These graphs are in pickle files numbered after the (p,q)-pair used to generate them. That is, graphs_1.pkl
contains graphs generated with the first (p,q)-pair, etc..."""
if __name__== "__main__":
	
	#specify root dir for generated data
	root ="partition_test/"
	
	#specify number of replicate graphs
	n_rep = 10
	

	#Check if root dir exists
	print("Checking root dir:{}".format(root))
	if(not os.path.exists(root)):
		print("Root not found; creating...")
		os.mkdir(root)
	print("Done!")
	#Check if we have a parameter table file for generating stochastic block models
	
	
	table_path =os.path.join(root,"table.pkl")
	#If we have, let's load it!
	print("Checking for pre-existing table file exists in root:{}".format(table_path))
	if(os.path.exists(table_path)):
		print("File detected! Loading...")
		table = pkl.load(open(table_path,"rb"))
		pq,f,part =(table["pq"],table["f"],table["part"])

	else:
	#No file; let's create one. 
		#specify edge density for generated graphs
		print("File not detected! creating a table file with hardcoded parameter values...")
		f=0.1
		#specify node set size number of clusters.
		n,m = (200,10)
		
		#Create even partitions
		part = np.repeat(range(m),n/m)
		
		#let's explore these ranges of p,q with l samples of p,q.
		l=10
		p=np.linspace(f,1,l)
		q=np.linspace(f,1,l)
		
		# We don't want p,q pairs with q>p
		pq = filter(lambda x: x[0]<x[1],product(p,q))
		
		#Specify the number of graphs per (p,q)-pair
		n_rep = 10 
		
		#This is the descriptor table 
		table = {"pq":pq,"f":f,"part":part}
		
		
		table_file=open(table_path,"wb")
		pkl.dump(table,table_file)
		table_file.close()	
	print("Done!")
	#Now generate the graphs
	print("generating graph files and the Louvain clusterings...")
	for i,pair in enumerate(pq):
		network_file=os.path.join(root,"{}.pkl".format(i))
		network_data = [stoch_block(pair[0],pair[1],f,part) for i in range(n_rep) ]
		community_data=
		pkl.dump(network_data,open(network_file,"wb"))	
