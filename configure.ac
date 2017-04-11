# This file is part of gqpe.

# Copyright © 2013-2017 Canek Peláez Valdés

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.

# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

# Autoconf initial setup
AC_INIT([gqpe], [0.1],
        [https://github.com/canek-pelaez/gqpe/issues],
        [gqpe], [https://github.com/canek-pelaez/gqpe])

# Autoconf general configuration
AC_CONFIG_SRCDIR([src/application-main.vala])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_AUX_DIR([build-aux])

# Automake initial setup
AM_INIT_AUTOMAKE([1.11 foreign no-dist-gzip dist-xz])
AM_SILENT_RULES([yes])

# C and Vala compilers requirements
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_STDC
AM_PROG_VALAC([0.24])
AC_PROG_INSTALL

# Optional Valadoc
AC_PATH_PROG([VALADOC], [valadoc])
AM_CONDITIONAL([HAVE_VALADOC], [test "${VALADOC}" != ""])

AC_ARG_ENABLE([valadoc],
    AS_HELP_STRING([--enable-valadoc],
        [enable valadoc generation (default=yes if available)]),
    [enable_valadoc=yes], [enable_valadoc=no])
AS_IF([test "${enable_valadoc}" = "yes" && test "${VALADOC}" = ""],
    [AC_MSG_ERROR([valadoc is not available])])

# For resources
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

# Champlain
CHAMPLAIN_PACKAGES="--pkg champlain-0.12"
PKG_CHECK_MODULES(CHAMPLAIN, [ champlain-0.12 ])

AC_SUBST(CHAMPLAIN_CFLAGS)
AC_SUBST(CHAMPLAIN_LIBS)
AC_SUBST(CHAMPLAIN_PACKAGES)

# Clutter Gtk
CLUTTER_GTK_PACKAGES="--pkg clutter-gtk-1.0"
PKG_CHECK_MODULES(CLUTTER_GTK, [  clutter-gtk-1.0 ])

AC_SUBST(CLUTTER_GTK_CFLAGS)
AC_SUBST(CLUTTER_GTK_LIBS)
AC_SUBST(CLUTTER_GTK_PACKAGES)

# Gexiv2
GEXIV2_PACKAGES="--pkg gexiv2"
PKG_CHECK_MODULES(GEXIV2, [  gexiv2 ])

AC_SUBST(GEXIV2_CFLAGS)
AC_SUBST(GEXIV2_LIBS)
AC_SUBST(GEXIV2_PACKAGES)

# Gtk+ 3
GTK_PACKAGES="--pkg gtk+-3.0"
PKG_CHECK_MODULES(GTK, [ gtk+-3.0 ])

AC_SUBST(GTK_CFLAGS)
AC_SUBST(GTK_LIBS)
AC_SUBST(GTK_PACKAGES)

# Gee 0.8
GEE_PACKAGES="--pkg gee-0.8"
PKG_CHECK_MODULES(GEE, [ gee-0.8 ])

AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)
AC_SUBST(GEE_PACKAGES)

# Gettext
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.19.7])
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The name of the gettext domain])

# Output files
AC_CONFIG_FILES([
	Makefile
        po/Makefile.in
])
AC_OUTPUT
