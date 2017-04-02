AUTOMAKE_OPTIONS = subdir-objects

gresource_file = $(top_srcdir)/data/gqpe.gresource.xml
resource_files = 						\
	$(top_srcdir)/data/gqpe.ui				\
	$(top_srcdir)/data/gqpe.css				\
	$(NULL)

src/resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) 			\
		--target=$@					\
		--sourcedir=$(top_srcdir)/data			\
		--generate-source $<

bin_PROGRAMS = src/gqpe

src_gqpe_SOURCES =						\
	src/application.vala					\
	src/application-window.vala				\
	src/application-main.vala				\
	src/photograph.vala					\
	src/resources.c

AM_CPPFLAGS =							\
	-include config.h					\
	-DLOCALEDIR=\""$(localedir)"\"				\
	-DPKGDATADIR=\""$(pkgdatadir)"\"			\
	-DPKGLIBDIR=\""$(pkglibdir)"\"


src_gqpe_VALAFLAGS =						\
	@GEE_PACKAGES@						\
	@GEXIV2_PACKAGES@					\
	@GTK_PACKAGES@						\
	--target-glib=2.38					\
	--vapidir=$(srcdir)/vapi				\
	--pkg config						\
	--gresources $(gresource_file)

src_gqpe_CFLAGS =						\
	@GEE_CFLAGS@						\
	@GEXIV2_CFLAGS@						\
	@GTK_CFLAGS@						\
	-w

src_gqpe_LDADD =						\
	@GEE_LIBS@						\
	@GEXIV2_LIBS@						\
	@GTK_LIBS@						\
	-lm

icondir = $(datadir)/icons/hicolor/scalable/apps
icon_DATA = data/gqpe.svg

desktopdir = $(datadir)/applications
desktop_DATA = data/gqpe.desktop

noinst_DATA =							\
	vapi/config.vapi					\
	$(gresource_file)					\
	$(resource_files)

EXTRA_DIST =							\
	$(noinst_DATA)						\
	$(icon_DATA)						\
	$(desktop_DATA)						\
	$(gresource_file)                       		\
        $(resource_files)

SUBDIRS = po
