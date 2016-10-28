#!/bin/bash

#SBATCH --job-name="JOBNAME"
#SBATCH --nodes=2-4
#SBATCH --mem=8gb
#SBATCH --time=00:20:00
#SBATCH --export=ALL

#NAMD scales better using fewer cores per node
#Default distribution = block:cyclic (roundrobin)
#Use ntasks-per-node to occupy entire node

#######AMD(Mangy-Cours)@1.9Ghz################
# 10 Nodes * 48 PU/Node = 480 PU
# 4 Sockets/Node; 12 Cores/Socket
#   2 NUMAs/Socket; 6 Cores/NUMA
#   Socket = <Cores in NUMA0; Cores in NUMA1>
#   <0-5; 6-11>, <12-17; 18-23>, 
#   <24-29; 30-35>, <36-41; 42-47>
# Cores must be distributed block fashion

# SBATCH --partition=mf_m-c1.9
# SBATCH --cpus-per-task=12
##SBATCH --ntasks-per-node=4
# SBATCH --distribution=block:block
##############################################

#######AMD(Mangy-Cours)@2.2Ghz################
# 2 Nodes * 48 PU/Node = 96 PU
# 4 Sockets/Node; 12 Cores/Socket
#   2 NUMAs/Socket; 6 Cores/NUMA
#   Socket = <Cores in NUMA0; Cores in NUMA1>
#   <0-5; 6-11>, <12-17; 18-23>, 
#   <24-29; 30-35>, <36-41; 42-47>
# Cores must be distributed block fashion

# SBATCH --partition=mf_m-c2.2
# SBATCH --cpus-per-task=12
##SBATCH --ntasks-per-node=4
# SBATCH --distribution=block:block
##############################################

########AMD(Interlagos)6276@2.3GHz############
# 26 Nodes * 64 PU/Node = 1664 PU
# 4 Sockets/Node; 16 (8x2) MC-Cores/Socket 
#   2 NUMAs/Socket; 8 Cores/NUMA
#   Socket = <Cores in NUMA0; Cores in NUMA1>    
#   <0-8; 8-15>, <16-23; 24-31>
#   <32-39; 40-47>, <48-55; 56-63>
# When binding to sockets, SLURM binds to NUMA
# Cores must be distributed block fashion
# Exclusions for poorly mapped NUMA nodes

# SBATCH --partition=mf_ilg2.3
# SBATCH --cpus-per-task=16
##SBATCH --ntasks-per-node=4
# SBATCH --distribution=block:block
# Exclude poorly mapped node
# SBATCH --exclude="c-16-24" 
#############################################

######Intel(Ivy-Bridge)E5-2680v2@2.8GHz######
# 12 Nodes * 40 PU/Node = 480PU
# 2 Sockets/Node; 20 (10x2) HT-Cores/Socket
#   2 NUMAs/Socket; 10 cores/NUMA; dist=cyclic
#   Socket = <Cores in NUMA0; Cores in NUMA1>
#   <0-9; 20-29>, <10-19,30-39>

# SBATCH --partition=mf_i-b2.8
# SBATCH --cpus-per-task=20
##SBATCH --ntasks-per-node=2
#############################################

########Intel(Nehalem)5560@2.8Ghz############
# 109 Nodes * 16 PU/Node = 1774 PU 
# 2 Sockets/Node; 8 (4x2) HT-Cores/Socket
#   1:1 NUMA:Socket; dist=cyclic
#   Socket(NUMA) = <0,2,4...14>, <1,3,5...15>
# Exclusions for Westmere nodes

# SBATCH --partition=mf_nes2.8
# SBATCH --cpus-per-task=8
##SBATCH --ntasks-per-node=2
# SBATCH --ntasks-per-core=2
# SBATCH --threads-per-core=2
# SBATCH --exclude="c-3-[341-344], c-6-[231-234], c-8-[251-254]"
##############################################

########Intel(Westmere)X5660@2.8Ghz###########
# 12 Nodes * 24 PU/Node = 288 PU
# 2 Sockets/Node; 12 (6x2) HT-Cores/Socket
#   1:1 NUMA:Socket
#   Socket(NUMA) = <0-5; 12-17>, <6-11; 18-23>
# Exclusions for Nehalem nodes

# SBATCH --partition=mf_nes2.8
# SBATCH --cpus-per-task=12
##SBATCH --ntasks-per-node=2
# SBATCH --ntasks-per-core=2
# SBATCH --threads-per-core=2
# SBATCH --exclude="c-4-[3-20], c-5-[9-42], c-6-[27-30], c-7-[7-24], c-8-[16-24,27,28,31,32,35,36,39,40]"
##############################################

#------------SIMULATION SETTINGS -----------#
#binfile="npt29"
#pdbfile="1f0l_hairpin_352o349o362n.pdb"
#psffile="1f0l_hairpin_352o349o362n.psf"
#fepfile="1f0l_hairpin_352o349o362n.fep"

#fepsource="fep.tcl"
#protpar="par_all22_prot_pjf_jaf.inp"
#lippar="par_all36_lipid.prm"
#restrfile="extrabonds.txt"

#dLambda="0.05" #20 Lambda Windows
#temp="300"
#nMinSteps=100
#eqSteps=500 
#nSteps=500
#------------------------------------------#

module load namd/2.11-MPISMP
module list

cd $SLURM_SUBMIT_DIR

echo "Working Directory:" pwd
echo 'Array ID number:' $SLURM_ARRAY_TASK_ID

lambda=$SLURM_ARRAY_TASK_ID
if (( $(echo "$dLambda > 0" | bc -l) )); then
   wdir="FEP_F-SMP-HT"
   mkdir $wdir; cd $wdir
   
   lambdalist=()
   for L in $(seq 0 $dLambda 1); do
      lambdalist+=("$L")
   done
   if [ $lambda -eq 1 ]; then
      FEPcmd="runFEPmin     0   ${lambdalist[$lambda]}   $dLambda  $nSteps  $nMinSteps $temp"
   else
      FEPcmd="runFEPmin     ${lambdalist[$lambda-1]}   ${lambdalist[$lambda]}   $dLambda   $nSteps  $nMinSteps $temp"
   fi
else
   wdir="FEP_R"
   mkdir $wdir; cd $wdir
   lambdalist=()
   for L in $(seq 1 $dLambda 0); do
      lambdalist+=("$L")
   done
   if [ $lambda -eq 1 ]; then
      FEPcmd="runFEPmin     1   ${lambdalist[$lambda]}   $dLambda  $nSteps  $nMinSteps $temp" 
   else
      FEPcmd="runFEPmin     ${lambdalist[$lambda-1]}   ${lambdalist[$lambda]}   $dLambda   $nSteps  $nMinSteps $temp" 
   fi
fi

if [ $lambda -lt 10 ]; then
   lambda_dir=`printf "lambda_0%s" $lambda`
   fname="alchemy0$lambda"
else
   lambda_dir=`printf "lambda_%s" $lambda`
   fname="alchemy$lambda"
fi

if [ ! -d "$lambda_dir" ]; then
   mkdir $lambda_dir
fi

slurm_startjob(){
cd $lambda_dir
cp ../../core/alchemy.inp ./$fname.inp
#Specify inputs at top
sed -i '1iset binfile            ../../core/'$binfile  $fname.inp
sed -i '2iset outfile            '$fname    $fname.inp
sed -i '3istructure              ../../core/'$psffile  $fname.inp
sed -i '4icoordinates            ../../core/'$pdbfile  $fname.inp
sed -i '5iparameters             ../../core/'$protpar  $fname.inp
sed -i '6iparameters             ../../core/'$lippar   $fname.inp
sed -i '7iset temp               '$temp     $fname.inp

#Specify FEP Parameters at end
echo " source                   ../../core/$fepsource" >> $fname.inp
echo " alchFile                 ../../core/$fepfile"   >> $fname.inp
echo " extraBonds               on"         >> $fname.inp
echo " extraBondsFile           ../../core/$restrfile" >> $fname.inp
echo " alchEquilSteps           $eqSteps"   >> $fname.inp
echo " set nMinSteps            $nMinSteps" >> $fname.inp
echo "$FEPcmd" >> $fname.inp

cpt=$SLURM_CPUS_PER_TASK
srun --propagate=STACK namd2 ++ppn $((cpt-1)) +isomalloc_sync $fname.inp > $fname.log

cd ..

echo "JOB DONE"
}

# Function to echo informational output
slurm_info_out(){
# Informational output
echo "=================================== SLURM JOB ==================================="
date
echo
echo "The job will be started on the following node(s):"
echo $SLURM_JOB_NODELIST
echo
echo "Slurm User:         $SLURM_JOB_USER"
echo "Run Directory:      $(pwd)"
echo "Job ID:             ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo "Job Name:           $SLURM_JOB_NAME"
echo "Partition:          $SLURM_JOB_PARTITION"
echo "Number of nodes:    $SLURM_JOB_NUM_NODES"
echo "Number of tasks:    $SLURM_NTASKS"
echo "Submitted From:     $SLURM_SUBMIT_HOST:$SLURM_SUBMIT_DIR"
echo "=================================== SLURM JOB ==================================="
echo
echo "--- SLURM job-script output ---"
}

copy_results(){

if [ ! -d results ]; then
   mkdir results
fi
cp $lambda_dir/$fname.fepout ./results/
}

slurm_startjob
copy_results
slurm_info_out

date
