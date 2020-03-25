import argparse
import copy
import glob
import hashlib
import json
import os

from datalad.api import Dataset, ls
import git


METADATA_PATH = ".git/datalad/metadata"
_GIT_DIR_STACK = []


def push_git_dir(path):
    try:
        _GIT_DIR_STACK.append(os.environ["GIT_DIR"])
    except KeyError:
        pass

    os.environ["GIT_DIR"] = path


def pop_git_dir():
    try:
        os.environ["GIT_DIR"] = _GIT_DIR_STACK.pop()
    except IndexError:
        del os.environ["GIT_DIR"]


def load_json(ds_path, entry):
    path = os.path.join(ds_path, METADATA_PATH,
            hashlib.md5(entry.encode("utf-8")).hexdigest())
    with open(path, 'r') as f:
        return json.load(f)


def dump_json(ds_path, entry, json_content):
    path = os.path.join(ds_path, METADATA_PATH,
            hashlib.md5(entry.encode("utf-8")).hexdigest())
    with open(path, 'w') as f:
        json.dump(json_content, f)


def ds_need_update(root_path, ds_path):
    abs_path = os.path.join(root_path, ds_path)
    try:
        ds_json = load_json(abs_path, '/')
    except FileNotFoundError as error:
        return True

    return ds_json.get("commit_hash", None) != git.Repo(abs_path).head.object.hexsha


ds = Dataset(".")

subds_var = {}
subds_path = []
for subds in ds.subdatasets():
    path = subds["path"][len(ds.path.rstrip('/'))+1:].rstrip('/')
    subds_path.append(path)
    path += ".var"
    subds_var[path] = glob.glob(os.path.join(path, "*"))
    subds_var[path].sort()
    subds_path.extend(subds_var[path])

push_git_dir(os.path.join(ds.path, ".git"))
ds.aggregate_metadata()

ls([path for path in subds_path if ds_need_update(ds.path, path)],
        recursive=True, all_=True, long_=True, json="file")

ls('.', recursive=False, all_=True, long_=True, json="file")
pop_git_dir()

for path in ['.'] + subds_path:
    abs_path = os.path.join(ds.path, path)
    try:
        ds_json = load_json(abs_path, '/')
    except FileNotFoundError as error:
        continue
    ds_json["commit_hash"] = git.Repo(abs_path).head.object.hexsha
    dump_json(abs_path, '/', ds_json)

ds_json = load_json(ds.path, '/');
ds_json["nodes"] = [node for node in ds_json["nodes"] if len(node["path"]) == 1 or node["path"][0] != "."]
dump_json(ds.path, '/', ds_json)

del ds_json["nodes"]

for subds_var_dir, subds_vars_path in subds_var.items():
    try:
        dir_json = load_json(ds.path, subds_var_dir);
    except FileNotFoundError as error:
        continue

    for subds_var_path in subds_vars_path:
        var_json = load_json(os.path.join(ds.path, subds_var_path), '/');

        ds_json["name"] = ".."
        ds_json["path"] = os.path.relpath(".", subds_var_path)
        var_json["nodes"].insert(1, copy.deepcopy(ds_json))
        dump_json(os.path.join(ds.path, subds_var_path), '/', var_json)

        del var_json["nodes"]
        dir_json["nodes"].append(var_json)

    dump_json(ds.path, subds_var_dir, dir_json)
