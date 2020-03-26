import argparse
import copy
import glob
import hashlib
import json
import os
from pathlib import Path

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


def filter_nodes_duplicates(nodes):
    included_names = set()
    filtered_nodes = []
    for node in nodes:
        if node["name"] not in included_names:
            filtered_nodes.append(node)
            included_names.add(node["name"])
    return filtered_nodes


def fix_dir_links(ds_path, node_path):
    ds_path = str(Path(ds_path).resolve())
    node_json = load_json(ds_path, node_path)
    for subnode in [_ for _ in node_json["nodes"] if _["type"] in {"dir", "link"}]:
        resolved_path = str(Path(subnode["path"]).resolve())[len(ds_path.rstrip('/'))+1:]
        is_link = subnode["path"] != resolved_path
        if subnode["name"] != '.' and not is_link and subnode["type"] == "dir":
            fix_dir_links(ds_path, subnode["path"])
        elif is_link and os.path.isdir(resolved_path):
            subnode["type"] = "dir"
            subnode_json = load_json(ds_path, subnode["path"])
            subnode_json["type"] = "dir"
            subnode_here = next((_ for _ in subnode_json["nodes"] if _["name"] == "."), None)
            if subnode_here is not None:
                subnode_here["type"] = "dir"
            subnode_parent = next((_ for _ in subnode_json["nodes"] if _["name"] == ".."), None)
            if subnode_parent is None:
                subnode_parent = copy.deepcopy(node_json)
                subnode_parent["name"] = ".."
                del subnode_parent["nodes"]
                subnode_json["nodes"].insert(1, subnode_parent)
                subnode_json["nodes"] = filter_nodes_duplicates(subnode_json["nodes"])
            dump_json(ds_path, subnode["path"], subnode_json)
    dump_json(ds_path, node_path, node_json)


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


is_ds_need_update = ds_need_update(ds.path, '.')
ds_to_update = [path for path in subds_path if ds_need_update(ds.path, path)]

push_git_dir(os.path.join(ds.path, ".git"))
if is_ds_need_update:
    ds.aggregate_metadata()
ls(ds_to_update, recursive=True, all_=True, long_=True, json="file")
if is_ds_need_update:
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

ds_json = load_json(ds.path, '/')
ds_json["nodes"] = [node for node in ds_json["nodes"] if len(node["name"]) == 1 or node["name"][0] != "."]
dump_json(ds.path, '/', ds_json)
fix_dir_links(ds.path, '/')

del ds_json["nodes"]

for subds_var_dir, subds_vars_path in subds_var.items():
    try:
        dir_json = load_json(ds.path, subds_var_dir)
    except FileNotFoundError as error:
        continue

    for subds_var_path in subds_vars_path:
        var_json = load_json(os.path.join(ds.path, subds_var_path), '/')

        ds_json["name"] = ".."
        ds_json["path"] = os.path.relpath(".", subds_var_path)
        var_json["nodes"].insert(1, copy.deepcopy(ds_json))
        var_json["nodes"] = filter_nodes_duplicates(var_json["nodes"])
        dump_json(os.path.join(ds.path, subds_var_path), '/', var_json)

        del var_json["nodes"]
        dir_json["nodes"].append(var_json)

    dir_json["nodes"] = filter_nodes_duplicates(dir_json["nodes"])
    dump_json(ds.path, subds_var_dir, dir_json)
