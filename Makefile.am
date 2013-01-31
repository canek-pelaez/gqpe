bin_PROGRAMS = src/quick-photo-editor

src_quick_photo_editor_SOURCES = src/quick-photo-editor.vala

INCLUDES =					\
	-include config.h			\
	-DLOCALEDIR=\""$(localedir)"\"		\
	-DPKGDATADIR=\""$(pkgdatadir)"\"	\
	-DPKGLIBDIR=\""$(pkglibdir)"\"

VALAFLAGS =					\
	--vapidir=$(srcdir)/vapi --pkg config	\
	@QUICKPHOTOEDITOR_PACKAGES@

src_quick_photo_editor_CFLAGS = $(QUICKPHOTOEDITOR_CFLAGS)
src_quick_photo_editor_LDADD = $(QUICKPHOTOEDITOR_LIBS)

uidir = $(pkgdatadir)
ui_DATA = data/quick-photo-editor.ui

icondir = $(datadir)/icons/hicolor/scalable/apps
icon_DATA = data/quick-photo-editor.svg

noinst_DATA = vapi/config.vapi

EXTRA_DIST = $(noinst_DATA) $(ui_DATA) $(icon_DATA)

SUBDIRS = po

dist-hook:
	cd ${top_srcdir} && git log --no-color --stat --name-only --date=short --abbrev-commit > ${srcdir}/ChangeLog
