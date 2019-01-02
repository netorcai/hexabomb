#!/usr/bin/env python3
"""Convert Tiled JSON maps into hexabomb JSON maps.

Usage:
  tiled_to_hexabomb.py <TILED_MAP> [options]

Options:
  -h, --help                    Show this help.
  -o, --output <HEXABOMB_MAP>   Write the map on a file instead of stdout.
  -i, --indent <INDENT>         The output file indentation. [default: 2]
"""
import json
from docopt import docopt

def oddr_to_cube(col, row):
    """Convert offset coordinates (in odd-r) into cube coordinates.
    https://www.redblobgames.com/grids/hexagons/#conversions-offset
    """
    x = int(col - (row - (row & 1)) / 2)
    z = row
    y = -x - z
    return (x,y,z)

def cube_to_axial(x, y, z):
    """Convert cube coordinates into axial coordinates.
    https://www.redblobgames.com/grids/hexagons/#conversions-axial
    """
    return (x, z)

def oddr_to_axial(col, row):
    """Convert offset coordinates (in odd-r) into axial coordinates."""
    cube = oddr_to_cube(col, row)
    return cube_to_axial(*list(cube))

def convert_tiled_into_hexbomb(input_filename, output_filename, indent):
    with open(input_filename) as f:
        tiled = json.load(f)
    width = int(tiled['width'])
    height = int(tiled['height'])
    assert len(tiled['layers']) == 1
    assert len(tiled['layers'][0]['data']) == width*height

    # Tiled stores the map data in a 1D list, but this is 2D (split by width).
    # The coordinates system is implicit here. The map is stored in 'odd-r'.
    # https://www.redblobgames.com/grids/hexagons/
    cells = []
    initial_pos = {}

    for i, value in enumerate(tiled['layers'][0]['data']):
        # Read implicit (=index) 'odd-r' coordinates.
        col = i % width
        row = i // height

        # Get corresponding axial coordinates.
        axial = oddr_to_axial(col, row)
        axial_dict = {"q": axial[0], "r": axial[1]}

        # The cell exists.
        if value > 0:
            # Populate cells.
            cells.append(axial_dict)

            # The cell is not empty.
            if value > 1:
                # Populate starting positions.
                player_id = value - 2
                if player_id in initial_pos:
                    initial_pos[player_id].append(axial_dict)
                else:
                    initial_pos[player_id] = [axial_dict]

    # Generate an hexabomb JSON map.
    hexabomb = {
        "cells": cells,
        "initial_positions": initial_pos
    }
    hexabomb_json = json.dumps(hexabomb, indent=indent, sort_keys=True)

    if output_filename is None:
        print(hexabomb_json)
    else:
        with open(output_filename, 'w') as f:
            f.write(hexabomb_json)
            f.write('\n')
            f.close()

def main():
    args = docopt(__doc__)
    convert_tiled_into_hexbomb(args['<TILED_MAP>'], args['--output'],
        int(args['--indent']))

if __name__ == '__main__':
    main()
