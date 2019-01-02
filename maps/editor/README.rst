Editing maps
============

hexabomb does not implement its own map editor.
The following is proposed instead.

1. Use tiled_ to create a map. A tileset is available in this directory.
2. Export your map as JSON_ in tiled.
3. Use :code:`tiled_to_hexabomb.py` to convert the exported map to a one
   that hexabomb understands.

.. _tiled: https://www.mapeditor.org/
