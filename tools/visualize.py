import logging
from hashlib import sha1
from pathlib import Path

import geopandas as gpd
from matplotlib import pyplot as plt


logger = logging.getLogger(__name__)

for filename in Path("srcdata/shapes").glob("*.shp"):
    print(filename)
    df = gpd.read_file(filename, encoding="utf-8")

    column = df.name.apply(lambda n: sha1(str(n).encode("utf-8")).hexdigest())

    if "津波予報区" in filename.stem:
        df.plot(column, figsize=(20, 20), linewidth=3, cmap="hsv")
    else:
        df.plot(
            column,
            figsize=(20, 20),
            linewidth=0.3,
            edgecolor="black",
            cmap=plt.cm.get_cmap("hsv", len(df)),
        )

    plt.tight_layout()
    plt.axis("square")
    plt.xlim(122.5, 150)
    plt.ylim(22.5, 50)
    plt.grid()
    plt.savefig(Path("./visualized/").joinpath(filename.stem + ".png"))
