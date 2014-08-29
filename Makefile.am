AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = src/gqpe

src_gqpe_SOURCES =				\
	src/quick-photo-editor.vala		\
	src/photograph-image.vala		\
	$(NULL)

AM_CPPFLAGS =					\
	-include config.h			\
	-DLOCALEDIR=\""$(localedir)"\"		\
	-DPKGDATADIR=\""$(pkgdatadir)"\"	\
	-DPKGLIBDIR=\""$(pkglibdir)"\"		\
	$(NULL)

src_gqpe_VALAFLAGS =				\
	--target-glib=2.38			\
	--vapidir=$(srcdir)/vapi		\
	 --pkg config				\
	@GEE_PACKAGES@				\
	@GEXIV2_PACKAGES@			\
	@GTK_PACKAGES@				\
	$(NULL)

src_gqpe_CFLAGS =				\
	@GEE_CFLAGS@				\
	@GEXIV2_CFLAGS@				\
	@GTK_CFLAGS@				\
	-w					\
	$(NULL)

src_gqpe_LDADD =				\
	@GEE_LIBS@				\
	@GEXIV2_LIBS@				\
	@GTK_LIBS@				\
	$(NULL)

uidir = $(pkgdatadir)
ui_DATA = data/quick-photo-editor.ui

icondir = $(datadir)/icons/hicolor/scalable/apps
icon_DATA = data/quick-photo-editor.svg

desktopdir = $(datadir)/applications
desktop_DATA = data/quick-photo-editor.desktop

noinst_DATA = vapi/config.vapi

EXTRA_DIST = $(noinst_DATA) $(ui_DATA) $(icon_DATA) $(desktop_DATA)

SUBDIRS = po

dist-hook:
	cd ${top_srcdir} && git log --no-color --stat --name-only --date=short --abbrev-commit > ${srcdir}/ChangeLog
