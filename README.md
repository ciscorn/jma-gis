# jma-gis

気象庁の[予報区等GISデータ](https://www.data.jma.go.jp/developer/gis.html)をもとに、ベクタータイルなどのデータを生成します。

具体的には以下を行えます:

- ベクタータイルの生成
- 各シェイプの属性値（bbox等）の抽出
- Elasticsearch へのシェイプデータの挿入

## Development

- シェイプファイル (.shp) などの巨大なファイルは Git LFS で管理しています (管理対象は `.gitattributes` を参照)
- 参考のために、[`./visualized/`](./visualized/) に各シェイプファイルを可視化した画像を配置しています。
- 処理の流れは Makefile（と必要に応じて docker-compose.yml) を参照。

## ベクタータイルについて

### 仕様

生成されるベクタータイルには、元の各シェイプファイルが全て含まれており、それぞれ以下のレイヤ名で格納されています。

| 元のシェイプファイル | レイヤ名 |
| -- | -- |
| 全国・地方予報区等.shp | chihou |
| 府県予報区等.shp | fuken |
| 一次細分区域等.shp | ichiji |
| 市町村等をまとめた地域等.shp | matome |
| 市町村等（＊＊＊）.shp | city |
| 緊急地震速報／地方予報区.shp | eew_chihou |
| 緊急地震速報／府県予報区.shp | eew_fuken |
| 地震情報／細分区域.shp | seis_saibun |
| 地震情報／都道府県等.shp | seis_prefecture |
| 津波予報区.shp | tsunami |
| 地方海上予報区.shp | sea |

各 Feature は `name` (区域名) と `code` (区域コード) の属性 (attributes) を持ちます。

各シェイプファイルの領域区分の様子は [`./visualized/`](./visualized/) ディレクトリなどを参考にしてください。

### タイルの生成

#### Docker Compose 上で実行する方法

```bash
docker compose run xyztiles
```

プロセスが OOM で Kill される場合は、Docker 環境へのメモリ割り当てを増やしてください。

#### 直接実行する方法（高速）

お使いの環境に geopandas と tippecanoe がインストールされていれば、直接 Makefile を実行することもできます。

```bash
make xyztiles -j 8
```


## シェイプの属性値の抽出について

シェイプファイルから、各ジオメトリの重心や面積などの情報を抽出します。

```console
make shape_properties
```

`output/shape_propertes/*.json` に、JSONファイルとして出力されます

以下の情報を抽出します。

- 名称 (`name`) とコード (`code`)
- 面積 (`area`)
- 重心 (`centroid`)
- バウンディングボックス (`bbox`)
- 長さ (length) - 津波予報区のみ

これらの値はあくまでも WGS84 空間上での値です。

## Elasticsearch インデックスについて

Elasticsearch のインデクスにシェイプデータをインデクスすることができます。インデクスに際して一定のベクトル単純化を行います。

下記のコマンドでインデクスしなおすことができます（エイリアスの張り替えまで自動で行われます）。

```console
make update_es_index
```

インデクスの内容は以下の通りです:

```python
    "properties": {
        "kind": {"type": "keyword"},  # 種類 (e.g. 一次細分区域等)
        "name": {"type": "keyword"},  # 名前 (e.g. 秩父地方)
        "code": {"type": "keyword"},  # コード
        "geometry": {"type": "geo_shape"},  # シェイプデータ
    }
```
