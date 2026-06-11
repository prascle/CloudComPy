cd cloudComPy\CloudComPy\building
conda update -y -n base -c defaults conda
conda install -y -n base mamba -c conda-forge
conda activate base

mamba env create -y -n CloudComPy313 -f CloudComPy313_Ubuntu.yml

mamba env create -y -n Python313 -f Python313_minimal.yml
