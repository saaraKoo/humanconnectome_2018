import stoch_blockmodel
import networkx as nx

def generate_networks(filename,root,p,q,part,f):
	s=stoch_block(p,q,f,part)
	nx.write_edgelist(s,root+filename)
	f=open(root+filename,"a")
	f.write("# p {}\n#q {}\n#f {}\n partition {}".format(p,q,f,part))
	
