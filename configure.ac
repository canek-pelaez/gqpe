AC_INIT([gqpe], [0.1],
        [https://github.com/canek-pelaez/gqpe/issues],
        [gqpe], [https://github.com/canek-pelaez/gqpe])
AC_CONFIG_SRCDIR([src/main.vala])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([1.11 foreign no-dist-gzip dist-xz])
AM_SILENT_RULES([yes])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_STDC
AM_PROG_VALAC([0.24])
AC_PROG_INSTALL

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

GEE_PACKAGES="--pkg gee-0.8"
PKG_CHECK_MODULES(GEE, [ gee-0.8 ])

AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)
AC_SUBST(GEE_PACKAGES)

GEXIV2_PACKAGES="--pkg gexiv2"
PKG_CHECK_MODULES(GEXIV2, [  gexiv2 ])

AC_SUBST(GEXIV2_CFLAGS)
AC_SUBST(GEXIV2_LIBS)
AC_SUBST(GEXIV2_PACKAGES)

GTK_PACKAGES="--pkg gtk+-3.0"
PKG_CHECK_MODULES(GTK, [ gtk+-3.0 ])

AC_SUBST(GTK_CFLAGS)
AC_SUBST(GTK_LIBS)
AC_SUBST(GTK_PACKAGES)

IT_PROG_INTLTOOL([0.40])

GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,
                   "$GETTEXT_PACKAGE",
                   [The name of the gettext domain])

AC_CONFIG_FILES([
	Makefile
        po/Makefile.in
])

AC_OUTPUT
