project('random', 'cpp',
    default_options: ['cpp_std=c++17'],
    version: '1.0.0'
)

netorcai_client_cpp_dep = dependency('netorcai-client-cpp')
threads_dep = dependency('threads', required: true)

src = [
    'hexabomb-parse.cpp',
    'hexabomb-parse.hpp',
    'random.cpp'
]

player = executable('random', src,
    dependencies: [netorcai_client_cpp_dep, threads_dep],
    install: true
)
