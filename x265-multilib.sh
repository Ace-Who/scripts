#!/bin/sh

srcdir="source"

echo "MAKEFLAGS: ${MAKEFLAGS}"
echo "CMAKEFLAGS: ${CMAKEFLAGS}"

rm -rf 8bit 10bit 12bit
mkdir -p 8bit 10bit 12bit

echo ""
echo "### 12 bit ###"
cd 12bit
cmake ${srcdir} ${CMAKEFLAGS} -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON
make ${MAKEFLAGS}

echo ""
echo "### 10 bit ###"
cd ../10bit
cmake ${srcdir} ${CMAKEFLAGS} -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
make ${MAKEFLAGS}

echo ""
echo "### 8 bit ###"
cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
cmake ${srcdir} ${CMAKEFLAGS} -DEXTRA_LIB="x265_main10.a;x265_main12.a;-ldl" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON
make ${MAKEFLAGS}

# rename the 8bit library, then combine all three into libx265.a
mv libx265.a libx265_main.a

uname=`uname`
if [ "$uname" = "Linux" ]
then

# On Linux, we use GNU ar to combine the static libraries together
ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF

else

# Mac/BSD libtool
libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a 2>/dev/null

fi
