#!/usr/bin/env python
import argparse
import os.path
import shutil
import json
import sys
import os


arg_parser = argparse.ArgumentParser()
arg_parser.add_argument(
    "structured_attrs", help="Path to structured attrs file as exported by Nix __structuredAttrs"
)
arg_parser.add_argument("output_dir", help="Output directory")


def write_tree(output_dir: str, tree: dict) -> None:
    os.mkdir(output_dir)

    for name, node in tree.items():
        output_file = os.path.join(output_dir, name)

        if node["type"] == "derivation":
            shutil.copy(node["value"], output_file)
        elif node["type"] == "string":
            with open(output_file, "w") as f:
                f.write(node["value"])
        elif node["type"] == "set":
            write_tree(output_file, node["value"])
        else:
            raise ValueError(node["type"])


if __name__ == "__main__":
    args = arg_parser.parse_args()

    with open(args.structured_attrs) as f:
        attrs = json.load(f)

    write_tree(args.output_dir, attrs["tree"])
