#!/usr/bin/env bash

export START_DIR=$PWD

model_name=$1
timestamp=$2
path_to_export_config=$3
path_to_remove_init_tool=$4
path_to_export_modif=$5

if [ ! -d "trainer/P3TrainFarm" ]; then
  echo "P3TrainFarm is not constructed. Please run install_p3trainfarm.sh"
  exit 0
fi

cd trainer/P3TrainFarm
# Checking if the p2_trainer conda environment has been installed.
env_exists=$(conda env list | grep p3_exporter)

if [ -z "$env_exists" ]
then
      echo "Installing p3_exporter conda environment."
      conda create --name p3_exporter python=3.7.0 -y
      eval "$(conda shell.bash hook)"
      conda activate p3_exporter
      conda install ipython -y
      pip3 install ninja yacs cython matplotlib tqdm opencv-python requests onnx onnxruntime

      conda install -c pytorch pytorch-nightly cudatoolkit=10.0 -y
      conda install pytorch==1.2.0 torchvision -y # Temp for magic fix.
      pip3 uninstall numpy -y
      pip3 install numpy==1.19.2
      # Download maskrcnn-benchmark. Await modification later before building.
      git clone https://github.com/BowenBao/maskrcnn-benchmark.git --branch onnx_stage_mrcnn --single-branch p3_exporter --depth 1
      cd p3_exporter
      export INSTALL_DIR=$PWD
      python3 setup.py build develop

      # Install pycocotools
      git clone https://github.com/cardboardcode/cocoapi.git
      cd cocoapi/PythonAPI
      python3 setup.py build_ext install

      # Install apex
      cd $INSTALL_DIR
      git clone https://github.com/cardboardcode/apex.git
      cd apex
      python3 setup.py install

      # Add in remove_initializer.py tool that is not naturally present in onnx_stage.
      cd $INSTALL_DIR
      mkdir -p configs/custom
      # cd $START_DIR
      # cp $path_to_export_config $INSTALL_DIR/configs/custom/maskrcnn_export.yaml

      cd $INSTALL_DIR
      mkdir -p weights/custom

      # Copy in remove_initializer.py into the maskrcnn-benchmark folder
      cd $START_DIR
      cp $path_to_remove_init_tool $INSTALL_DIR/demo/remove_initializer.py
      cp $path_to_export_modif $INSTALL_DIR/demo/export_to_onnx.py

      echo "[p3_exporter] conda env created."
else
      echo "[p3_exporter] - FOUND. Skipping installation."
      eval "$(conda shell.bash hook)"
      conda activate p3_exporter

      # Download maskrcnn-benchmark. Await modification later before building.
      git clone https://github.com/BowenBao/maskrcnn-benchmark.git --branch onnx_stage_mrcnn --single-branch p3_exporter --depth 1
      cd p3_exporter
      export INSTALL_DIR=$PWD
      python3 setup.py build develop

      cd $INSTALL_DIR
      mkdir -p configs/custom
      # cd $START_DIR
      # cp $path_to_export_config $INSTALL_DIR/configs/custom/maskrcnn_export.yaml

      cd $INSTALL_DIR
      mkdir -p weights/custom

      # Copy in remove_initializer.py into the maskrcnn-benchmark folder
      cd $START_DIR
      cp $path_to_remove_init_tool $INSTALL_DIR/demo/remove_initializer.py
      cp $path_to_export_modif $INSTALL_DIR/demo/export_to_onnx.py
fi

unset env_exists INSTALL_DIR START_DIR
