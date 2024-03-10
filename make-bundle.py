#!/usr/bin/env python
#
# A web bundler that substitutes Nix store paths in an input directory for references to an internal store.
#
from typing import Sequence
from collections.abc import Iterator
import argparse
import os.path
import shutil
import stat
import os


arg_parser = argparse.ArgumentParser()
arg_parser.add_argument(
    "graph_path", help="Path to graph file as exported by Nix exportReferencesGraph"
)
arg_parser.add_argument("directory", help="Directory to bundle")


STORE_PREFIX = "/nix/store"
INTERNAL_STORE_DIR = "_store"


def make_dest(origin: str) -> str:
    return origin.replace(STORE_PREFIX, INTERNAL_STORE_DIR, 1)


def find_files(store_path: str) -> Iterator[str]:
    """Find files in a given store path"""
    mode = os.stat(store_path).st_mode

    # If a file return a set with itself only
    if not stat.S_ISDIR(mode):
        yield store_path
        return

    # Recurse into store
    for file in os.listdir(store_path):
        yield from find_files(os.path.join(store_path, file))


def read_export_references_graph_store_paths(graph_path: str) -> Sequence[str]:
    """Store paths to scan for files as exported by Nix exportReferencesGraph"""
    store_paths: set[str] = set()

    with open(graph_path) as f:
        for line in f.readlines():
            if line.startswith(STORE_PREFIX):
                store_paths.add(line.strip())

    return list(store_paths)


def find_files_recursive(store_paths: Sequence[str]) -> list[str]:
    """Find files from all store paths"""
    store_files: set[str] = set()

    for store_path in store_paths:
        for file in find_files(store_path):
            store_files.add(file)

    # Return list in reverse order so longer prefixes are processed first
    return sorted(store_files, reverse=True)


def recurse_output(
    path: str, store_files: Sequence[str], _depth: int = 0
) -> Iterator[str]:
    mode = os.stat(path).st_mode

    # If a file return a set with itself only
    if stat.S_ISDIR(mode):
        for file in os.listdir(path):
            yield from recurse_output(
                os.path.join(path, file), store_files, _depth=_depth + 1
            )
        return

    if not stat.S_ISREG(mode):
        raise ValueError(
            f"Invalid mode for directory '{path}', needs to be either directory or regular"
        )

    # Get the number of ../../ to prefix with based on recursion depth
    store_prefix = "../" * (_depth - 1) if _depth > 1 else "./"

    with open(path, mode="rb") as f:
        data = f.read()

    for store_file in store_files:
        store_file_bytes = store_file.encode()
        if store_file_bytes in data:
            dest = store_prefix + make_dest(store_file)
            data = data.replace(store_file_bytes, dest.encode())
            yield store_file

    with open(path, mode="wb") as f:
        f.write(data)


def make_store(root: str, found_files: set[str]) -> None:
    """Copy found files to a local store"""
    for file in found_files:
        dest = os.path.join(root, make_dest(file))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy(file, dest)


if __name__ == "__main__":
    args = arg_parser.parse_args()

    # Find Nix store paths & files to work on
    store_paths = read_export_references_graph_store_paths(args.graph_path)
    store_files: list[str] = find_files_recursive(store_paths)

    # Files that were referenced in the bundle directory
    found_files: set[str] = set(recurse_output(args.directory, store_files))

    # Write files to our local store
    make_store(args.directory, found_files)
