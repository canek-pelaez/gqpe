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

icondir = join_paths(get_option('datadir'), 'icons', 'hicolor')

install_data('gqpe.svg',
  install_dir: join_paths(icondir, 'scalable', 'apps'),
)

install_data('cities.csv',
  install_dir: join_paths(datadir, 'gqpe'),
)
