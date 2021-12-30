IMAGE_NAME := centerpoint-kitti
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
KITTI_ROOT :=

.PHONY: build
build:
	docker build -t $(IMAGE_NAME):latest .

.PHONY: prepare
prepare:
ifndef KITTI_ROOT
	echo "argument KITTI_ROOT is not defined"
	exit 1
endif
	docker run -it --rm --gpus all \
		-v $(KITTI_ROOT)/training:/app/centerpoint/data/kitti/training \
		-v $(KITTI_ROOT)/testing:/app/centerpoint/data/kitti/testing \
		-v $(MAKEFILE_DIR)/data/:/app/centerpoint/data/ \
		-v $(MAKEFILE_DIR)/output:/app/centerpoint/output \
		--workdir /app/centerpoint/tools \
		$(IMAGE_NAME):latest \
		python -m pcdet.datasets.kitti.kitti_dataset create_kitti_infos cfgs/dataset_configs/kitti_dataset.yaml

.PHONY: train
train:
ifndef KITTI_ROOT
	echo "argument KITTI_ROOT is not defined"
	exit 1
endif
	docker run -it --rm --gpus all \
		-v $(KITTI_ROOT)/training:/app/centerpoint/data/kitti/training \
		-v $(KITTI_ROOT)/testing:/app/centerpoint/data/kitti/testing \
		-v $(MAKEFILE_DIR)/data/:/app/centerpoint/data/ \
		-v $(MAKEFILE_DIR)/output:/app/centerpoint/output \
		--workdir /app/centerpoint/tools \
		$(IMAGE_NAME):latest \
		python train.py --cfg_file cfgs/kitti_models/centerpoint.yaml