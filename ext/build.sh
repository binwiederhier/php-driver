#!/bin/bash -ex

basedir=$(cd $(dirname $0); pwd)/..
builddir=$basedir/build

echo "Checking dependencies ..."
test -d $basedir/lib/cpp-driver || \
  { echo "Cannot find $basedir/lib/cpp-driver. Run 'git submodule update --init' and retry."; exit 1; }

echo "Preparing build directory ..."
rm -rf $builddir
mkdir -p $builddir/php-driver
mkdir -p $builddir/out/lib
mkdir -p $builddir/out/include
cp -a $basedir/lib/cpp-driver $builddir/cpp-driver
cp -a $basedir/{ext,features,lib} $builddir/php-driver
echo extension=cassandra.so > build/cassandra.ini

echo "Compiling cpp-driver..."
cd $builddir/cpp-driver
cmake -DCMAKE_CXX_FLAGS="-fPIC" -DCMAKE_INSTALL_PREFIX:PATH=$builddir -DCASS_BUILD_STATIC=ON \
  -DCASS_BUILD_SHARED=OFF -DCMAKE_BUILD_TYPE=RELEASE -DCASS_USE_ZLIB=ON \
  -DCMAKE_INSTALL_LIBDIR:PATH=lib $builddir/php-driver/lib/cpp-driver/
make

echo "PHP-izing extension ..."
cd $builddir/php-driver/ext
phpize

echo "Compiling extension ..."
cp -a $builddir/cpp-driver/libcassandra_static.a $builddir/out/lib/libcassandra.a
cp $builddir/php-driver/lib/cpp-driver/include/cassandra.h $builddir/out/include 
cd $builddir/php-driver/ext
LIBS="-lssl -lz -luv -lm -lstdc++" LDFLAGS="-L$builddir/out/lib" \
  ./configure --with-cassandra=$builddir/out --with-libdir=lib
make

