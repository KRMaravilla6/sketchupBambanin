# sketchupBambanin
3D model sketchup Ruby code

## CAD floor plan

Run `python floor_plan_export.py` to generate `Bambanin_House_Floor_Plans.dxf`.
The DXF contains the ground floor, second floor, and section A-A at full size
in millimetres. It can be opened in LibreCAD or imported into other CAD
applications. Use the included A1 landscape border at 1:50 when plotting.
The refrigerator footprint, door swing, L-shaped kitchen, W3 window location,
and TV shelf/screen layout are read from the adjacent `sketchupBambanin.rb`
source before each export.
The remaining architectural geometry is a documented 2D plan based on that
model's wall and opening coordinates. Verify on site before construction.

The TV wall is sized for the Philippine-market LG OLED48B4PSA 48-inch TV.
LG lists the body dimensions without stand as 1070 x 620 x 45.9 mm. Its model
and physical footprint are included in the SketchUp model and ground-floor
DXF. The 16:9 screen remains full size with a 1090 x 180 mm minimalist walnut
divider shelf; the upper wall stays clear around the air conditioner. The narrow
wall cannot fit side bookcases without reducing the TV size. Local stock can vary.
See [LG Philippines' specifications](https://www.lg.com/ph/tv-soundbars/oled-tvs/oled48b4psa/)
and [local marketplace listings](https://www.carousell.ph/search/oled%20lg%2048/).

Whenever the Ruby model is revised, regenerate and validate the DXF in the
same revision with `python floor_plan_export.py`. The exporter overwrites the
same `Bambanin_House_Floor_Plans.dxf` path and removes the matching
`#Bambanin_House_Floor_Plans.dxf` backup. Close the drawing in your CAD
application before exporting; an open application may recreate its backup.

The scene builder disables camera transition animation and selects the saved
opening scene after zooming, so clicks use the intended scene camera directly.
