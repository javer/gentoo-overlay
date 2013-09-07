# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit eutils git-2

EGIT_REPO_URI="https://github.com/facebook/hiphop-php.git"
EGIT_BRANCH="master"

IUSE="+jemalloc devel debug"

CURL_P="curl-7.31.0"
LIBEVENT_P="libevent-1.4.14b-stable"
JEMALLOC_P="jemalloc-3.0.0"
GOOGLE_GLOG_P="google-glog"

SRC_URI="http://curl.haxx.se/download/${CURL_P}.tar.bz2
         https://github.com/downloads/libevent/libevent/${LIBEVENT_P}.tar.gz
         jemalloc? ( http://www.canonware.com/download/jemalloc/${JEMALLOC_P}.tar.bz2 )"

DESCRIPTION="Virtual Machine, Runtime, and JIT for PHP"
HOMEPAGE="https://github.com/facebook/hiphop-php"

RDEPEND="
	>=dev-libs/boost-1.37
	sys-devel/flex
	sys-devel/bison
	dev-util/re2c
	dev-db/mysql
	dev-libs/libxml2
	dev-libs/libmcrypt
	dev-libs/icu
	dev-libs/openssl
	sys-libs/libcap
	media-libs/gd
	sys-libs/zlib
	dev-cpp/tbb
	dev-libs/oniguruma
	dev-libs/libpcre
	dev-libs/expat
	sys-libs/readline
	sys-libs/ncurses
	dev-libs/libmemcached
	net-nds/openldap
	net-libs/c-client
	dev-util/google-perftools
	dev-libs/cloog
	dev-libs/elfutils
	dev-libs/libdwarf
	sys-libs/libunwind
"

DEPEND="
	${RDEPEND}
	dev-util/cmake
"

SLOT="0"
LICENSE="PHP-3"
KEYWORDS="~amd64"

src_prepare()
{
	git submodule init
	git submodule update

	epatch "${FILESDIR}/support-curl-7.31.0.patch"

	export CMAKE_PREFIX_PATH="${D}/usr/lib/hiphop-php"

	einfo "Building custom libevent"
	export EPATCH_SOURCE="${S}/hphp/third_party"
	EPATCH_OPTS="-d ""${WORKDIR}/${LIBEVENT_P}" epatch libevent-1.4.14.fb-changes.diff
	pushd "${WORKDIR}/${LIBEVENT_P}" > /dev/null
	./autogen.sh
	./configure --prefix="${CMAKE_PREFIX_PATH}"
	emake
	emake -j1 install
	popd > /dev/null

	einfo "Building custom curl"
	EPATCH_OPTS="-d ""${WORKDIR}/${CURL_P} -p1" epatch libcurl.fb-changes.diff
	pushd "${WORKDIR}/${CURL_P}" > /dev/null
	./buildconf
	./configure --prefix="${CMAKE_PREFIX_PATH}"
	emake
	emake -j1 install
	popd > /dev/null

	einfo "Building Google glog"
	pushd "${WORKDIR}" > /dev/null
	svn checkout http://google-glog.googlecode.com/svn/trunk/ ${GOOGLE_GLOG_P}
	cd ${GOOGLE_GLOG_P}
	./configure --prefix="${CMAKE_PREFIX_PATH}"
	emake
	emake -j1 install
	popd > /dev/null

	if use jemalloc;
	then
		einfo "Building jemalloc"
		pushd "${WORKDIR}/${JEMALLOC_P}" > /dev/null
		./configure --prefix="${CMAKE_PREFIX_PATH}"
		emake
		emake -j1 install
		popd > /dev/null
	fi

	if use debug;
	then
		einfo "Configuring DEBUG build"
		sed -i -E 's/^#(.*CMAKE_BUILD_TYPE.*Debug.*)$/\1/' "${S}/CMake/Options.cmake"
	fi
}

src_configure()
{
	export HPHP_HOME="${S}"
	econf
}

src_install()
{
	pushd "${WORKDIR}/${LIBEVENT_P}" > /dev/null
	emake -j1 install
	popd > /dev/null

	pushd "${WORKDIR}/${CURL_P}" > /dev/null
	emake -j1 install
	popd > /dev/null

	pushd "${WORKDIR}/${JEMALLOC_P}" > /dev/null
	emake -j1 install
	popd > /dev/null

	pushd "${WORKDIR}/${GOOGLE_GLOG_P}" > /dev/null
	emake -j1 install
	popd > /dev/null

	rm -rf "${D}/usr/lib/hiphop-php/"{bin,include,share}
	rm -rf "${D}/usr/lib/hiphop-php/lib/pkgconfig"
	rm -f "${D}/usr/lib/hiphop-php/lib/"*.{a,la}

	exeinto "/usr/lib/hiphop-php/bin"
	doexe hphp/hhvm/hhvm
	dodir "/usr/share/hiphop-php"
	insinto "/usr/share/hiphop-php"
	cp -a "${S}/"{bin,CMake} "${D}/usr/share/hiphop-php/"
	doins "LICENSE.PHP"
	doins "LICENSE.ZEND"
	dodir "/usr/share/hiphop-php/hphp"
	insinto "/usr/share/hiphop-php/hphp"
	cp -a "${S}/hphp/"{doc,runtime,system,third_party,util,zend} "${D}/usr/share/hiphop-php/hphp"

	if use devel;
	then
		cp -a "${S}/hphp/test" "${D}/usr/lib/hiphop-php/"
	fi

	dobin "${FILESDIR}/hphp"
	newinitd "${FILESDIR}"/hphp.rc hphp
	dodir "/etc/hiphop"
	insinto /etc/hiphop
	newins "${FILESDIR}"/config.hdf.dist config.hdf.dist
}
