from argparse import ArgumentParser
from dataclasses import dataclass
from yaml import safe_load
import logging
import sys
from pprint import pformat

from hloc import (
    extract_features,
    match_features,
)


def setup_logging():
    logger = logging.getLogger("hloc-pipeline")
    logger.setLevel(logging.INFO)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)

    formatter = logging.Formatter("%(name)s - %(levelname)s - %(message)s")
    handler.setFormatter(formatter)

    logger.addHandler(handler)

    return logger


def prettify_dict(d: dict) -> str:
    return f"\n{pformat(d)}"


@dataclass
class InputArguments:
    image_dir: str
    # relative to this, all outputs are stored
    base_output_dir: str
    use_exhaustive: bool
    visualize: bool
    force_overwrite: bool

    retrieval_conf: dict
    feature_conf: dict
    matcher_conf: dict


_PIPELINE_CONFIG_MATCHER = {
    "retrieval_conf": extract_features.confs,
    "feature_conf": extract_features.confs,
    "matcher_conf": match_features.confs,
}


def parse_args() -> InputArguments:
    L = setup_logging()
    parser = ArgumentParser()
    parser.add_argument(
        "--config-file", type=str, required=True, help="Path to the configuration file"
    )

    args = parser.parse_args()

    with open(args.config_file, "r") as f:
        config = safe_load(f)

        for k, v in _PIPELINE_CONFIG_MATCHER.items():
            if isinstance(config[k], str):
                config[k] = v[config[k]]

        L.info(prettify_dict(config))
        return InputArguments(**config)
