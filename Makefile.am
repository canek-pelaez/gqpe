AUTOMAKE_OPTIONS = subdir-objects

gresource_file = $(top_srcdir)/data/gqpe.gresource.xml
resource_files = $(top_srcdir)/data/gqpe.ui

icondir = $(datadir)/icons/hicolor/scalable/apps
icon_DATA = data/gqpe.svg

desktopdir = $(datadir)/applications
desktop_DATA = data/gqpe.desktop

noinst_DATA =					\
	vapi/config.vapi			\
	$(gresource_file)			\
	$(resource_files)			\
	$(NULL)

bin_PROGRAMS = src/gqpe

src/resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) 	\
		--target=$@			\
		--sourcedir=$(top_srcdir)/data	\
		--generate-source $<

src_gqpe_SOURCES =				\
	src/application.vala			\
	src/application-window.vala		\
	src/main.vala				\
	src/photograph.vala			\
	src/resources.c				\
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
	--gresources $(gresource_file)		\
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

EXTRA_DIST =					\
	$(noinst_DATA)				\
	$(icon_DATA)				\
	$(desktop_DATA)				\
	$(gresource_file)                       \
        $(resource_files)                       \
	$(NULL)

SUBDIRS = po

dist-hook:
	cd ${top_srcdir} &&			\
	git log --no-color --stat --name-only	\
		--date=short --abbrev-commit	\
		> ${srcdir}/ChangeLog
