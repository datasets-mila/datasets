import argparse
import copy
import glob
import hashlib
import json
import os
from pathlib import Path
import subprocess

from datalad.api import Dataset, ls
from datalad.interface.ls_webui import fs_traverse
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


def build_json_cache(path_split, repo, base_path, subdatasets=[], recurse_directories=False):
    for i in range(len(path_split) if recurse_directories else 1):
        path = '/'.join(path_split[:i+1])
        fs_traverse(path, repo,
                parent=None,
                subdatasets=[_[len(path)+1:] for _ in subdatasets if _.startswith(path)],
                render=True,
                recurse_directories=False,
                recurse_datasets=False,
                json="file",
                basepath=base_path)


def ds_need_update(root_path, ds_path):
    abs_path = os.path.join(root_path, ds_path)
    try:
        commit_hash = git.Repo(abs_path).head.object.hexsha
    except git.exc.InvalidGitRepositoryError as error:
        return False
    try:
        ds_json = load_json(abs_path, '/')
    except FileNotFoundError as error:
        return True
    return ds_json.get("commit_hash", None) != commit_hash


def fix_links(ds_path, node_path):
    ds_path = str(Path(ds_path).resolve())
    try:
        node_json = load_json(ds_path, node_path)
    except FileNotFoundError as error:
        return
    for subnode in [_ for _ in node_json["nodes"] if _["type"] in {"dir", "link", "link-broken"}]:
        resolved_path = str(Path(subnode["path"]).resolve())[len(ds_path.rstrip('/'))+1:]
        is_link = subnode["path"] != resolved_path
        if subnode["name"] != '.' and not is_link and subnode["type"] == "dir":
            fix_links(ds_path, subnode["path"])
        elif subnode["type"] == "link-broken" and os.path.isfile(resolved_path):
            subnode["type"] = "link"
        elif is_link and os.path.isdir(resolved_path):
            subnode["type"] = "dir"
            subnode["path"] = os.path.relpath(resolved_path, node_path)
    dump_json(ds_path, node_path, node_json)


def filter_nodes_duplicates(nodes):
    included_names = set()
    filtered_nodes = []
    for node in nodes:
        if node["name"] not in included_names:
            filtered_nodes.append(node)
            included_names.add(node["name"])
    return filtered_nodes


ds = Dataset(".")

subds_var = {}
subds_path = []
for path in ds.subdatasets(result_xfm='relpaths'):
    path = path.rstrip('/')
    subds_path.append(path)
    path += ".var"
    subds_var[path] = glob.glob(os.path.join(path, "*"))
    subds_var[path].sort()
    subds_path.extend(subds_var[path])

subds_to_update = [path for path in subds_path if ds_need_update(ds.path, path)]

if subds_to_update:
    ls(subds_to_update, recursive=True, all_=True, long_=True, json="file")

if subds_to_update or ds_need_update(ds.path, '.'):
    push_git_dir(os.path.join(ds.path, ".git"))
    ds.aggregate_metadata()
    pop_git_dir()
    subprocess.run([os.path.join(ds.path, "scripts/aggregate_metadata_root.sh")], check=True)

for path in ['.'] + subds_path:
    abs_path = os.path.join(ds.path, path)
    try:
        subds_json = load_json(abs_path, '/')
    except FileNotFoundError as error:
        continue
    subds_json["commit_hash"] = git.Repo(abs_path).head.object.hexsha
    subds_parent = next((_ for _ in subds_json["nodes"] if _["name"] == ".."), None)
    if path != '.' and subds_parent is None:
        subds_parent = copy.deepcopy(subds_json)
        subds_parent["path"] = os.path.relpath(".", path)
        subds_parent["name"] = ".."
        del subds_parent["nodes"]
        subds_json["nodes"].insert(1, subds_parent)
        subds_json["nodes"] = filter_nodes_duplicates(subds_json["nodes"])
    dump_json(abs_path, '/', subds_json)

ds_json = load_json(ds.path, '/')
ds_json["nodes"] = [node for node in ds_json["nodes"] if len(node["name"]) == 1 or node["name"][0] != "."]
dump_json(ds.path, '/', ds_json)
fix_links(ds.path, '/')
del ds_json["nodes"]

for subds_var_dir, subds_vars_path in subds_var.items():
    try:
        dir_json = load_json(ds.path, subds_var_dir)
    except FileNotFoundError as error:
        continue

    for subds_var_path in subds_vars_path:
        try:
            var_json = load_json(os.path.join(ds.path, subds_var_path), '/')
        except FileNotFoundError as error:
            continue

        ds_json["name"] = ".."
        ds_json["path"] = os.path.relpath(".", subds_var_path)
        var_json["nodes"].insert(1, copy.deepcopy(ds_json))
        var_json["nodes"] = filter_nodes_duplicates(var_json["nodes"])
        dump_json(os.path.join(ds.path, subds_var_path), '/', var_json)

        del var_json["nodes"]
        dir_json["nodes"].append(var_json)

    dir_json["nodes"] = filter_nodes_duplicates(dir_json["nodes"])
    dump_json(ds.path, subds_var_dir, dir_json)
