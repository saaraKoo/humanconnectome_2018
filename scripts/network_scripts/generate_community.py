import community 
import os
import sys
import networkx as nx
import pickle as pkl
import numpy as np
import scipy as sc 
import pandas as pd
from functools import reduce

 
def load_r_adj_csv(input_dir):
	subject_adj={}
	#Crawl input directory for csv files
	for f in os.walk(input_dir):
		dirpath,folders,files=f
		csv = filter(lambda x: ".csv" == x[-4:],files)
		for k in csv:
			#subject_name=dirpath.split("/")[-1]
			subject_name=k.split(".")[0]
			full_path=os.path.join(dirpath,k)
			subject_adj[subject_name]=pd.read_csv(full_path,index_col=None,header=None)
	return subject_adj
def load_adj_csv(input_dir):
	#Loads all csv files in directory input dir
	result = {}
	for f in os.listdir(input_dir):
		
		#Extract file extension
		ext = f.split(".")[1]
		if ext == "csv":
			
			#Extract subject id; e.g 12345_adj.csv
			name = f.split("_")[0]
			path=os.path.join(input_dir,f)
			result[name]=pd.read(path,header=None,index_col=None)
	return result
	

def write_hmetis(subject_community,hmetis_fname,input_dir):
	hmetis=open(os.path.join(input_dir,hmetis_fname),"w")
	
	#Count the number of nodes and clusters (hyperedges)
	n = len(list(list(subject_community.values())[0]))
	m = sum([max(list(values.values()))  for name,values in subject_community.items()])
	hmetis.write("{}\t{}\n".format(m,n))
	print("n,m:{} {}".format(n,m))
	i=0
	
	for name, community in subject_community.items():
		
		#Print progress
		print("{}% done...".format(float(i)/float(n)))
		#Write the subject name in comment  
		hmetis.write("%{}\n".format(name))
		
		#Generate hyperedges
		h_edges={x:[] for x in set(community.values())}
		for x,y in community.items():
			#HMETIS indexes nodes starting from 1 instead of 0, so let's rename node n to n+1
			h_edges[y].append(x+1)
		#Write hyperedges into file
		for x,y in h_edges.items():
			z=[str(a) for a in y]
			hmetis.write(reduce(lambda a,b: "{} {}".format(a,b),z)+"\n")
	hmetis.close()
	
	
if __name__ == "__main__":
	
	#Parse input directory containing csv files of correlation matrices; output dir for pickled matrices, generated adjacency matrices and generated communities.
	input_dir,output_dir = sys.argv[1:]

	subject_adj=load_r_adj_csv(input_dir,output_dir)

	#Cast in to nx Graph.

	#Detect communities using Louvain modularity maximization
	subject_community={x:community.best_partition(nx.Graph(y.values)) for x,y in subject_adj.items()}
	#Pickle them.
	com_path= output_dir
	com_fname="communities.pkl"
	pkl.dump(subject_adj,open(os.path.join(com_path,com_fname),"wb"))
	
	#Finally, let's generate something nice for HMETIS
	hmetis_fname="communities.hypergraph"
	write_hmetis(subject_community,hmetis_fname,input_dir)

	
			
				
