AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = src/gqpe

GQPESOURCES =							\
	src/application.vala					\
	src/application-window.vala				\
	src/orientation.vala					\
	src/namespace.vala					\
	src/photograph.vala

src_gqpe_SOURCES =						\
	$(GQPESOURCES)						\
	src/application-main.vala				\
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

gresource_file = $(top_srcdir)/data/gqpe.gresource.xml
resource_files = 						\
	$(top_srcdir)/data/gqpe.css				\
	$(top_srcdir)/data/gqpe.ui				\
	$(top_srcdir)/data/menu.ui

src/resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) 			\
		--target=$@					\
		--sourcedir=$(top_srcdir)/data			\
		--generate-source $<

MSGFMT_DESKTOP_OPTIONS =					\
	--keyword=GenericName					\
	--keyword=Comment

gqpe_desktop_in_file = $(top_srcdir)/data/gqpe.desktop.in
data/gqpe.desktop: $(gqpe_desktop_in_file)
	$(AM_V_GEN)$(MSGFMT) $(MSGFMT_DESKTOP_OPTIONS) 		\
		--desktop --template $< 			\
		-d $(top_srcdir)/po -o $@

icondir = $(datadir)/icons/hicolor/scalable/apps
icon_DATA = data/gqpe.svg

desktopdir = $(datadir)/applications
desktop_DATA = data/gqpe.desktop

noinst_DATA =							\
	vapi/config.vapi					\
	$(gqpe_desktop_in_file)					\
	$(gresource_file)					\
	$(resource_files)

EXTRA_DIST =							\
	$(noinst_DATA)						\
	$(icon_DATA)						\
	$(gqpe_desktop_in_file)					\
	$(gresource_file)                       		\
        $(resource_files)

CLEANFILES = $(desktop_DATA)

if HAVE_VALADOC

AM_V_VALADOC = $(AM_V_VALADOC_$(V))
AM_V_VALADOC_ = $(AM_V_VALADOC_$(AM_DEFAULT_VERBOSITY))
AM_V_VALADOC_0 = @echo "  VALADOC " $@;

docs: doc/gqpe/index.htm

doc/gqpe/index.htm: $(GQPESOURCES)
	$(AM_V_VALADOC)$(VALADOC)					\
		--directory=doc						\
		--force							\
		--package-name=${PACKAGE}				\
		--package-version=${VERSION}				\
		--target-glib=2.38					\
		--vapidir=vapi						\
		--verbose						\
		@GEE_PACKAGES@						\
		@GEXIV2_PACKAGES@					\
		@GTK_PACKAGES@						\
		--pkg config						\
		$(GQPESOURCES)

clean-docs:
	-rm -rf doc/

clean-local: clean-docs

endif

SUBDIRS = . po
