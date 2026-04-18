cd cloudComPy\CloudComPy\building
conda install -y -n base mamba -c conda-forge
mamba update -y -n base -c defaults conda
conda activate base

mamba env create -y -n CloudComPy312 -f CloudComPy312Qt6_Ubuntu.yml
