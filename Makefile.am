bin_PROGRAMS = quick-photo-editor

quick_photo_editor_SOURCES = src/quick-photo-editor.vala

# \
#        -DLOCALEDIR=\""$(localedir)"\" \
#        -DPKGDATADIR=\""$(pkgdatadir)"\" \
#        -DPKGLIBDIR=\""$(pkglibdir)"\"

INCLUDES =					\
	-include config.h			\
	-DPKGDATADIR=\""$(pkgdatadir)"\"

VALAFLAGS =					\
	--vapidir=$(srcdir)/vapi --pkg config	\
	@QUICKPHOTOEDITOR_PACKAGES@

quick_photo_editor_CFLAGS = $(QUICKPHOTOEDITOR_CFLAGS)
quick_photo_editor_LDADD = $(QUICKPHOTOEDITOR_LIBS)

uidir = $(pkgdatadir)
ui_DATA = data/quick-photo-editor.ui

noinst_DATA = vapi/config.vapi

EXTRA_DIST = $(noinst_DATA)
