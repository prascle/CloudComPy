cd cloudComPy\CloudComPy\building
conda install -y -n base mamba -c conda-forge
conda update -y -n base -c defaults conda
conda activate base
mamba env create -y -n CloudComPy313 -f CloudComPy313_Ubuntu.yml
