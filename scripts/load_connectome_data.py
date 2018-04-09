

'''
This is a small piece of python script that extracts the useful parts from human connectome datasets.

Hardcoded for structural T1 and Resting state REST1_LR datas.
Takes a folder with Connectome data zips as input and outputs subject folders with nifti files.

Usage:
python load_connectome_data.py <arguments> <inputfolder> <outputfolder>
Possible arguments:
-preproc 		the data is preprocessed (default)
-unproc 		the data is unprocessed
-trim 			the data will be cut to half (from the beginning of the timeseries)
-downsample 	the data will be downsampled to 4mm

Warning: trimming and downsampling the files requires flirt tools installation!
Downsampling also requires the DSTEMPLATE filepath setting.

@author Jaakko Vallinoja
'''


#Put the 4mm template filepath here
#DSTEMPLATE = '/u/60/aokorhon/unix/opetus/HCPdata/MNI152_T1_4mm_brain.nii'
DSTEMPLATE = '/m/cs/scratch/cs-e5700-2018/hcp/raw_data/HO_masks/MNI152_T1_4mm_brain.nii'

import os
import sys
import zipfile
import gzip
import fnmatch
import shutil
import subprocess

TRIM = False # a global settings variables for trimming the files... spaghetti...
DOWNSAMPLE = False

def main(argv):

	if len(argv) < 2:
		print 'Usage:\npython load_connectome_data.py <arguments> <inputfolder> <outputfolder>\nPossible arguments:\n-preproc \tthe data is preprocessed (default)\n-unproc \tthe data is unprocessed\n-trim \t\tthe data will be cut to half (from the beginning of the timeseries)\n-downsample \tthe data will be downsampled to 4mm'
		print 'Warning: trimming and downsampling the files requires flirt tools installation!'
		return

	print 
	print 'Data extraction may take several minutes per subject. If you have a large dataset, do something useful for a while.'
	print

	preproc = True
	for a in argv:
		if a == '-trim':
			global TRIM 
			TRIM = True
		elif a == '-downsample':
			global DOWNSAMPLE 
			DOWNSAMPLE = True
		elif a == '-preproc':
			preproc = True
		elif a == '-unproc':
			preproc = False
	
	rootdir = argv[-2] #give the main data folder and
	targetdir = argv[-1] #the target as the last arguments
	
	zips = findZipFiles(rootdir)
	l = len(zips)
	i = 0.0
        import pdb; pdb.set_trace()
	for z in zips:
		try:
			print '{0:.0f}%'.format(i/l * 100) + ' done.'
			print 'Looking at zipfile: ' +z
			extractDataFromZip(z, targetdir, preproc)
		except:
			print
			print 'ERROR:',sys.exc_info()[0]
			print
		i += 1
	createDirectory(targetdir, 'masks')#creates a directory for groupmasks
	print
	print '100%% done.'
	removeEmptyDataFolders(targetdir)
	


def findZipFiles(rootdir, preproc=True):
        # add here the names of files you want to pick
	zips = []
	if preproc:
		temp1 = '*3T_Structural_preproc.zip'
		temp2 = '*3T_rfMRI_REST1_preproc.zip'
	else:
		temp1 = '*3T_Structural_unproc.zip'
		temp2 = '*3T_rfMRI_REST1_unproc.zip'
	# go trough the entire directory tree.
	for root, subfolders, files in os.walk(rootdir):
		for filename in fnmatch.filter(files, temp1):
			zips.append(os.path.join(root, filename))
		for filename in fnmatch.filter(files, temp2):
			zips.append(os.path.join(root, filename))
	return zips

def extractDataFromZip(filepath, target, preproc=True):
	masktemp = None
	trim = False
	# first lets extract the subject "name"
	subject_name = filepath.rsplit('/',1)[-1].rsplit('_')[0]
	# then create a folder for that jubject if it does not exist
	dirname = createDirectory(target, subject_name)
	# create a zip object
	zipped = zipfile.ZipFile(filepath)
	# extract the nii.gz file from it

	# if the file is a structural file
	if 'Structural' in filepath:
		if preproc:
			return
                        # Preprocessed structural data are not needed for analysis
			#TODO find the right files if structural preprocessed needed.
			#temp = ''
		else:
			temp = 'unprocessed/3T/T1w_MPR1/'+subject_name+ '_3T_T1w_MPR1.nii.gz'
	# if the file is resting state data
	elif 'REST1' in filepath: # TODO: update this part if you want to read something else than resting state
		trim = True
		if preproc:
			temp = 'MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR.nii.gz'
			masktemp = 'MNINonLinear/Results/rfMRI_REST1_LR/brainmask_fs.2.nii.gz'
			#unzipped = zipped.extract(temp, dirname)
		else:
			temp = 'unprocessed/3T/T1w_MPR1/'+subject_name+ '_3T_rfMRI_REST1_LR.nii.gz'
	# 
	else:
		return

	# unzip the data
	unzipped = zipped.extract(os.path.join(subject_name, temp), dirname)
	
	#this next function is a bit of a hack to automatically trim the files.
	if trim:
		unzipped = autoTrimAndDs(unzipped, 'downsampled_4mm_rest_LR.nii.gz')

	# then extract the .gz compresison
	print 'Extracting ' +unzipped
	extractDataFromGZip(unzipped, target, subject_name)
	# if there is a brainmask file lets unzip that too
	if masktemp:
		unzipped = zipped.extract(os.path.join(subject_name, masktemp), dirname)
		if trim:
			unzipped = autoTrimAndDs(unzipped, 'brainmask_fs.4.nii.gz')

		extractDataFromGZip(unzipped, target, subject_name)

	# then remove the unused directory tree (from zip extract. gzip extract moves files to target/subject_name)
	shutil.rmtree(os.path.join(target,subject_name,subject_name))

# extracts from gzip and writes to a new uncompressed file
def extractDataFromGZip(filepath, target, subject_name):
	with gzip.open(filepath, 'rb') as f:
		file_content = f.read()
	ungzipped = filepath.rsplit('/',1)[-1].rsplit('.',1)[-2] #this feels like a hack...
	ungzipped = os.path.join(target, subject_name, ungzipped)
	with open(ungzipped, 'wb') as f:
		f.write(file_content)

# creates a directory "target/subject_name" if it does not exist
def createDirectory(target, subject_name):
	dir = os.path.join(target, subject_name)
	if not os.path.exists(dir):
		os.makedirs(dir)
	return dir


# calls flirt tools to trim and downsample the stupidly big resting state data 
def autoTrimAndDs(unzipped, name):
	newname = os.path.dirname(unzipped) + '/' + name
	if TRIM:
		trimname = os.path.dirname(unzipped) + '/trimmed_rest_LR.nii.gz'
		subprocess.call(['fslroi', unzipped, trimname, '3', '600'])
	else:
		trimname = unzipped
	if DOWNSAMPLE:
		subprocess.call(['flirt', '-applyisoxfm', '4', '-in', trimname, '-ref', DSTEMPLATE, '-out', newname, '-interp', 'nearestneighbour'])
	else:
		newname = trimname
	return newname

def removeEmptyDataFolders(parentdir):
	raw_subject_folders = [x[0] for x in os.walk(parentdir)]
	raw_subject_folders = [x+'/' for x in raw_subject_folders if x != parentdir and x != parentdir+'masks']
	count = 0
	for f in raw_subject_folders:
		if not os.listdir(f):
			count += 1
			shutil.rmtree(f)
	print 'Note: Removed '+str(count)+' faulty (empty) raw data folders.'



if __name__ == "__main__":
	main(sys.argv[1:])





