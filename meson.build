project('hexabomb', 'd', version: '1.1.0')

netorcai_dep = dependency('netorcai-client-d', method: 'pkg-config')
docopt_dep = dependency('docopt-d', method: 'pkg-config')

incdir = include_directories('src')

executable('hexabomb',
    'src/actions.d',
    'src/board.d',
    'src/bomb.d',
    'src/cell.d',
    'src/game.d',
    'src/main.d',
    dependencies: [netorcai_dep, docopt_dep],
    include_directories: [incdir],
    install: true, install_dir: 'bin'
)
