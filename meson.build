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

project('gqpe', ['vala', 'c'], version: '0.1')

cc = meson.get_compiler('c')

add_global_arguments('-DGETTEXT_PACKAGE="gqpe"', language: 'c')

vapidir = join_paths(meson.current_source_dir(), 'vapi')

add_project_arguments(['--vapidir=' + vapidir,
                       '--pkg=config',
                       '--target-glib=2.38'],
                      language: 'vala')

math = cc.find_library('m', required: true)
champlain = dependency('champlain-0.12')
clutter_gtk = dependency('clutter-gtk-1.0')
gee = dependency('gee-0.8')
gexiv2 = dependency('gexiv2')
gtk = dependency('gtk+-3.0')

gnome = import('gnome')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', get_option('localedir'))
conf.set_quoted('LOCALSTATEDIR', get_option('localstatedir'))
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('VERSION', meson.project_version())

valadoc = find_program('valadoc', required: false)
if valadoc.found()
  conf.set('HAVE_VALADOC', 1)
endif

gresources = gnome.compile_resources(
  'gresources', 'data/gqpe.gresource.xml',
  source_dir: 'data',
  c_name: 'resources')

configure_file(output: 'config.h',
               configuration: conf)

gqpe_vala_sources = [
  'src/application-window.vala',
  'src/application.vala',
  'src/namespace.vala',
  'src/orientation.vala',
  'src/photograph.vala',
  'src/tag.vala',
  'src/application-main.vala'
]

gqpe_sources = gqpe_vala_sources + [ gresources ]

gqpe_dependencies = [
  champlain,
  clutter_gtk,
  gee,
  gexiv2,
  gtk,
  math
]

executable('src/gqpe', gqpe_sources,
           dependencies: gqpe_dependencies)

if valadoc.found()
  docdir = 'doc'
  doc = custom_target('documentation',
                      output: docdir,
                      input: gqpe_vala_sources,
                      command: [valadoc,
                                '--directory=@OUTPUT@',
                                '--force',
                                '--package-name=gqpe',
                                '--package-version=0.1',
                                '--target-glib=2.38',
                                '--vapidir=' + vapidir,
                                '--verbose',
                                '--pkg=champlain-0.12',
                                '--pkg=clutter-gtk-1.0',
                                '--pkg=gee-0.8',
                                '--pkg=gexiv2',
                                '--pkg=gtk+-3.0',
                                '--pkg=config',
                                '@INPUT@'],
                      install: false)
endif

subdir('data')
subdir('po')
