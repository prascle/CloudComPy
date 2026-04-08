cd cloudComPy\CloudComPy\building
conda update -y -n base -c defaults conda
:: ne parvient pas a faire la mise a jour de conda, il faut d'abord installer mamba, puis faire la mise a jour de conda avec mamba  
:: conda update --all : casse conda !
conda install -y -n base mamba -c conda-forge
mamba update -y -n base -c defaults conda
conda activate base

mamba env create -y -n CloudComPy312 -f CloudComPy312Qt6_Ubuntu.yml

mamba env create -y -n Python312 -f Python312_minimal.yml
