#!/bin/bash -x

set -e

echo "version ${1}"
echo "build ${2}"

BUILD_VERSION=${1}
BUILD_NUMBER=${2}


GPDB_PACKAGE_NAME=apache-greenplum-db-${BUILD_VERSION}-${BUILD_NUMBER}-x86_64
GPDB_VERSION_NAME=apache-greenplum-db-${BUILD_VERSION}-${BUILD_NUMBER}
GPDB_VERSION_PATH=/usr/local/${GPDB_VERSION_NAME}
GPDB_PATH=/usr/local/apache-greenplum-db

# Setup GPDB location
cp -r /usr/local/GP-${BUILD_VERSION} ${GPDB_VERSION_PATH}
ln -sf ${GPDB_VERSION_PATH} ${GPDB_PATH}

pushd ${GPDB_VERSION_PATH}
sed "s#GP-${BUILD_VERSION}#${GPDB_VERSION_NAME}#g" greenplum_path.sh > greenplum_path.sh.updated
mv greenplum_path.sh.updated greenplum_path.sh
sed "s#/greenplum-db/#/apache-greenplum-db/#g" greenplum_path.sh > greenplum_path.sh.updated
mv greenplum_path.sh.updated greenplum_path.sh
if [ "$WITH_MINICONDA" = "true" ]; then
  sed "s#ext/python#ext/conda2#g" greenplum_path.sh > greenplum_path.sh.updated
  mv greenplum_path.sh.updated greenplum_path.sh
fi
chmod oug+x greenplum_path.sh
popd

#Package results in tarball
tar -czhvf /usr/local/${GPDB_PACKAGE_NAME}.tar.gz -C /usr/local ${GPDB_VERSION_NAME}

# Build additional directories we may need
for dir in BUILD RPMS SOURCES SPECS SRPMS
do
  [[ -d $dir ]] && rm -Rf $dir
  mkdir $dir
done

#Build RPM
cp gpdb.spec SPECS/gpdb.spec
cp /usr/local/${GPDB_PACKAGE_NAME}.tar.gz ./SOURCES/
rpmbuild --define "gpdb_ver ${BUILD_VERSION}" --define "gpdb_rel ${BUILD_NUMBER}" --define "_topdir "`pwd` -ba SPECS/gpdb.spec
