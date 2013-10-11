AC_INIT([quick-photo-editor],
        [0.1],
        [https://github.com/canek-pelaez/quick-photo-editor/issues],
        [quick-photo-editor],
        [https://github.com/canek-pelaez/quick-photo-editor])
AC_CONFIG_SRCDIR([src/quick-photo-editor.vala])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([1.11 no-dist-gzip dist-xz])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_STDC
AM_PROG_VALAC([0.18])
AC_PROG_INSTALL

QUICKPHOTOEDITOR_PACKAGES="--pkg gtk+-3.0 --pkg gee-0.8 --pkg gexiv2"
PKG_CHECK_MODULES(QUICKPHOTOEDITOR, [ gtk+-3.0 gee-0.8 gexiv2 ])

AC_SUBST(QUICKPHOTOEDITOR_CFLAGS)
AC_SUBST(QUICKPHOTOEDITOR_LIBS)
AC_SUBST(QUICKPHOTOEDITOR_PACKAGES)

IT_PROG_INTLTOOL([0.40])

GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])

AC_CONFIG_FILES([
	Makefile
        po/Makefile.in
])

AC_OUTPUT
