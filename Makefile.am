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

# Automake options
AUTOMAKE_OPTIONS = subdir-objects

# GQPE
bin_PROGRAMS = src/gqpe

GQPESOURCES =								\
	src/application-window.vala					\
	src/application.vala						\
	src/namespace.vala						\
	src/orientation.vala						\
	src/photograph.vala						\
	src/tag.vala

src_gqpe_SOURCES =							\
	$(GQPESOURCES)							\
	src/application-main.vala					\
	src/resources.c

AM_CPPFLAGS =								\
	-include config.h						\
	-DLOCALEDIR=\""$(localedir)"\"					\
	-DPKGDATADIR=\""$(pkgdatadir)"\"				\
	-DPKGLIBDIR=\""$(pkglibdir)"\"

src_gqpe_VALAFLAGS =							\
	@CHAMPLAIN_PACKAGES@						\
	@CLUTTER_GTK_PACKAGES@						\
	@GEE_PACKAGES@							\
	@GEXIV2_PACKAGES@						\
	@GTK_PACKAGES@							\
	--target-glib=2.38						\
	--vapidir=$(srcdir)/vapi					\
	--pkg config							\
	--gresources $(gresource_file)

src_gqpe_CFLAGS =							\
	@CHAMPLAIN_CFLAGS@						\
	@CLUTTER_GTK_CFLAGS@						\
	@GEE_CFLAGS@							\
	@GEXIV2_CFLAGS@							\
	@GTK_CFLAGS@							\
	-w

src_gqpe_LDADD =							\
	@CHAMPLAIN_LIBS@						\
	@CLUTTER_GTK_LIBS@						\
	@GEE_LIBS@							\
	@GEXIV2_LIBS@							\
	@GTK_LIBS@							\
	-lm

# Resource file
gresource_file = $(top_srcdir)/data/gqpe.gresource.xml
resource_files = 							\
	$(top_srcdir)/data/application-menu.ui				\
	$(top_srcdir)/data/application-window.ui			\
	$(top_srcdir)/data/gqpe.css					\
	$(top_srcdir)/data/pin-map.svg

src/resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) 				\
		--target=$@						\
		--sourcedir=$(top_srcdir)/data				\
		--generate-source $<

# Desktop file
MSGFMT_DESKTOP_OPTIONS =						\
	--keyword=GenericName						\
	--keyword=Comment

gqpe_desktop_in_file = $(top_srcdir)/data/gqpe.desktop.in
data/gqpe.desktop: $(gqpe_desktop_in_file)
	$(AM_V_GEN)$(MSGFMT) $(MSGFMT_DESKTOP_OPTIONS) 			\
		--desktop --template $< 				\
		-d $(top_srcdir)/po -o $@

desktopdir = $(datadir)/applications
desktop_DATA = data/gqpe.desktop

# Icons
icondir = $(datadir)/icons/hicolor/scalable/apps
icon_DATA = data/gqpe.svg

# Extra files
noinst_DATA =								\
	vapi/config.vapi						\
	$(gqpe_desktop_in_file)						\
	$(gresource_file)						\
	$(resource_files)

EXTRA_DIST =								\
	$(noinst_DATA)							\
	$(icon_DATA)							\
	$(gqpe_desktop_in_file)						\
	$(gresource_file)                       			\
        $(resource_files)

CLEANFILES = $(desktop_DATA)

# Valadoc
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
		@CHAMPLAIN_PACKAGES@					\
		@CLUTTER_GTK_PACKAGES@					\
		@GEE_PACKAGES@						\
		@GEXIV2_PACKAGES@					\
		@GTK_PACKAGES@						\
		--pkg config						\
		$(GQPESOURCES)

clean-docs:
	-rm -rf doc/

clean-local: clean-docs

endif

# Internationalization
SUBDIRS = . po
