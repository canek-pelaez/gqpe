msgfmt = find_program('msgfmt')
podir = join_paths(meson.source_root(), 'po')

custom_target(
  'desktop-file',
  input: 'gqpe.desktop.in',
  output: 'gqpe.desktop',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications'),
  command: [msgfmt, '--desktop', '--template', '@INPUT@',
    '-d', podir, '-o', '@OUTPUT@'],
)

datadir = get_option('datadir')
install_data('cities.csv',
  install_dir: join_paths(datadir, 'gqpe'),
)

icondir = join_paths(datadir, 'icons', 'hicolor')
install_data('gqpe.svg',
  install_dir: join_paths(icondir, 'scalable', 'apps'),
)

gsettings_conf = configuration_data()
gsettings_conf.set ('GETTEXT_PACKAGE', meson.project_name())

configure_file (input: 'mx.unam.GQPE.gschema.xml',
                output: 'mx.unam.GQPE.gschema.xml',
                configuration: gsettings_conf,
                install: true,
                install_dir: join_paths(datadir, 'glib-2.0', 'schemas'))
