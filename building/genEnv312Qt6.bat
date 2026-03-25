cd cloudComPy\CloudComPy\building
conda update -y -n base -c defaults conda
conda install -y -n base mamba -c conda-forge
conda activate base

mamba env create -y -n CloudComPy312b -f CloudComPy312Qt6_Ubuntu.yml

mamba env create -y -n Python312 -f Python312_minimal.yml
