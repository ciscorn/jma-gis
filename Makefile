.PHONY: help xyztiles

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


XYZTILE_VERSION = v0.1
S3_BASE = s3://YOUR-BUCKET-NAME/jma-gis
LAYERS = chihou city eew_chihou eew_fuken fuken ichiji matome sea seis_prefecture seis_saibun tsunami
CITY_VARIANTS = 市町村等（気象警報等） 市町村等（大雨危険度） 市町村等（土砂災害警戒情報） 市町村等（指定河川洪水予報） 市町村等（地震津波関係） 市町村等（火山関係）
SHP_BASE = srcdata/shapes


PROPS_BASE = output/shape_properties
GEOJSON_BASE = output/geojson
XYZ_BASE = output/xyz
PROPS_FILES = $(addprefix ${PROPS_BASE}/, $(addsuffix .json, $(LAYERS)))
GEOJSON_FILES = $(addprefix ${GEOJSON_BASE}/, $(addsuffix .json, $(LAYERS)))


xyztiles: ${GEOJSON_FILES} ## ベクタータイル (XYZ) を生成する
	tippecanoe -z12 --simplification=2 --detect-shared-borders --no-tile-compression -f -P -e ${XYZ_BASE} $^

geojson: ${GEOJSON_FILES} ## GeoJSON を生成する

shape_properties: ${PROPS_FILES} ## 各シェイプの面積などを計算する

update_es_index:  ## Elasticsearch のインデクスを作り直す
	python3 tools/es/make_shape_index.py

upload-to-s3: ${XYZ_BASE}/metadata.json ## Amazon S3 にアップロードする
	aws s3 sync ${XYZ_BASE} ${S3_BASE}/$(XYZTILE_VERSION)/ --include "*" --cache-control "max-age=3600"

# シェイプファイル (.shp) から面積などの属性値を抽出する
${PROPS_BASE}/chihou.json: ${SHP_BASE}/全国・地方予報区等.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/city.json: $(addprefix ${SHP_BASE}/, $(addsuffix .shp, $(CITY_VARIANTS))) # 市町村等（＊＊＊）は1つにまとめる
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $^ > $@
${PROPS_BASE}/eew_chihou.json: ${SHP_BASE}/緊急地震速報／地方予報区.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/eew_fuken.json: ${SHP_BASE}/緊急地震速報／府県予報区.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/fuken.json: ${SHP_BASE}/府県予報区等.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/ichiji.json: ${SHP_BASE}/一次細分区域等.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/matome.json: ${SHP_BASE}/市町村等をまとめた地域等.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/sea.json: ${SHP_BASE}/地方海上予報区.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/seis_saibun.json: ${SHP_BASE}/地震情報／細分区域.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/seis_prefecture.json: ${SHP_BASE}/地震情報／都道府県等.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@
${PROPS_BASE}/tsunami.json: ${SHP_BASE}/津波予報区.shp
	mkdir -p ${PROPS_BASE} && python3 tools/calc_shape_props.py $< > $@

# シェイプファイル (.shp) を GeoJSON に変換する
${GEOJSON_BASE}/chihou.json: ${SHP_BASE}/全国・地方予報区等.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/city.json: $(addprefix ${SHP_BASE}/, $(addsuffix .shp, $(CITY_VARIANTS))) # 市町村等（＊＊＊）は1つにまとめる
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $^ > $@
${GEOJSON_BASE}/eew_chihou.json: ${SHP_BASE}/緊急地震速報／地方予報区.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/eew_fuken.json: ${SHP_BASE}/緊急地震速報／府県予報区.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/fuken.json: ${SHP_BASE}/府県予報区等.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/ichiji.json: ${SHP_BASE}/一次細分区域等.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/matome.json: ${SHP_BASE}/市町村等をまとめた地域等.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/sea.json: ${SHP_BASE}/地方海上予報区.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/seis_saibun.json: ${SHP_BASE}/地震情報／細分区域.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/seis_prefecture.json: ${SHP_BASE}/地震情報／都道府県等.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
${GEOJSON_BASE}/tsunami.json: ${SHP_BASE}/津波予報区.shp
	mkdir -p ${GEOJSON_BASE} && python3 tools/shape_to_geojson.py $< > $@
