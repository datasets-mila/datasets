import argparse
import copy
import glob
import hashlib
import json
import os

from datalad.api import Dataset, ls


METADATA_PATH = ".git/datalad/metadata"

ds = Dataset(".")

subds_var = {}
for subds in ds.subdatasets():
    path = subds["path"][len(ds.path.rstrip('/'))+1:].rstrip('/') + ".var"
    subds_var[path] = glob.glob(os.path.join(path, "*"))
    subds_var[path].sort()

ds.aggregate_metadata()

ls(["."] + [path for var_paths in subds_var.values() for path in var_paths],
        recursive=True, all_=True, long_=True, json="file")

ds_path = os.path.join(ds.path, METADATA_PATH,
        hashlib.md5('/'.encode("utf-8")).hexdigest())
with open(ds_path, 'r') as f:
    ds_json = json.load(f)

ds_json["nodes"] = [node for node in ds_json["nodes"] if len(node["path"]) == 1 or node["path"][0] != "."]
with open(ds_path, 'w') as f:
    json.dump(ds_json, f)

del ds_json["nodes"]

for subds_var_root, subds_var_paths in subds_var.items():
    try:
        root_path = os.path.join(ds.path, METADATA_PATH,
                hashlib.md5(subds_var_root.encode("utf-8")).hexdigest())
        with open(root_path, 'r') as f:
            root_json = json.load(f)
    except FileNotFoundError as error:
        continue

    for subds_var_path in subds_var_paths:
        var_path = os.path.join(ds.path, subds_var_path, METADATA_PATH,
                hashlib.md5('/'.encode("utf-8")).hexdigest())
        with open(var_path, 'r') as f:
            var_json = json.load(f)

        ds_json["name"] = ".."
        ds_json["path"] = os.path.relpath(".", subds_var_path)
        var_json["nodes"].insert(1, copy.deepcopy(ds_json))
        with open(var_path, 'w') as f:
            json.dump(var_json, f)

        del var_json["nodes"]
        root_json["nodes"].append(var_json)

    with open(root_path, 'w') as f:
        json.dump(root_json, f)
