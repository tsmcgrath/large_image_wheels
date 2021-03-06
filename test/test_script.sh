#!/usr/bin/env bash
set -e

python --version
pip install --upgrade pip 
pip install --upgrade setuptools
# which pip2 && pip2 install virtualenv==20.0.5 || true
# echo 'Test installing all libraries from wheels'
# pip install libtiff openslide_python pyvips GDAL mapnik -f /wheels
echo 'Test installing pyvips and other dependencies from wheels via large_image'
pip install --pre pyvips large_image[sources,memcached] -f ${1:-/wheels}
echo 'Test basic import of libtiff'
python -c 'import libtiff'
echo 'Test basic import of openslide'
python -c 'import openslide'
echo 'Test basic import of pyvips'
python -c 'import pyvips'
echo 'Test basic import of gdal'
python -c 'import gdal'
echo 'Test basic import of mapnik'
python -c 'import mapnik'
echo 'Test basic imports of all wheels'
python -c 'import libtiff, openslide, pyvips, gdal, mapnik, glymur'
echo 'Test import of pyproj after mapnik'
python <<EOF
import mapnik
import pyproj
print(pyproj.Proj('+init=epsg:4326 +type=crs'))
EOF
echo 'Download an openslide file'
curl --retry 5 -L -o sample.svs https://data.kitware.com/api/v1/file/5be43d9c8d777f217991e1c2/download
echo 'Use large_image to read an openslide file'
python <<EOF
import large_image, pprint
ts = large_image.getTileSource('sample.svs')
pprint.pprint(ts.getMetadata())
ti = ts.getSingleTile(tile_size=dict(width=1000, height=1000),
                      scale=dict(magnification=20), tile_position=1000)
pprint.pprint(ti)
print(ti['tile'].size)
print(ti['tile'][:4,:4])
EOF
echo 'Download a tiff file'
curl --retry 5 -L -o sample.tif https://data.kitware.com/api/v1/file/5be43e398d777f217991e21f/download
echo 'Use large_image to read a tiff file'
python <<EOF
import large_image, pprint
ts = large_image.getTileSource('sample.tif')
pprint.pprint(ts.getMetadata())
ti = ts.getSingleTile(tile_size=dict(width=1000, height=1000),
                      scale=dict(magnification=20), tile_position=100)
pprint.pprint(ti)
print(ti['tile'].size)
print(ti['tile'][:4,:4])
EOF
echo 'Download a tiff file that requires a newer openjpeg'
curl --retry 5 -L -o sample_jp2.tif https://data.kitware.com/api/v1/file/5be348568d777f21798fa1d1/download
echo 'Use large_image to read a tiff file that requires a newer openjpeg'
python <<EOF
import pyvips
pyvips.Image.new_from_file('sample_jp2.tif').write_to_file(
  'sample_jp2_out.tif', compression='jpeg', Q=90, tile=True, 
  tile_width=256, tile_height=256, pyramid=True, bigtiff=True)
import large_image, pprint
ts = large_image.getTileSource('sample_jp2_out.tif')
pprint.pprint(ts.getMetadata())
ti = ts.getSingleTile(tile_size=dict(width=1000, height=1000), tile_position=100)
pprint.pprint(ti)
print(ti['tile'].size)
print(ti['tile'][:4,:4])
EOF
echo 'Download a geotiff file'
curl --retry 5 -L -o landcover.tif https://data.kitware.com/api/v1/file/5be43e848d777f217991e270/download
echo 'Use gdal to open a geotiff file'
python <<EOF
import gdal, pprint
d = gdal.Open('landcover.tif')
pprint.pprint({
  'RasterXSize': d.RasterXSize,
  'RasterYSize': d.RasterYSize,
  'GetProjection': d.GetProjection(),
  'GetGeoTransform': d.GetGeoTransform(),
  'RasterCount': d.RasterCount,
  'band.GetStatistics': d.GetRasterBand(1).GetStatistics(True, True),
  'band.GetNoDataValue': d.GetRasterBand(1).GetNoDataValue(),
  'band.GetScale': d.GetRasterBand(1).GetScale(),
  'band.GetOffset': d.GetRasterBand(1).GetOffset(),
  'band.GetUnitType': d.GetRasterBand(1).GetUnitType(),
  'band.GetCategoryNames': d.GetRasterBand(1).GetCategoryNames(),
  'band.GetColorInterpretation': d.GetRasterBand(1).GetColorInterpretation(),
  'band.GetColorTable().GetCount': d.GetRasterBand(1).GetColorTable().GetCount(),
  'band.GetColorTable().GetColorEntry(0)': d.GetRasterBand(1).GetColorTable().GetColorEntry(0),
  'band.GetColorTable().GetColorEntry(1)': d.GetRasterBand(1).GetColorTable().GetColorEntry(1),
})
EOF
echo 'Use large_image to read a geotiff file'
python <<EOF
import large_image, pprint
ts = large_image.getTileSource('landcover.tif')
pprint.pprint(ts.getMetadata())
ti = ts.getSingleTile(tile_size=dict(width=1000, height=1000), tile_position=200)
pprint.pprint(ti)
print(ti['tile'].size)
print(ti['tile'][:4,:4])
EOF
echo 'Use large_image to read a geotiff file with a projection'
python <<EOF
import large_image, pprint
ts = large_image.getTileSource('landcover.tif', projection='EPSG:3857')
pprint.pprint(ts.getMetadata())
ti = ts.getSingleTile(tile_size=dict(width=1000, height=1000), tile_position=100)
pprint.pprint(ti)
print(ti['tile'].size)
print(ti['tile'][:4,:4])
tile = ts.getTile(1178, 1507, 12)
pprint.pprint(repr(tile[1400:1440]))
EOF
echo 'Test that pyvips and openslide can both be imported, pyvips first'
python <<EOF
import pyvips, openslide
pyvips.Image.new_from_file('sample_jp2.tif').write_to_file(
  'sample_jp2_out.tif', compression='jpeg', Q=90, tile=True,
  tile_width=256, tile_height=256, pyramid=True, bigtiff=True)
EOF
echo 'Test that pyvips and openslide can both be imported, openslide first'
python <<EOF
import openslide, pyvips
pyvips.Image.new_from_file('sample_jp2.tif').write_to_file(
  'sample_jp2_out.tif', compression='jpeg', Q=90, tile=True,
  tile_width=256, tile_height=256, pyramid=True, bigtiff=True)
EOF
echo 'Test that pyvips and mapnik can both be imported, pyvips first'
python <<EOF
import pyvips, mapnik
pyvips.Image.new_from_file('sample_jp2.tif').write_to_file(
  'sample_jp2_out.tif', compression='jpeg', Q=90, tile=True,
  tile_width=256, tile_height=256, pyramid=True, bigtiff=True)
EOF
echo 'Test that pyvips and mapnik can both be imported, mapnik first'
python <<EOF
import mapnik, pyvips
pyvips.Image.new_from_file('sample_jp2.tif').write_to_file(
  'sample_jp2_out.tif', compression='jpeg', Q=90, tile=True,
  tile_width=256, tile_height=256, pyramid=True, bigtiff=True)
EOF
echo 'Download a somewhat bad nitf file'
curl --retry 5 -L -o sample.ntf https://data.kitware.com/api/v1/file/5cee913e8d777f072bf1c47a/download
echo 'Use gdal to open a nitf file'
python <<EOF
import gdal, pprint
d = gdal.Open('sample.ntf')
pprint.pprint({
  'RasterXSize': d.RasterXSize,
  'RasterYSize': d.RasterYSize,
  'GetProjection': d.GetProjection(),
  'GetGeoTransform': d.GetGeoTransform(),
  'RasterCount': d.RasterCount,
  })
pprint.pprint(d.GetMetadata()['NITF_BLOCKA_FRFC_LOC_01'])
EOF
echo 'Test import order with shapely'
if pip install shapely; then (
python -c 'import shapely;import mapnik;import pyproj;print(pyproj.Proj("+init=epsg:4326 +type=crs"))'
python -c 'import pyproj;import shapely;import mapnik;print(pyproj.Proj("+init=epsg:4326 +type=crs"))'
python -c 'import mapnik;import pyproj;import shapely;print(pyproj.Proj("+init=epsg:4326 +type=crs"))'
python -c 'import shapely;import pyproj;import mapnik;print(pyproj.Proj("+init=epsg:4326 +type=crs"))'
python -c 'import mapnik;import shapely;import pyproj;print(pyproj.Proj("+init=epsg:4326 +type=crs"))'
python -c 'import pyproj;import mapnik;import shapely;print(pyproj.Proj("+init=epsg:4326 +type=crs"))'
); else echo 'no shapely available'; fi
echo 'Test running executables'
`python -c 'import os,sys,libtiff;sys.stdout.write(os.path.dirname(libtiff.__file__))'`/bin/tiffinfo landcover.tif
tiffinfo landcover.tif
`python -c 'import os,sys,glymur;sys.stdout.write(os.path.dirname(glymur.__file__))'`/bin/opj_dump -h | grep -q 'opj_dump utility from the OpenJPEG project'
opj_dump -h | grep -q 'opj_dump utility from the OpenJPEG project'
`python -c 'import os,sys,openslide;sys.stdout.write(os.path.dirname(openslide.__file__))'`/bin/openslide-show-properties --version
openslide-show-properties --version
`python -c 'import os,sys,osgeo;sys.stdout.write(os.path.dirname(osgeo.__file__))'`/bin/gdalinfo --version
gdalinfo --version
`python -c 'import os,sys,mapnik;sys.stdout.write(os.path.dirname(mapnik.__file__))'`/bin/mapnik-render --version 2>&1 | grep version
mapnik-render --version 2>&1 | grep version
`python -c 'import os,sys,pyvips;sys.stdout.write(os.path.dirname(pyvips.__file__))'`/bin/vips --version
vips --version
PROJ_LIB=`python -c 'import os,sys,pyproj;sys.stdout.write(os.path.dirname(pyproj.__file__))'`/proj `python -c 'import os,sys,pyproj;sys.stdout.write(os.path.dirname(pyproj.__file__))'`/bin/projinfo EPSG:4326
projinfo EPSG:4326

