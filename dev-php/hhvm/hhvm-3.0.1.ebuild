# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils git-2 user

EGIT_REPO_URI="https://github.com/facebook/hhvm.git"
EGIT_COMMIT="HHVM-${PV}"

IUSE="debug hack xen zend-compat"

DESCRIPTION="Virtual Machine, Runtime, and JIT for PHP"
HOMEPAGE="https://github.com/facebook/hhvm"

RDEPEND="
	app-arch/bzip2
	dev-cpp/glog
	dev-cpp/tbb
	hack? ( >=dev-lang/ocaml-3.12[ocamlopt] )
	>=dev-libs/boost-1.49
	dev-libs/cloog
	dev-libs/elfutils
	dev-libs/expat
	dev-libs/icu
	>=dev-libs/jemalloc-3.0.0[stats]
	dev-libs/libdwarf
	>=dev-libs/libevent-2.0.9
	dev-libs/libmcrypt
	dev-libs/libmemcached
	dev-libs/libpcre
	dev-libs/libxml2
	dev-libs/libxslt
	dev-libs/oniguruma
	dev-libs/openssl
	media-gfx/imagemagick
	media-libs/freetype
	media-libs/gd[jpeg,png]
	net-libs/c-client[kerberos]
	>=net-misc/curl-7.28.0
	net-nds/openldap
	>=sys-devel/gcc-4.7
	sys-libs/libcap
	sys-libs/ncurses
	sys-libs/readline
	sys-libs/zlib
	virtual/mysql
"

DEPEND="
	${RDEPEND}
	>=dev-util/cmake-2.8.7
	sys-devel/binutils
	sys-devel/bison
	sys-devel/flex
"

SLOT="0"
LICENSE="PHP-3"
KEYWORDS="amd64"

pkg_setup() {
	ebegin "Creating hhvm user and group"
	enewgroup hhvm
	enewuser hhvm -1 -1 "/var/lib/hhvm" hhvm
	eend $?
}

src_prepare()
{
	git submodule update --init
}

src_configure()
{
	CMAKE_BUILD_TYPE="Release"
	if use debug; then
		CMAKE_BUILD_TYPE="Debug"
	fi

	if use xen; then
		HHVM_OPTS="${HHVM_OPTS} -DDISABLE_HARDWARE_COUNTERS=ON"
	fi

	if use zend-compat; then
		HHVM_OPTS="${HHVM_OPTS} -DENABLE_ZEND_COMPAT=ON"
	fi

	econf -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" ${HHVM_OPTS}
}

src_install()
{
	dobin hphp/hhvm/hhvm

	if use hack; then
		dobin hphp/hack/bin/hh_client
		dobin hphp/hack/bin/hh_server
		dobin hphp/hack/bin/hh_single_type_check
		dodir "/usr/share/hhvm/hack"
		cp -a "${S}/hphp/hack/hhi" "${D}/usr/share/hhvm/hack/"
		cp -a "${S}/hphp/hack/editor-plugins/emacs" "${D}/usr/share/hhvm/hack/"
		cp -a "${S}/hphp/hack/editor-plugins/vim" "${D}/usr/share/hhvm/hack/"
	fi

	newinitd "${FILESDIR}"/hhvm.initd-r3 hhvm
	newconfd "${FILESDIR}"/hhvm.confd-r3 hhvm
	dodir "/etc/hhvm"
	insinto /etc/hhvm
	newins "${FILESDIR}"/config.hdf.dist-r3 config.hdf.dist
}
