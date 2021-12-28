IMAGE_NAME := centerpoint-kitti
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
KITTI_ROOT :=

.PHONY: build
build:
	docker build -t $(IMAGE_NAME):latest .

.PHONY: prepare
ifndef KITTI_ROOT
	echo "argument KITTI_ROOT is not defined"
	exit 1
endif
prepare:
	docker run --rm -it --gpus all \
		-v $(KITTI_ROOT)/training:/app/centerpoint/data/kitti/training \
		-v $(KITTI_ROOT)/testing:/app/centerpoint/data/kitti/testing \
		-v $(MAKEFILE_DIR)/data/kitti/ImageSets:/app/centerpoint/data/kitti/ImageSets \
		$(IMAGE_NAME):latest \
		python -m pcdet.datasets.kitti.kitti_dataset create_kitti_infos tools/cfgs/dataset_configs/kitti_dataset.yaml
