project('gqpe', ['vala', 'c'], version : '0.1')

add_global_arguments('-DGETTEXT_PACKAGE="gqpe"', language: 'c')

add_project_arguments(['--vapidir',
                       join_paths(meson.current_source_dir(), 'vapi'),
                       '--pkg=config',
                       '--target-glib=2.38'],
                      language: 'vala')

champlain = dependency('champlain-0.12')
clutter_gtk = dependency('clutter-gtk-1.0')
gee = dependency('gee-0.8')
gexiv2 = dependency('gexiv2')
gtk = dependency('gtk+-3.0')

gnome = import('gnome')
i18n = import('i18n')

conf = configuration_data()
# Surround the version in quotes to make it a C string
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set('ENABLE_NLS', 1)
conf.set('HAVE_DCGETTEXT', 1)
conf.set('HAVE_GETTEXT', 1)
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', get_option('localedir'))
conf.set_quoted('LOCALSTATEDIR', get_option('localstatedir'))

valadoc = find_program('valadoc', required : false)
if valadoc.found()
  conf.set('HAVE_VALADOC', 1)
endif

gresources = gnome.compile_resources(
  'gresources', 'data/gqpe.gresource.xml',
  source_dir : 'data',
  c_name : 'resources')

configure_file(output : 'config.h',
               configuration : conf)

gqpe_sources = [
  'src/application-window.vala',
  'src/application.vala',
  'src/namespace.vala',
  'src/orientation.vala',
  'src/photograph.vala',
  'src/tag.vala',
  'src/application-main.vala',
  gresources
]

gqpe_dependencies = [
  champlain,
  clutter_gtk,
  gee,
  gexiv2,
  gtk
]

gqpe_link_args = [ '-lm' ]

executable('src/gqpe', gqpe_sources,
           dependencies: gqpe_dependencies,
           link_args: gqpe_link_args)
