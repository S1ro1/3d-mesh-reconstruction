from utils import parse_args, InputArguments, setup_logging
from pathlib import Path
from hloc import extract_features, match_features, pairs_from_exhaustive, reconstruction
import os
import shutil

L = setup_logging()


def visualize(model):
    from hloc.utils import viz_3d

    fig = viz_3d.init_figure()
    viz_3d.plot_reconstruction(
        fig, model, color="rgba(255,0,0,0.5)", name="mapping", points_rgb=True
    )
    fig.show()


def run_pipeline(config: InputArguments):
    image_dir = Path(config.image_dir)
    output_dir = Path(config.base_output_dir)

    model_dir = output_dir / "model"

    references = [p.relative_to(image_dir).as_posix() for p in image_dir.iterdir()]

    _sfm_dir = output_dir / "sfm"
    _sfm_pairs = _sfm_dir / "pairs.txt"

    if config.force_overwrite:
        shutil.rmtree(output_dir, ignore_errors=True)

    os.makedirs(_sfm_dir, exist_ok=True)

    # feature retrieval
    extract_features.main(config.retrieval_conf, image_dir, output_dir)

    if config.use_exhaustive:
        if len(references) > 16:
            L.warn(
                f"Using {len(references)} images with exhaustive matching might take a while"
            )

        pairs_from_exhaustive.main(_sfm_pairs, image_list=references)
    else:
        raise NotImplementedError("Other matching strategies are not implemented yet")

    features_path = extract_features.main(config.feature_conf, image_dir, output_dir)

    match_path = match_features.main(
        config.matcher_conf, _sfm_pairs, config.feature_conf["output"], output_dir
    )

    model = reconstruction.main(
        _sfm_dir,
        image_dir,
        _sfm_pairs,
        features_path,
        match_path,
        image_list=references,
    )

    os.makedirs(model_dir, exist_ok=True)

    model.write(model_dir)

    if config.visualize:
        visualize(model)


if __name__ == "__main__":
    config = parse_args()

    run_pipeline(config)
