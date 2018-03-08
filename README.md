# humanconnectome_2018

Welcome to the Hands-on Network Analysis, edition 2018, brain networks project! We'll use data from the Human Connectome Project (https://humanconnectome.org/). You can download the data from https://db.humanconnectome.org (requires registration and installation of the Aspera plug-in, check the release manual at https://humanconnectome.org/documentation/S900/HCP_S900_Release_Reference_Manual.pdf.

Download the minimally preprocessed data and save it in /m/cs/cs-e5700-2018/hcp (on Triton). After that, follow this minimal TODO to start investigating the data. If you face any problems that you cannot solve on your own, please contact the TA. Feel free to use Triton for your analyses when needed.

- Use scripts/load_connectome_data.py to unzip and organize the files you want. Modify the file accordingly, e.g. change paths where needed. When running, use parameter -downsample to downsample to 4 mm resolution but don't use parameter -trim to avoid problems.
- In Matlab, run make_group_mask.m to create group-level grey matter and ROI masks that can be used later in the analysis.
- Still in Matlab, run time_series_picker_wrapper.m in order to save the voxel time series in ROI order.
- As a first step of your analyses, use ROI and voxel time series to calculate adjacency matrices.
- You are now ready to play with the data!

*Some references that you may find inspiring:*

*On brain networks in general:*

- Olaf Sporns 2011. The human connectome: a complex network. Annals of the New York Academy of Sciences 1224. http://onlinelibrary.wiley.com/doi/10.1111/j.1749-6632.2010.05888.x/full

- Olaf Sporns 2013. The human connectome: Origins and challenges. NeuroImage 80. http://www.sciencedirect.com/science/article/pii/S1053811913002656

- Olaf Sporns 2011. Networks of the brain. The MIT Press. (a textbook, in the end of chapter 2, there is a nice example case of brain network analysis)

*On module differences:*

- Enrico Glerean et al. 2016. Reorganization of functionally connected brain subnetworks in high-functioning autism. http://arxiv.org/pdf/1503.04851v1.pdf (also published in Human Brain Mapping 37)

*On differences between voxel and ROI-level networks*

- Satoru Hayasaka & Paul J. Laurienti 2010. Comparison of characteristics between region- and voxel-based network analyses in resting-state fMRI data. NeuroImage 50. http://www.sciencedirect.com/science/article/pii/S1053811909013408

*On node definitions*

- Stanley, Mathew L. et al. 2013. Defining nodes in complex brain networks. Frontiers in Comp NeuroSci 7. www.ncbi.nlm.nih.gov/pmc/articles/PMC3837224/
