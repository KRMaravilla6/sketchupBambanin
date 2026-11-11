require 'tmpdir'
model = Sketchup.active_model
raise 'No active SketchUp model.' unless model
model.start_operation('Build Combined Minimal Elegant Exterior & Upgraded Interior', true)
begin
root_ents = model.entities
['FURNISHING', 'EXTERIOR_REDESIGN_V7', 'House_10x10_Model', 'Mindoro_Breeze_Atrium_House', 'Mindoro_10x10_Tropical_House'].each do |gname|
old = root_ents.grep(Sketchup::Group).find { |g| g.name == gname }
old.erase! if old && !old.deleted?
end
root_ents.grep(Sketchup::ComponentInstance).to_a.each do |inst|
inst.erase! if inst.definition.name =~ /Laura|Heather|Scale|Person|Chris|Sumele/i
end
root_ents.grep(Sketchup::SectionPlane).each { |sp| sp.erase! unless sp.deleted? }
model.rendering_options['DisplaySectionPlanes'] = false
model.rendering_options['DisplaySectionCuts'] = false
master_group = root_ents.add_group
master_group.name = 'House_10x10_Model'
ents = master_group.entities
layers = model.layers
L_SUV = layers['00_HIDE_UNHIDE_Black_SUV'] || layers.add('00_HIDE_UNHIDE_Black_SUV')
L_SITE = layers['01_Site_and_Gardens'] || layers.add('01_Site_and_Gardens')
L_FENCE = layers['02_Front_Fence_and_Gates'] || layers.add('02_Front_Fence_and_Gates')
L_PERIM = layers['03_Perimeter_Firewalls'] || layers.add('03_Perimeter_Firewalls')
L_GF_EXT = layers['04_GF_Exterior_Front'] || layers.add('04_GF_Exterior_Front')
L_GF_WALLS = layers['05_GF_Walls_and_Shell'] || layers.add('05_GF_Walls_and_Shell')
L_GF_FURN = layers['06_GF_Interior_Furniture'] || layers.add('06_GF_Interior_Furniture')
L_2F_SLAB = layers['07_2F_Floor_Slabs'] || layers.add('07_2F_Floor_Slabs')
L_2F_EXT = layers['08_2F_Exterior_Front'] || layers.add('08_2F_Exterior_Front')
L_2F_WALLS = layers['09_2F_Walls_and_Shell'] || layers.add('09_2F_Walls_and_Shell')
L_2F_FURN = layers['10_2F_Interior_Furniture'] || layers.add('10_2F_Interior_Furniture')
L_ROOF = layers['11_Roof_Assembly'] || layers.add('11_Roof_Assembly')
[L_SUV, L_SITE, L_FENCE, L_PERIM, L_GF_EXT, L_GF_WALLS, L_GF_FURN,
L_2F_SLAB, L_2F_EXT, L_2F_WALLS, L_2F_FURN, L_ROOF].each { |l| l.visible = true }
def toggle_suv
m = Sketchup.active_model
suv_layer = m.layers['00_HIDE_UNHIDE_Black_SUV']
if suv_layer
suv_layer.visible = !suv_layer.visible?
puts "Black SUV is now #{suv_layer.visible? ? 'VISIBLE' : 'HIDDEN'}."
end
end
unless $suv_toggle_menu_added
UI.menu('Extensions').add_item('Toggle Black SUV (Show / Hide)') { toggle_suv }
$suv_toggle_menu_added = true
end
def z_upper_deck(y); 6.32 + (y - 0.85) * (-0.52 / 7.35); end
def z_upper_soffit(y); z_upper_deck(y) - 0.08; end
def z_lower_deck(y); 5.82 + (y - 3.40) * (-0.34 / 4.80); end
def z_lower_soffit(y); z_lower_deck(y) - 0.08; end
def hash_noise(x, y)
n = (x * 374761393 + y * 668265263) ^ (x * 1274126177)
n = (n ^ (n >> 13)) * 1274126177
((n ^ (n >> 16)) & 0x7fffffff).to_f / 2147483647.0
end
def smooth_noise(u, v, freq)
x = u * freq; y = v * freq
xi = x.floor; yi = y.floor
xf = x - xi; yf = y - yi
sx = xf * xf * (3.0 - 2.0 * xf)
sy = yf * yf * (3.0 - 2.0 * yf)
n00 = hash_noise(xi % freq, yi % freq)
n10 = hash_noise((xi + 1) % freq, yi % freq)
n01 = hash_noise(xi % freq, (yi + 1) % freq)
n11 = hash_noise((xi + 1) % freq, (yi + 1) % freq)
(n00 + sx * (n10 - n00)) + sy * ((n01 + sx * (n11 - n01)) - (n00 + sx * (n10 - n00)))
end
def fbm_noise(u, v)
0.50 * smooth_noise(u, v, 4) + 0.25 * smooth_noise(u, v, 8) + 0.15 * smooth_noise(u, v, 16) + 0.10 * smooth_noise(u, v, 32)
end
def write_bmp(filename, size, &pixel_block)
path = File.join(Dir.tmpdir, filename)
row_bytes = size * 3
padding = (4 - (row_bytes % 4)) % 4
data_size = (row_bytes + padding) * size
file_size = 54 + data_size
File.open(path, 'wb') do |file|
file.write(['BM', file_size, 0, 0, 54, 40, size, size, 1, 24, 0, data_size, 2835, 2835, 0, 0].pack('A2Vv2V2l2v2V6'))
pad = "\x00" * padding
(0...size).each do |y|
row = String.new('', encoding: 'ASCII-8BIT')
(0...size).each do |x|
r, g, b = pixel_block.call(x, y, size)
row << [[[b.round, 0].max, 255].min, [[g.round, 0].max, 255].min, [[r.round, 0].max, 255].min].pack('C3')
end
row << pad if padding > 0
file.write(row)
end
end
path
rescue StandardError
nil
end
bmp_marble = write_bmp('Mindoro_Bianco_Carrara_Unified.bmp', 256) do |x, y, size|
if x == 0 || y == 0 || x == size / 2 || y == size / 2
[237, 237, 235]
else
u = x.to_f / size; v = y.to_f / size
n1 = fbm_noise(u, v); n2 = fbm_noise((u + 0.37) % 1.0, (v + 0.61) % 1.0)
d1 = (((u * 0.75 + v * 0.55 + 0.45 * (n1 - 0.5)) * 2.0) % 1.0 - 0.5).abs * 2.0
d2 = ((((u * 0.45 - v * 0.85 + 0.35 * (n2 - 0.5)) % 1.0 + 1.0) % 1.0) - 0.5).abs * 2.0
vein = Math.exp(-(d1 ** 1.8) * 28.0) * 22.0 + Math.exp(-(d2 ** 2.0) * 45.0) * 12.0
drop = vein + (n1 - 0.5) * 6.0
[249.0 - drop, 248.5 - drop, 247.5 - drop * 0.95]
end
end
bmp_quartz = write_bmp('Mindoro_Warm_Alabaster_Quartz.bmp', 128) do |x, y, size|
s = (fbm_noise(x.to_f / size, y.to_f / size) - 0.5) * 4.5
[246.0 + s, 242.0 + s, 234.0 + s]
end
bmp_subway = write_bmp('Mindoro_Warm_Sand_Subway.bmp', 192) do |x, y, size|
row_h = size / 6; col_w = size / 3
row = y / row_h; ry = y % row_h
sx = (x + (row.odd? ? col_w / 2 : 0)) % size
rx = sx % col_w
if ry < 3 || rx < 3
[242, 238, 231]
else
bevel = (ry < 7 || ry > row_h - 4 || rx < 7 || rx > col_w - 4) ? -4.5 : 0.0
glaze = Math.sin((ry.to_f / row_h) * Math::PI) * 3.5
[218.0 + glaze + bevel, 208.0 + glaze + bevel, 194.0 + glaze + bevel]
end
end
bmp_pietrasanta = write_bmp('Pietrasanta_Light_Grey_Matte.bmp', 256) do |x, y, size|
u = x.to_f / size; v = y.to_f / size
n1 = fbm_noise(u, v); n2 = fbm_noise((u + 0.28) % 1.0, (v + 0.47) % 1.0)
cloud = (n1 - 0.5) * 14.0 + (n2 - 0.5) * 7.0
d1 = (((u * 0.82 + v * 0.38 + 0.42 * (n1 - 0.5)) * 2.0) % 1.0 - 0.5).abs * 2.0
vein = Math.exp(-(d1 ** 1.9) * 26.0) * 16.0
g = 204.0 + cloud - vein * 0.25
[g, g + 1.0, g + 2.5]
end
bmp_aston = write_bmp('Aston_Nature_47x47.bmp', 256) do |x, y, size|
u = x.to_f / size; v = y.to_f / size
n1 = fbm_noise(u * 1.05, v); n2 = fbm_noise((u + 0.51) % 1.0, (v + 0.33) % 1.0)
d1 = (((u * 0.62 + v * 0.78 + 0.48 * (n1 - 0.5)) * 2.0) % 1.0 - 0.5).abs * 2.0
d2 = ((((u * 0.40 - v * 0.88 + 0.32 * (n2 - 0.5)) % 1.0 + 1.0) % 1.0) - 0.5).abs * 2.0
vein = Math.exp(-(d1 ** 1.55) * 16.0) * 0.72 + Math.exp(-(d2 ** 2.1) * 38.0) * 0.38
base = (n1 - 0.5) * 12.0
[186.0 + base - vein * 42.0, 174.0 + base - vein * 58.0, 156.0 + base * 0.8 - vein * 72.0]
end
bmp_porcelanato = write_bmp('Pisos_Porcelanato_60x60_Full_Body.bmp', 256) do |x, y, size|
u = x.to_f / size; v = y.to_f / size
n1 = fbm_noise(u, v); n2 = fbm_noise((u + 0.37) % 1.0, (v + 0.61) % 1.0)
d1 = (((u * 0.75 + v * 0.55 + 0.45 * (n1 - 0.5)) * 2.0) % 1.0 - 0.5).abs * 2.0
d2 = ((((u * 0.45 - v * 0.85 + 0.35 * (n2 - 0.5)) % 1.0 + 1.0) % 1.0) - 0.5).abs * 2.0
vein = Math.exp(-(d1 ** 1.8) * 28.0) * 28.0 + Math.exp(-(d2 ** 2.0) * 45.0) * 16.0
drop = vein + (n1 - 0.5) * 5.0
[248.0 - drop * 0.85, 247.0 - drop * 0.82, 245.0 - drop * 0.70]
end
bmp_spc_oak = write_bmp('SPC_Light_Oak_Plank.bmp', 256) do |x, y, size|
grain = Math.sin(y * 0.22 + Math.sin(x * 0.045) * 2.8) * 9.0
fine = Math.cos(x * 0.62 + y * 0.07) * 3.2
streak = Math.sin((x * 0.031) + (y * 0.9)) * 2.4
pore = ((x * 19 + y * 5) % 29 == 0) ? -7.0 : 0.0
[214.0 + grain + fine + pore, 186.0 + grain * 0.88 + streak, 150.0 + grain * 0.62 + fine * 0.4]
end
def get_mat(mats, name, r, g, b, alpha = 1.0, tex_path = nil, sx_mm = 1200.0, sy_mm = 1200.0)
m = mats[name] || mats.add(name)
m.alpha = alpha
if tex_path && File.file?(tex_path)
m.color = Sketchup::Color.new(255, 255, 255)
m.texture = tex_path
m.texture.size = [sx_mm / 25.4, sy_mm / 25.4]
else
m.texture = nil
m.color = Sketchup::Color.new(r, g, b)
end
m
end
mats = model.materials
M_SLAB = get_mat(mats, 'Concrete_Slab', 211, 207, 199)
M_SIDEWALK = get_mat(mats, 'Sidewalk_Paver', 195, 191, 183)
M_PEBBLES = get_mat(mats, 'River_Pebbles', 225, 222, 215)
M_SOIL = get_mat(mats, 'Garden_Soil_Mulch', 92, 74, 58)
M_WALL_EXT = get_mat(mats, 'Wall_Exterior', 243, 240, 233)
M_WALL_FENCE = get_mat(mats, 'Wall_Perimeter', 218, 211, 199)
M_CANOPY = get_mat(mats, 'Dark_Canopy', 64, 66, 68)
M_METAL_BLK = get_mat(mats, 'Black_Steel', 47, 49, 50)
M_BRASS = get_mat(mats, 'Champagne_Brass', 198, 166, 108)
M_CHROME = get_mat(mats, 'Polished_Chrome', 210, 215, 220)
M_STONE = get_mat(mats, 'Stone_Cladding', 190, 176, 153)
M_WOOD_EXT = get_mat(mats, 'Exterior_Teak', 157, 112, 76)
M_WOOD_REAR = get_mat(mats, 'Rear_Wood_Siding', 171, 145, 112)
M_SOFFIT_WOOD = get_mat(mats, 'Soffit_Cedar', 181, 137, 91)
M_ROOF_RED = get_mat(mats, 'Roof_Red_Metal', 65, 66, 65)
M_ROOF_INSULATION = get_mat(mats, 'Roof_Batt_Insulation_60mm', 221, 196, 122)
M_ROOF_RADIANT_BARRIER = get_mat(mats, 'Roof_Radiant_Barrier_Foil', 190, 197, 202)
M_WINDOW_MOSQUITO_MESH = get_mat(mats, 'Fine_Mosquito_Screen_Translucent', 66, 74, 71, 0.12)
M_FASCIA_RED = get_mat(mats, 'Fascia_Dark_Red', 52, 54, 54)
M_GRASS = get_mat(mats, 'Garden_Grass', 102, 152, 78)
M_LEAF_DARK = get_mat(mats, 'Foliage_Deep', 54, 112, 44)
M_LEAF_MID = get_mat(mats, 'Foliage_Mid', 74, 136, 56)
M_LEAF_LIME = get_mat(mats, 'Foliage_Bright', 98, 158, 68)
M_PALM_TRUNK = get_mat(mats, 'Palm_Bark', 128, 108, 88)
M_MARBLE_ICE = get_mat(mats, 'Pisos_Porcelanato_60x60_Full_Body', 248, 247, 244, 1.0, bmp_porcelanato, 600.0, 600.0)
M_MARBLE_SILV = M_MARBLE_ICE
M_MARBLE_VEIN = M_MARBLE_ICE
M_TILE_BORDER = M_MARBLE_ICE
M_GROUT_PLAT = get_mat(mats, 'Platinum_Silver_Grout', 232, 230, 225)
M_FLOOR_2F = M_MARBLE_ICE
M_FLOOR_2F_ALT = M_MARBLE_ICE
M_TILE_BATH1 = get_mat(mats, 'Pietrasanta_Light_Grey_Matte_35x35', 204, 206, 208, 1.0, bmp_pietrasanta, 350.0, 350.0)
M_TILE_BATH2 = get_mat(mats, 'Aston_Nature_47x47', 186, 174, 156, 1.0, bmp_aston, 470.0, 470.0)
M_TILE_BATH = M_TILE_BATH1
M_SPC_OAK = get_mat(mats, 'SPC_Light_Oak_Plank_Flooring', 214, 186, 150, 1.0, bmp_spc_oak, 1220.0, 180.0)
M_SPC_GROUT = get_mat(mats, 'SPC_Plank_Micro_Bevel', 196, 176, 148)
M_TILE_TERRACE = get_mat(mats, 'Basalt_Deck_Tile', 195, 191, 183)
M_TILE_GARAGE = get_mat(mats, 'Granite_Paver_Tile', 195, 191, 183)
M_GROUT_DARK = get_mat(mats, 'Tile_Grout_Charcoal', 215, 211, 204)
M_MARBLE_WHT = get_mat(mats, 'Calacatta_Marble', 246, 242, 233, 1.0, bmp_quartz, 1800.0, 1800.0)
M_MARBLE_DRK = get_mat(mats, 'Nero_Marquina', 42, 44, 47)
M_KITCHEN_TOP = get_mat(mats, 'Kitchen_Charcoal_Top', 42, 44, 47)
M_SUBWAY_TILE = get_mat(mats, 'Kitchen_Subway_Tile', 218, 208, 194, 1.0, bmp_subway, 900.0, 600.0)
M_CHARCOAL_CAB = get_mat(mats, 'Kitchen_Charcoal_Cab', 44, 46, 49)
M_GREIGE_CAB = get_mat(mats, 'Kitchen_Upper_Greige', 185, 180, 170)
M_RUG = get_mat(mats, 'Area_Rug_Warm', 212, 206, 196)
M_WOOD_DOOR = get_mat(mats, 'Hardwood_Walnut', 118, 82, 54)
M_WOOD_OAK = get_mat(mats, 'Warm_Oak_Wood', 194, 158, 116)
M_WOOD_TAN = get_mat(mats, 'Fluted_Teak_Slat', 176, 134, 90)
M_WOOD_DARK = get_mat(mats, 'Espresso_Veneer', 72, 52, 38)
M_SOFA_MAIN = get_mat(mats, 'Boucle_Taupe', 158, 146, 134)
M_PILLOW_RUST = get_mat(mats, 'Velvet_Terracotta', 182, 108, 82)
M_PILLOW_SLATE = get_mat(mats, 'Velvet_Navy', 36, 58, 92)
M_PILLOW_PINK = get_mat(mats, 'Velvet_DustyPink', 196, 144, 154)
M_PILLOW_SAGE = get_mat(mats, 'Linen_Sage', 148, 172, 142)
M_PILLOW_CREAM = get_mat(mats, 'Linen_Cream', 240, 234, 224)
M_MUSTARD = get_mat(mats, 'Warm_Mustard_Accent', 202, 156, 52)
M_TEAL = get_mat(mats, 'Deep_Teal_Accent', 48, 126, 128)
M_CHAIR_FAB = get_mat(mats, 'Dining_Upholstery', 152, 140, 128)
M_BED_WHITE = get_mat(mats, 'Egyptian_Cotton', 248, 247, 244)
M_BED_THROW = get_mat(mats, 'Slate_Cashmere', 62, 118, 124)
M_FIXTURE = get_mat(mats, 'Ceramic_White', 251, 251, 249)
M_WATER_BLUE = get_mat(mats, 'Toilet_Water_Seal', 154, 212, 226, 0.65)
M_LED_GLOW = get_mat(mats, 'Warm_LED_Light', 255, 240, 202)
M_BURNER_RED = get_mat(mats, 'Burner_Ring', 220, 75, 45)
M_OVEN_GLASS = get_mat(mats, 'Oven_Tinted_Window', 28, 30, 34, 0.65)
M_HOB_GLASS = get_mat(mats, 'Induction_Hob_Glass', 18, 20, 23)
M_CURTAIN = get_mat(mats, 'Curtain_Sheer', 248, 245, 238, 0.88)
M_GLASS = get_mat(mats, 'Window_Glass', 135, 190, 220, 0.30)
M_MIRROR = get_mat(mats, 'Silver_Mirror', 212, 222, 230, 1.0)
M_RAIL_GLASS = get_mat(mats, 'Tempered_Balustrade_Glass', 165, 215, 230, 0.32)
M_GLASS_EDGE = get_mat(mats, 'Polished_Aqua_Glass_Edge', 75, 185, 165, 0.68)
M_SHOWER_GL = get_mat(mats, 'Shower_Glass', 185, 222, 235, 0.28)
M_SUV_BLACK = get_mat(mats, 'SUV_Gloss_Black', 8, 8, 10)
M_SUV_TRIM = get_mat(mats, 'BMW_Gloss_Shadow', 12, 14, 17)
M_SUV_GLASS = get_mat(mats, 'BMW_Tinted_Glass', 38, 48, 58, 0.58)
M_SUV_LEATHER = get_mat(mats, 'BMW_Merino_Leather', 55, 48, 44)
M_SUV_TIRE = get_mat(mats, 'BMW_Tire_Rubber', 26, 28, 30)
M_SUV_RIM = get_mat(mats, 'BMW_Alloy_Silver', 210, 215, 222)
M_SUV_TAIL_R = get_mat(mats, 'BMW_Taillight_Red', 220, 28, 32)
M_SUV_HEAD_W = get_mat(mats, 'BMW_Laser_White', 245, 250, 255)
M_SUV_DRL = get_mat(mats, 'BMW_Angel_Eye_Blue', 175, 225, 255)
M_BMW_BLUE = get_mat(mats, 'BMW_Roundel_Blue', 0, 102, 177)
def mm(v); v.to_f.mm; end
def m(v); v.to_f.m; end
def face_mat(f, mat)
return unless f && mat
f.material = mat
f.back_material = mat
end
# #region agent log
$agent_dbg_path = 'c:/Users/kevinryan/project_bambanin/sketchupBambanin/sketchupBambanin/.cursor/debug-e4f4ee.log'
$agent_arch_boxes = []
def agent_dbg(hyp, loc, msg, data)
  require 'json' unless defined?(JSON)
  rec = { 'sessionId' => 'e4f4ee', 'timestamp' => (Time.now.to_f * 1000).to_i, 'location' => loc, 'message' => msg, 'hypothesisId' => hyp, 'data' => data }
  File.open($agent_dbg_path, 'a') { |f| f.puts(rec.to_json) }
rescue StandardError
end
def agent_record_box(name, x1, y1, x2, y2, z1, z2, src)
  xmin, xmax = [x1.to_f, x2.to_f].minmax
  ymin, ymax = [y1.to_f, y2.to_f].minmax
  zmin, zmax = [z1.to_f, z2.to_f].minmax
  vol = (xmax - xmin) * (ymax - ymin) * (zmax - zmin)
  return if vol < 1.0e-6
  $agent_arch_boxes << { 'name' => name.to_s, 'xmin' => xmin, 'ymin' => ymin, 'zmin' => zmin, 'xmax' => xmax, 'ymax' => ymax, 'zmax' => zmax, 'vol' => vol, 'src' => src }
end
# #endregion
def add_box(parent_ents, x1, y1, x2, y2, z1, z2, mat = nil, name = nil)
xmin, xmax = [x1, x2].minmax
ymin, ymax = [y1, y2].minmax
zmin, zmax = [z1, z2].minmax
return nil if (xmax - xmin) < 1e-4 || (ymax - ymin) < 1e-4 || (zmax - zmin) < 1e-4
# #region agent log
nstr = name.to_s
arch = nstr =~ /Wall|Slab|Floor|Rail|Guard|Handrail|Canopy|Soffit|Carriage|Tile|Landing|Railing|Balustrade|Ceiling|Facade|Spandrel/i
zspan = zmax - zmin
xy = (xmax - xmin) * (ymax - ymin)
struct_unnamed = nstr.empty? && (zspan >= 0.20 || (xy >= 1.0 && zspan >= 0.10))
agent_record_box(nstr.empty? ? format('unnamed_%.3f_%.3f_%.3f', xmin, ymin, zmin) : nstr, xmin, ymin, xmax, ymax, zmin, zmax, 'add_box') if arch || struct_unnamed
# #endregion
grp = parent_ents.add_group
grp.name = name if name
pts = [
Geom::Point3d.new(xmin.m, ymin.m, zmin.m),
Geom::Point3d.new(xmax.m, ymin.m, zmin.m),
Geom::Point3d.new(xmax.m, ymax.m, zmin.m),
Geom::Point3d.new(xmin.m, ymax.m, zmin.m)
]
face = grp.entities.add_face(pts)
if face
face.reverse! if face.normal.z < 0
face_mat(face, mat)
face.pushpull((zmax - zmin).m)
end
grp.entities.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
grp.material = mat if mat
grp
end
def rounded_rect_pts(w, d, r, z = 0.0, segs = 6)
w = w.to_f; d = d.to_f
r = [[r.to_f, 0.0].max, [w, d].min * 0.45].min
corners = [[r, r, 180.0, 270.0], [w - r, r, 270.0, 360.0], [w - r, d - r, 0.0, 90.0], [r, d - r, 90.0, 180.0]]
pts = []
corners.each do |cx, cy, s_deg, e_deg|
(0..segs).each do |i|
ang = (s_deg + (e_deg - s_deg) * i.to_f / segs) * Math::PI / 180.0
pts << Geom::Point3d.new(mm(cx + r * Math.cos(ang)), mm(cy + r * Math.sin(ang)), mm(z))
end
end
pts
end
def rounded_box_at(ents, name, x_m, y_m, z_m, w_mm, d_mm, h_mm, r_mm, mat)
grp = ents.add_group
grp.name = name
face = grp.entities.add_face(rounded_rect_pts(w_mm, d_mm, r_mm, 0.0, 6))
if face
face.reverse! if face.normal.z < 0
face_mat(face, mat)
face.pushpull(mm(h_mm))
end
grp.entities.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
grp.entities.grep(Sketchup::Edge).each do |e|
if (e.start.position.z - e.end.position.z).abs > mm(0.5)
e.soft = true; e.smooth = true
end
end
grp.material = mat if mat
grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(x_m.m, y_m.m, z_m.m)))
grp
end
def vertical_capsule_xz(ents, name, x0_mm, y_back_mm, z0_mm, w_mm, thick_mm, h_mm, r_mm, mat)
w = w_mm.to_f; h = h_mm.to_f; t = thick_mm.to_f
r = [[r_mm.to_f, 0.0].max, [w, h].min * 0.48].min
segs = 10
corners = [[r, r, 180.0, 270.0], [w - r, r, 270.0, 360.0], [w - r, h - r, 0.0, 90.0], [r, h - r, 90.0, 180.0]]
pts = []
corners.each do |cx, cz, s_deg, e_deg|
(0..segs).each do |i|
ang = (s_deg + (e_deg - s_deg) * i.to_f / segs) * Math::PI / 180.0
pts << Geom::Point3d.new(mm(x0_mm + cx + r * Math.cos(ang)), mm(y_back_mm), mm(z0_mm + cz + r * Math.sin(ang)))
end
end
grp = ents.add_group
grp.name = name
face = grp.entities.add_face(pts)
if face
face.reverse! if face.normal.y > 0
face_mat(face, mat)
face.pushpull(mm(t))
end
grp.entities.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
grp.material = mat if mat
grp
end
def cylinder_mm(ents, name, radius_mm, height_mm, mat, segs = 24)
grp = ents.add_group
grp.name = name
edges = grp.entities.add_circle(ORIGIN, Z_AXIS, mm(radius_mm), segs)
face = grp.entities.add_face(edges)
if face
face.reverse! if face.normal.z < 0
face_mat(face, mat)
face.pushpull(mm(height_mm))
end
grp.entities.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
grp.entities.grep(Sketchup::Edge).each { |e| e.soft = true; e.smooth = true }
grp.material = mat if mat
grp
end
def cylinder_between_mm(ents, name, p1, p2, rad_mm, mat, segs = 16)
dx = p2[0].to_f - p1[0].to_f; dy = p2[1].to_f - p1[1].to_f; dz = p2[2].to_f - p1[2].to_f
len = Math.sqrt(dx * dx + dy * dy + dz * dz)
return nil if len < 0.01
part = cylinder_mm(ents, name, rad_mm, len, mat, segs)
dir = Geom::Vector3d.new(mm(dx), mm(dy), mm(dz))
rot_axis = Z_AXIS.cross(dir)
rot = rot_axis.length > 1e-8 ? Geom::Transformation.rotation(ORIGIN, rot_axis, Z_AXIS.angle_between(dir)) : Geom::Transformation.new
trans = Geom::Transformation.translation(Geom::Vector3d.new(mm(p1[0]), mm(p1[1]), mm(p1[2])))
part.transform!(trans * rot)
part
end
def tapered_leg_at(ents, name, x_m, y_m, z_m, bw_mm, tw_mm, h_mm, mat)
grp = ents.add_group
grp.name = name
bw = bw_mm * 0.5; tw = tw_mm * 0.5
pb = [Geom::Point3d.new(mm(-bw), mm(-bw), 0), Geom::Point3d.new(mm(bw), mm(-bw), 0), Geom::Point3d.new(mm(bw), mm(bw), 0), Geom::Point3d.new(mm(-bw), mm(bw), 0)]
pt = [Geom::Point3d.new(mm(-tw), mm(-tw), mm(h_mm)), Geom::Point3d.new(mm(tw), mm(-tw), mm(h_mm)), Geom::Point3d.new(mm(tw), mm(tw), mm(h_mm)), Geom::Point3d.new(mm(-tw), mm(tw), mm(h_mm))]
grp.entities.add_face(pb)
grp.entities.add_face(pt)
4.times { |i| grp.entities.add_face([pb[i], pb[(i + 1) % 4], pt[(i + 1) % 4], pt[i]]) }
grp.entities.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
grp.material = mat if mat
grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(x_m.m, y_m.m, z_m.m)))
grp
end
def revolve_open_hollow_mesh(ents, name, profile, mat, segs = 36, scale_y = 1.0)
grp = ents.add_group
grp.name = name
mesh = Geom::PolygonMesh.new
rings = profile.map do |rad, z|
r = rad.to_f
(0...segs).map do |i|
a = 2.0 * Math::PI * i.to_f / segs
mesh.add_point(Geom::Point3d.new(mm(r * Math.cos(a)), mm(r * scale_y.to_f * Math.sin(a)), mm(z.to_f)))
end
end
(0...(rings.length - 1)).each do |ri|
r1 = profile[ri][0].to_f; r2 = profile[ri + 1][0].to_f
next if r1 <= 0.001 && r2 <= 0.001
segs.times do |i|
j = (i + 1) % segs
idx00 = rings[ri][i]; idx01 = rings[ri][j]; idx11 = rings[ri + 1][j]; idx10 = rings[ri + 1][i]
if r1 <= 0.001
mesh.add_polygon(idx00, idx11, idx10)
elsif r2 <= 0.001
mesh.add_polygon(idx00, idx01, idx10)
else
mesh.add_polygon(idx00, idx01, idx11)
mesh.add_polygon(idx00, idx11, idx10)
end
end
end
grp.entities.fill_from_mesh(mesh, true, 12, mat, mat)
grp.material = mat if mat
grp
end
def add_inflated_pillow_mesh(ents, name, cx_m, cy_m, cz_m, w_mm, d_mm, h_mm, rot_z_deg, vertical, mat)
grp = ents.add_group
grp.name = name
nx = 14; ny = 10
mesh = Geom::PolygonMesh.new
top = []; bot = []
(0..nx).each do |i|
u = i.to_f / nx
tr = []; br = []
(0..ny).each do |j|
v = j.to_f / ny
dome = (Math.sin(Math::PI * u).abs ** 0.44) * (Math.sin(Math::PI * v).abs ** 0.44)
px = (u - 0.5) * w_mm.to_f
py = (v - 0.5) * d_mm.to_f
tr << mesh.add_point(Geom::Point3d.new(mm(px), mm(py), mm(h_mm.to_f * (0.12 + 0.88 * dome))))
br << mesh.add_point(Geom::Point3d.new(mm(px), mm(py), mm(-h_mm.to_f * 0.08 * dome)))
end
top << tr; bot << br
end
nx.times do |i|
ny.times do |j|
mesh.add_polygon(top[i][j], top[i + 1][j], top[i + 1][j + 1])
mesh.add_polygon(top[i][j], top[i + 1][j + 1], top[i][j + 1])
mesh.add_polygon(bot[i][j], bot[i][j + 1], bot[i + 1][j + 1])
mesh.add_polygon(bot[i][j], bot[i + 1][j + 1], bot[i + 1][j])
end
end
grp.entities.fill_from_mesh(mesh, true, 12, mat, mat)
grp.material = mat if mat
rx = vertical ? Geom::Transformation.rotation(ORIGIN, X_AXIS, -82.degrees) : Geom::Transformation.new
rz = Geom::Transformation.rotation(ORIGIN, Z_AXIS, rot_z_deg.to_f.degrees)
tr = Geom::Transformation.translation(Geom::Vector3d.new(cx_m.m, cy_m.m, cz_m.m))
grp.transform!(tr * rz * rx)
grp
end
def add_luxury_tiled_floor(parent_ents, name, x1, y1, x2, y2, z_base, z_top, tile_w, tile_d, mat_primary, _mat_alt, mat_grout, _border_w = 0.0, _mat_border = nil, _add_veins = false)
f_grp = parent_ents.add_group
f_grp.name = name
# #region agent log
agent_record_box(name, x1, y1, x2, y2, z_base, z_top, 'floor')
# #endregion
fe = f_grp.entities
xmin, xmax = [x1, x2].minmax
ymin, ymax = [y1, y2].minmax
grout_t = 0.003
z_grout = z_top - 0.002
add_box(fe, xmin, ymin, xmax, ymax, z_base, z_grout, mat_grout)
cx = xmin
while cx < xmax - 0.02
nx = [cx + tile_w, xmax].min
cy = ymin
while cy < ymax - 0.02
ny = [cy + tile_d, ymax].min
ax1 = cx + grout_t * 0.5; ax2 = nx - grout_t * 0.5
ay1 = cy + grout_t * 0.5; ay2 = ny - grout_t * 0.5
if (ax2 - ax1) > 0.02 && (ay2 - ay1) > 0.02
t_face = fe.add_face(
Geom::Point3d.new(ax1.m, ay1.m, z_grout.m),
Geom::Point3d.new(ax2.m, ay1.m, z_grout.m),
Geom::Point3d.new(ax2.m, ay2.m, z_grout.m),
Geom::Point3d.new(ax1.m, ay2.m, z_grout.m)
)
if t_face
t_face.reverse! if t_face.normal.z < 0
face_mat(t_face, mat_primary)
t_face.pushpull((z_top - z_grout).m)
end
end
cy = ny
end
cx = nx
end
fe.grep(Sketchup::Face).each { |f| face_mat(f, mat_primary) if (f.bounds.max.z - z_top.m).abs < 1e-3.m }
f_grp
end
def add_luxury_plank_floor(parent_ents, name, x1, y1, x2, y2, z_base, z_top, plank_w, plank_l, mat_plank, mat_bevel)
f_grp = parent_ents.add_group
f_grp.name = name
agent_record_box(name, x1, y1, x2, y2, z_base, z_top, 'floor')
fe = f_grp.entities
xmin, xmax = [x1, x2].minmax
ymin, ymax = [y1, y2].minmax
grout_t = 0.0015
z_grout = z_top - 0.002
add_box(fe, xmin, ymin, xmax, ymax, z_base, z_grout, mat_bevel)
row = 0
cy = ymin
while cy < ymax - 0.01
ny = [cy + plank_w, ymax].min
offset = (row.odd? ? plank_l * 0.5 : 0.0)
cx = xmin - offset
while cx < xmax - 0.01
nx = [cx + plank_l, xmax].min
ax1 = [cx, xmin].max + grout_t * 0.5
ax2 = [nx, xmax].min - grout_t * 0.5
ay1 = cy + grout_t * 0.5
ay2 = ny - grout_t * 0.5
if (ax2 - ax1) > 0.04 && (ay2 - ay1) > 0.02
t_face = fe.add_face(
Geom::Point3d.new(ax1.m, ay1.m, z_grout.m),
Geom::Point3d.new(ax2.m, ay1.m, z_grout.m),
Geom::Point3d.new(ax2.m, ay2.m, z_grout.m),
Geom::Point3d.new(ax1.m, ay2.m, z_grout.m)
)
if t_face
t_face.reverse! if t_face.normal.z < 0
face_mat(t_face, mat_plank)
t_face.pushpull((z_top - z_grout).m)
end
end
cx = nx
end
cy = ny
row += 1
end
fe.grep(Sketchup::Face).each { |f| face_mat(f, mat_plank) if (f.bounds.max.z - z_top.m).abs < 1e-3.m }
f_grp
end
def weld_groups_into_monolithic_shell!(parent_grp, sub_groups, mat, hide_z_planes = [], hide_y_planes = [], hide_x_planes = [])
valid = sub_groups.compact.reject(&:deleted?)
return if valid.empty?
valid.each { |g| g.explode unless g.deleted? }
pe = parent_grp.entities
xform = Geom::Transformation.new
pe.intersect_with(false, xform, pe, xform, false, pe.to_a)
2.times do
pe.grep(Sketchup::Edge).to_a.each do |e|
next if e.deleted?
if e.faces.length == 2
f1, f2 = e.faces
e.erase! if f1.normal.parallel?(f2.normal) && f1.normal.samedirection?(f2.normal)
end
end
pe.grep(Sketchup::Face).to_a.each { |f| f.erase! if !f.deleted? && f.edges.all? { |e| e.faces.length > 2 } }
pe.grep(Sketchup::Edge).to_a.each { |e| e.erase! if !e.deleted? && e.faces.empty? }
end
pe.grep(Sketchup::Edge).each do |e|
next if e.deleted?
p1 = e.start.position; p2 = e.end.position
hide_z_planes.each { |zv| (e.soft = true; e.smooth = true; e.hidden = true) if (p1.z - zv.m).abs < 3e-3.m && (p2.z - zv.m).abs < 3e-3.m }
hide_y_planes.each { |yv| (e.soft = true; e.smooth = true; e.hidden = true) if (p1.y - yv.m).abs < 3e-3.m && (p2.y - yv.m).abs < 3e-3.m }
hide_x_planes.each { |xv| (e.soft = true; e.smooth = true; e.hidden = true) if (p1.x - xv.m).abs < 3e-3.m && (p2.x - xv.m).abs < 3e-3.m }
end
parent_grp.material = mat
pe.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
end
def add_rosette_plant(parent_ents, name, cx, cy, z_base, radius, height)
p_grp = parent_ents.add_group; p_grp.name = name; pe = p_grp.entities
[[7, radius, height * 0.72, 22, M_LEAF_DARK, 0.0], [5, radius * 0.68, height, 48, M_LEAF_LIME, 25.0]].each do |(num_leaves, r_len, l_h, pitch_deg, mat, phase_deg)|
num_leaves.times do |i|
ang_deg = i * (360.0 / num_leaves) + phase_deg
leaf = pe.add_group; le = leaf.entities
w_base = r_len * 0.14; w_mid = r_len * 0.24
p1 = Geom::Point3d.new(0.02.m, -w_base.m, (l_h * 0.05).m)
p2 = Geom::Point3d.new((r_len * 0.55).m, -w_mid.m, (l_h * 0.35).m)
p3 = Geom::Point3d.new(r_len.m, 0, (l_h * 0.18).m)
p4 = Geom::Point3d.new((r_len * 0.55).m, w_mid.m, (l_h * 0.35).m)
p5 = Geom::Point3d.new(0.02.m, w_base.m, (l_h * 0.05).m)
f1 = le.add_face(p1, p2, p4, p5); f2 = le.add_face(p2, p3, p4)
f1.pushpull(0.015.m) if f1; f2.pushpull(0.010.m) if f2
leaf.material = mat
tr = Geom::Transformation.translation(Geom::Vector3d.new(cx.m, cy.m, z_base.m)) *
Geom::Transformation.rotation(ORIGIN, Z_AXIS, ang_deg.degrees) *
Geom::Transformation.rotation(ORIGIN, Y_AXIS, (-pitch_deg * 0.30).degrees)
leaf.transform!(tr)
end
end
end
def add_trimmed_hedge(parent_ents, name, x1, y1, x2, y2, z_base, height)
h_grp = parent_ents.add_group; h_grp.name = name; he = h_grp.entities
add_box(he, x1 + 0.04, y1 + 0.04, x2 - 0.04, y2 - 0.04, z_base, z_base + 0.08, M_PALM_TRUNK)
add_box(he, x1, y1, x2, y2, z_base + 0.08, z_base + height * 0.78, M_LEAF_DARK)
add_box(he, x1 + 0.03, y1 + 0.03, x2 - 0.03, y2 - 0.03, z_base + height * 0.78, z_base + height * 0.92, M_LEAF_MID)
add_box(he, x1 + 0.06, y1 + 0.06, x2 - 0.06, y2 - 0.06, z_base + height * 0.92, z_base + height, M_LEAF_LIME)
end
def add_realistic_palm_tree(parent_ents, name, cx, cy, z_base, trunk_h, max_radius = 0.46)
t_grp = parent_ents.add_group; t_grp.name = name; te = t_grp.entities
[[0.0, 0.0, 1.0, 0.0], [-0.05, 0.04, 0.76, 15.0], [0.05, -0.04, 0.56, 30.0]].each do |(ox, oy, scale_h, phase_deg)|
th = trunk_h * scale_h
6.times do |i|
t1 = i / 6.0; t2 = (i + 1) / 6.0
r = 0.065 * (1.0 - 0.30 * t1)
dx = ox * (1.0 + 0.8 * t1); dy = oy * (1.0 + 0.8 * t1)
add_box(te, cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r, z_base + t1 * th, z_base + t2 * th, M_PALM_TRUNK)
end
top_x = cx + ox * 1.8; top_y = cy + oy * 1.8; top_z = z_base + th
add_box(te, top_x - 0.045, top_y - 0.045, top_x + 0.045, top_y + 0.045, top_z - 0.04, top_z + 0.16, M_LEAF_MID)
8.times do |f_idx|
upper_tier = f_idx.even?
ang_deg = f_idx * 45.0 + phase_deg
frond_len = (upper_tier ? max_radius * 0.86 : max_radius) * (0.75 + 0.25 * scale_h)
arch_h = (upper_tier ? 0.24 : 0.12) * scale_h
f_grp = te.add_group; fe = f_grp.entities
s1 = frond_len * 0.40; s2 = frond_len * 0.76; s3 = frond_len
w1 = 0.08 * scale_h; w2 = 0.11 * scale_h
f1 = fe.add_face(Geom::Point3d.new(0.03.m, -0.02.m, 0.08.m), Geom::Point3d.new(s1.m, -w1.m, (0.08 + arch_h).m), Geom::Point3d.new(s1.m, w1.m, (0.08 + arch_h).m), Geom::Point3d.new(0.03.m, 0.02.m, 0.08.m))
f1.pushpull(0.012.m) if f1
f2 = fe.add_face(Geom::Point3d.new(s1.m, -w1.m, (0.08 + arch_h).m), Geom::Point3d.new(s2.m, -w2.m, (0.04 + arch_h * 0.45).m), Geom::Point3d.new(s2.m, w2.m, (0.04 + arch_h * 0.45).m), Geom::Point3d.new(s1.m, w1.m, (0.08 + arch_h).m))
f2.pushpull(0.010.m) if f2
f3 = fe.add_face(Geom::Point3d.new(s2.m, -w2.m, (0.04 + arch_h * 0.45).m), Geom::Point3d.new(s3.m, 0, (-0.12 * scale_h).m), Geom::Point3d.new(s2.m, w2.m, (0.04 + arch_h * 0.45).m))
f3.pushpull(0.008.m) if f3
f_grp.material = (upper_tier ? M_LEAF_LIME : M_LEAF_DARK)
f_grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(top_x.m, top_y.m, top_z.m)) * Geom::Transformation.rotation(ORIGIN, Z_AXIS, ang_deg.degrees))
end
end
end
def add_curtain_unit(parent_ents, id, horizontal, fixed_coord, interior_dir, r1, r2, z_bot, z_top, wall_t)
c_grp = parent_ents.add_group; c_grp.name = "Curtain_#{id}"; ce = c_grp.entities
pos_c = fixed_coord + interior_dir * (wall_t / 2.0 + 0.045)
panel_w = [(r2 - r1).abs * 0.30, 0.50].min
if horizontal
add_box(ce, r1 - 0.04, pos_c - 0.012, r2 + 0.04, pos_c + 0.012, z_top, z_top + 0.022, M_METAL_BLK)
else
add_box(ce, pos_c - 0.012, r1 - 0.04, pos_c + 0.012, r2 + 0.04, z_top, z_top + 0.022, M_METAL_BLK)
end
[[r1 - 0.01, r1 + panel_w], [r2 - panel_w, r2 + 0.01]].each_with_index do |(p_start, p_end), idx|
p_grp = ce.add_group; p_grp.name = "#{id}_Drapery_#{idx + 1}"; pe = p_grp.entities
steps = 12; front_pts = []; back_pts = []
(0..steps).each do |i|
t = i.to_f / steps
s = p_start + t * (p_end - p_start)
cf = pos_c + 0.024 * Math.sin(t * 3.5 * 2.0 * Math::PI)
cb = cf + interior_dir * 0.015
front_pts << (horizontal ? Geom::Point3d.new(s.m, cf.m, z_bot.m) : Geom::Point3d.new(cf.m, s.m, z_bot.m))
back_pts << (horizontal ? Geom::Point3d.new(s.m, cb.m, z_bot.m) : Geom::Point3d.new(cb.m, s.m, z_bot.m))
end
face = pe.add_face(front_pts + back_pts.reverse)
if face
face.reverse! if face.normal.z < 0
face.pushpull((z_top - z_bot).m)
end
pe.grep(Sketchup::Edge).each { |e| (e.soft = true; e.smooth = true) if (e.start.position.z - e.end.position.z).abs > 0.4.m }
p_grp.material = M_CURTAIN
end
end
def add_openable_casement_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t)
w_grp = parent_ents.add_group
w_grp.name = "Window_#{id}"
we = w_grp.entities
f = 0.035
s = 0.025
depth = [wall_t + 0.02, 0.12].min
middle = (r1 + r2) / 2.0
if horizontal
ya = fixed_coord - depth / 2.0
yb = fixed_coord + depth / 2.0
add_box(we, r1, ya, r2, yb, z1, z1 + f, M_METAL_BLK)
add_box(we, r1, ya, r2, yb, z2 - f, z2, M_METAL_BLK)
add_box(we, r1, ya, r1 + f, yb, z1 + f, z2 - f, M_METAL_BLK)
add_box(we, r2 - f, ya, r2, yb, z1 + f, z2 - f, M_METAL_BLK)
else
xa = fixed_coord - depth / 2.0
xb = fixed_coord + depth / 2.0
add_box(we, xa, r1, xb, r2, z1, z1 + f, M_METAL_BLK)
add_box(we, xa, r1, xb, r1 + f, z1 + f, z2 - f, M_METAL_BLK)
add_box(we, xa, r2 - f, xb, r2, z1 + f, z2 - f, M_METAL_BLK)
add_box(we, xa, r1, xb, r2, z2 - f, z2, M_METAL_BLK)
end
[[r1 + f + 0.003, middle - 0.010, 1], [middle + 0.010, r2 - f - 0.003, -1]].each_with_index do |(a, b, side), idx|
leaf = we.add_group
leaf.name = "#{id}_Operable_Outward_Casement_#{idx + 1}"
e = leaf.entities
if horizontal
add_box(e, a, fixed_coord - 0.016, b, fixed_coord + 0.016, z1 + f, z1 + f + s, M_METAL_BLK)
add_box(e, a, fixed_coord - 0.016, b, fixed_coord + 0.016, z2 - f - s, z2 - f, M_METAL_BLK)
add_box(e, a, fixed_coord - 0.016, a + s, fixed_coord + 0.016, z1 + f + s, z2 - f - s, M_METAL_BLK)
add_box(e, b - s, fixed_coord - 0.016, b, fixed_coord + 0.016, z1 + f + s, z2 - f - s, M_METAL_BLK)
add_box(e, a + s, fixed_coord - 0.006, b - s, fixed_coord + 0.006, z1 + f + s, z2 - f - s, M_GLASS)
add_box(e, (side == 1 ? b - 0.037 : a + 0.027), fixed_coord - 0.026, (side == 1 ? b - 0.027 : a + 0.037), fixed_coord - 0.006, z1 + 0.22, z1 + 0.34, M_CHROME)
hinge = Geom::Point3d.new((side == 1 ? a : b).m, fixed_coord.m, z1.m)
else
add_box(e, fixed_coord - 0.016, a, fixed_coord + 0.016, b, z1 + f, z1 + f + s, M_METAL_BLK)
add_box(e, fixed_coord - 0.016, a, fixed_coord + 0.016, b, z2 - f - s, z2 - f, M_METAL_BLK)
add_box(e, fixed_coord - 0.016, a, fixed_coord + 0.016, a + s, z1 + f + s, z2 - f - s, M_METAL_BLK)
add_box(e, fixed_coord - 0.016, b - s, fixed_coord + 0.016, b, z1 + f + s, z2 - f - s, M_METAL_BLK)
add_box(e, fixed_coord - 0.006, a + s, fixed_coord + 0.006, b - s, z1 + f + s, z2 - f - s, M_GLASS)
add_box(e, fixed_coord + 0.006, (side == 1 ? b - 0.037 : a + 0.027), fixed_coord + 0.026, (side == 1 ? b - 0.027 : a + 0.037), z1 + 0.85, z1 + 0.97, M_CHROME)
hinge = Geom::Point3d.new(fixed_coord.m, (side == 1 ? a : b).m, z1.m)
end
display_angle = id == 'W3' ? 16.0 : (id == 'W5' ? 0.0 : 88.0)
outward_sign = id == 'W3' ? -side : (horizontal && id == 'W5' ? -side : side)
leaf.transform!(Geom::Transformation.rotation(hinge, Z_AXIS, (outward_sign * display_angle).degrees))
leaf.set_attribute('Opening', 'type', id == 'W3' ? 'inward casement with exterior security grille' : 'outward casement')
leaf.set_attribute('Opening', 'display_angle_degrees', display_angle)
leaf.set_attribute('Opening', 'maximum_open_angle_degrees', 88.0)
end
net = [r2 - r1 - 2.0 * f - 0.020 - 4.0 * s, 0.0].max * [z2 - z1 - 2.0 * f - 2.0 * s, 0.0].max
w_grp.set_attribute('Ventilation', 'full_open_estimated_clear_m2', net.round(3))
w_grp.set_attribute('Ventilation', 'assumption', id == 'W3' ? 'Inward-operating casements with interior-release exterior security grille. Actual net free opening at the selected opening angle and site eligibility must be checked.' : 'Two outward-opening casements; exterior clearance, orientation and local approvals must be verified')
if id == 'W3'
  security = we.add_group
  security.name = 'W3_Hinged_Exterior_Security_Grille_Interior_Quick_Release'
  steel = security.entities
  gx1 = fixed_coord - wall_t / 2.0 - 0.032
  gx2 = gx1 + 0.028
  rail = 0.027
  add_box(steel, gx1, r1, gx2, r1 + rail, z1, z2, M_METAL_BLK, 'Security_Anchor_Left')
  add_box(steel, gx1, r2 - rail, gx2, r2, z1, z2, M_METAL_BLK, 'Security_Anchor_Right')
  add_box(steel, gx1, r1 + rail, gx2, r2 - rail, z1, z1 + rail, M_METAL_BLK, 'Security_Anchor_Bottom')
  add_box(steel, gx1, r1 + rail, gx2, r2 - rail, z2 - rail, z2, M_METAL_BLK, 'Security_Anchor_Top')
  gate = steel.add_group
  gate.name = 'Hinged_Grille_Gate_Closed_Position'
  bars = gate.entities
  bar_t = 0.014
  inner1 = r1 + rail + 0.012
  inner2 = r2 - rail - 0.012
  add_box(bars, gx1 - 0.004, inner1 - bar_t, gx1 + 0.012, inner1, z1 + rail, z2 - rail, M_METAL_BLK, 'Grille_Gate_Left')
  add_box(bars, gx1 - 0.004, inner2, gx1 + 0.012, inner2 + bar_t, z1 + rail, z2 - rail, M_METAL_BLK, 'Grille_Gate_Right')
  add_box(bars, gx1 - 0.004, inner1, gx1 + 0.012, inner2, z1 + rail, z1 + rail + bar_t, M_METAL_BLK, 'Grille_Gate_Bottom')
  add_box(bars, gx1 - 0.004, inner1, gx1 + 0.012, inner2, z2 - rail - bar_t, z2 - rail, M_METAL_BLK, 'Grille_Gate_Top')
  12.times do |i|
    yy = inner1 + (inner2 - inner1) * (i + 1).to_f / 13.0
    add_box(bars, gx1 - 0.004, yy - bar_t / 2.0, gx1 + 0.012, yy + bar_t / 2.0, z1 + rail, z2 - rail, M_METAL_BLK, "Security_Vertical_#{i + 1}")
  end
  [z1 + 0.49, z2 - 0.49].each_with_index do |zz, i|
    add_box(bars, gx1 - 0.006, inner1, gx1 + 0.012, inner2, zz - 0.009, zz + 0.009, M_METAL_BLK, "Security_Stiffener_#{i + 1}")
  end
  [z1 + 0.21, z2 - 0.21].each_with_index do |zz, i|
    add_box(steel, gx1 - 0.010, r1 + rail - 0.012, gx1 + 0.020, r1 + rail + 0.016, zz - 0.035, zz + 0.035, M_CHROME, "Grille_Hinge_#{i + 1}")
  end
  add_box(steel, gx1 + 0.006, r2 - 0.086, gx1 + 0.033, r2 - 0.052, z1 + 0.72, z1 + 0.84, M_CHROME, 'Grille_Exterior_Latch')
  add_box(steel, fixed_coord + wall_t / 2.0 + 0.010, r2 - 0.085, fixed_coord + wall_t / 2.0 + 0.030, r2 - 0.050, z1 + 0.73, z1 + 0.86, M_BRASS, 'Interior_Manual_Emergency_Release_Concept')
  security.set_attribute('Security', 'specification', 'Fabricated steel grille, hinged gate, tamper-resistant exterior and tool-free interior emergency release; conceptual, not field certified')
  security.set_attribute('Security', 'maximum_clear_bar_spacing_m', (((inner2 - inner1) / 13.0) - bar_t).round(3))
  security.set_attribute('Security', 'site_installation', 'Confirm fire escape, anchorage, releases, outward conditions and fabricator design with licensed professionals')
  w_grp.set_attribute('Glazing', 'security_specification', 'Specify certified laminated security glazing and multipoint lock during fabrication; material is conceptual')
  w_grp.set_attribute('Ventilation', 'preliminary_grille_clear_area_m2', (((inner2 - inner1) - 12 * bar_t) * ((z2 - z1 - 2 * rail) - 2 * 0.018)).round(3))
  w_grp.set_attribute('Ventilation', 'warning', 'Grille clearance alone is not code-compliant net openable area. Confirm angle of sashes, exterior air, other openings and setbacks.')
end
w_grp
end
def add_sliding_window_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir = 1, panels = 2)
w_grp = parent_ents.add_group
w_grp.name = "Window_#{id}"
we = w_grp.entities
ft = 0.040
st = 0.024
fd = [wall_t + 0.02, 0.12].min
panel_count = [panels, 2].max
span = (r2 - r1) / panel_count.to_f
track_gap = 0.018
if horizontal
ya = fixed_coord - fd / 2.0
yb = fixed_coord + fd / 2.0
add_box(we, r1, ya, r2, yb, z1, z1 + ft, M_METAL_BLK)
add_box(we, r1, ya, r2, yb, z2 - ft, z2, M_METAL_BLK)
add_box(we, r1, ya, r1 + ft, yb, z1 + ft, z2 - ft, M_METAL_BLK)
add_box(we, r2 - ft, ya, r2, yb, z1 + ft, z2 - ft, M_METAL_BLK)
add_box(we, r1 + ft, fixed_coord - 0.008, r2 - ft, fixed_coord + 0.008, z1 + 0.022, z1 + 0.030, M_METAL_BLK)
(0...panel_count).each do |i|
  a = r1 + i * span + ft * 0.5
  b = r1 + (i + 1) * span - ft * 0.5
  offset = i.even? ? -track_gap * 0.5 : track_gap * 0.5
  add_box(we, a, fixed_coord - st + offset, b, fixed_coord + st + offset, z1 + ft, z1 + ft + st, M_METAL_BLK)
  add_box(we, a, fixed_coord - st + offset, b, fixed_coord + st + offset, z2 - ft - st, z2 - ft, M_METAL_BLK)
  add_box(we, a, fixed_coord - st + offset, a + st, fixed_coord + st + offset, z1 + ft + st, z2 - ft - st, M_METAL_BLK)
  add_box(we, b - st, fixed_coord - st + offset, b, fixed_coord + st + offset, z1 + ft + st, z2 - ft - st, M_METAL_BLK)
  add_box(we, a + st, fixed_coord - 0.005 + offset, b - st, fixed_coord + 0.005 + offset, z1 + ft + st, z2 - ft - st, M_GLASS)
  hx = (a + b) * 0.5
  add_box(we, hx - 0.026, fixed_coord - 0.012 + offset, hx + 0.026, fixed_coord + 0.012 + offset, (z1 + z2) * 0.5 - 0.055, (z1 + z2) * 0.5 + 0.055, M_CHROME)
end
else
xa = fixed_coord - fd / 2.0
xb = fixed_coord + fd / 2.0
add_box(we, xa, r1, xb, r2, z1, z1 + ft, M_METAL_BLK)
add_box(we, xa, r1, xb, r2, z2 - ft, z2, M_METAL_BLK)
add_box(we, xa, r1, xb, r1 + ft, z1 + ft, z2 - ft, M_METAL_BLK)
add_box(we, xa, r2 - ft, xb, r2, z1 + ft, z2 - ft, M_METAL_BLK)
add_box(we, fixed_coord - 0.008, r1 + ft, fixed_coord + 0.008, r2 - ft, z1 + 0.022, z1 + 0.030, M_METAL_BLK)
(0...panel_count).each do |i|
  a = r1 + i * span + ft * 0.5
  b = r1 + (i + 1) * span - ft * 0.5
  offset = i.even? ? -track_gap * 0.5 : track_gap * 0.5
  add_box(we, fixed_coord - st + offset, a, fixed_coord + st + offset, b, z1 + ft, z1 + ft + st, M_METAL_BLK)
  add_box(we, fixed_coord - st + offset, a, fixed_coord + st + offset, b, z2 - ft - st, z2 - ft, M_METAL_BLK)
  add_box(we, fixed_coord - st + offset, a, fixed_coord + st + offset, a + st, z1 + ft + st, z2 - ft - st, M_METAL_BLK)
  add_box(we, fixed_coord - st + offset, b - st, fixed_coord + st + offset, b, z1 + ft + st, z2 - ft - st, M_METAL_BLK)
  add_box(we, fixed_coord - 0.005 + offset, a + st, fixed_coord + 0.005 + offset, b - st, z1 + ft + st, z2 - ft - st, M_GLASS)
  hz = (z1 + z2) * 0.5
  add_box(we, fixed_coord - 0.012 + offset, (a + b) * 0.5 - 0.026, fixed_coord + 0.012 + offset, (a + b) * 0.5 + 0.026, hz - 0.055, hz + 0.055, M_CHROME)
end
end
w_grp.set_attribute('Opening', 'type', 'sliding window')
w_grp
end

def add_awning_window_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir = 1, panels = 2)
w_grp = parent_ents.add_group
w_grp.name = "Window_#{id}"
we = w_grp.entities
ft = 0.040
st = 0.024
fd = [wall_t + 0.02, 0.12].min
columns = id == 'W_2F_Center' ? 3 : (['W2', 'W_TB2_Rear'].include?(id) ? 1 : [panels.to_i, 1].max)
rows = ['W3', 'W_2F_Center'].include?(id) ? 3 : (id == 'W_Fam_Rear' ? 2 : 1)
glass_mat = M_GLASS
if ['W2', 'W_TB2_Rear'].include?(id)
  glass_mat = Sketchup.active_model.materials['Window_Obscure_Frosted_Glass'] || Sketchup.active_model.materials.add('Window_Obscure_Frosted_Glass')
  glass_mat.color = Sketchup::Color.new(211, 226, 231)
  glass_mat.alpha = 0.96
end
span = (r2 - r1) / columns.to_f
row_h = (z2 - z1 - 2 * ft) / rows.to_f
if horizontal
  a0 = fixed_coord - fd / 2.0
  b0 = fixed_coord + fd / 2.0
  add_box(we, r1, a0, r2, b0, z1, z1 + ft, M_METAL_BLK)
  add_box(we, r1, a0, r2, b0, z2 - ft, z2, M_METAL_BLK)
  add_box(we, r1, a0, r1 + ft, b0, z1 + ft, z2 - ft, M_METAL_BLK)
  add_box(we, r2 - ft, a0, r2, b0, z1 + ft, z2 - ft, M_METAL_BLK)
  (1...columns).each do |i|
    c = r1 + i * span
    add_box(we, c - ft / 2, a0, c + ft / 2, b0, z1 + ft, z2 - ft, M_METAL_BLK)
  end
  (1...rows).each do |i|
    z = z1 + ft + i * row_h
    add_box(we, r1 + ft, a0, r2 - ft, b0, z - ft / 2, z + ft / 2, M_METAL_BLK)
  end
  (0...rows).each do |row|
    lower = z1 + ft + row * row_h + (row == 0 ? 0.006 : ft / 2 + 0.006)
    upper = z1 + ft + (row + 1) * row_h - (row == rows - 1 ? 0.006 : ft / 2 + 0.006)
    (0...columns).each do |col|
      left = r1 + col * span + (col == 0 ? ft : ft / 2) + 0.006
      right = r1 + (col + 1) * span - (col == columns - 1 ? ft : ft / 2) - 0.006
      sash = we.add_group
      sash.name = "#{id}_Awning_Row_#{row + 1}_Panel_#{col + 1}"
      e = sash.entities
      add_box(e, left, fixed_coord - st, right, fixed_coord + st, lower, lower + st, M_METAL_BLK)
      add_box(e, left, fixed_coord - st, right, fixed_coord + st, upper - st, upper, M_METAL_BLK)
      add_box(e, left, fixed_coord - st, left + st, fixed_coord + st, lower + st, upper - st, M_METAL_BLK)
      add_box(e, right - st, fixed_coord - st, right, fixed_coord + st, lower + st, upper - st, M_METAL_BLK)
      add_box(e, left + st, fixed_coord - 0.005, right - st, fixed_coord + 0.005, lower + st, upper - st, glass_mat)
      center = (left + right) * 0.5
      add_box(e, center - 0.027, fixed_coord - 0.012, center + 0.027, fixed_coord + 0.016, lower + 0.036, lower + 0.098, M_CHROME)
      hinge = Geom::Point3d.new(left.m, fixed_coord.m, upper.m)
      sash.transform!(Geom::Transformation.rotation(hinge, X_AXIS, (-interior_dir * 18.0).degrees))
      sash.set_attribute('Opening', 'type', 'top-hinged awning')
      sash.set_attribute('Opening', 'display_angle_degrees', 18.0)
    end
  end
else
  a0 = fixed_coord - fd / 2.0
  b0 = fixed_coord + fd / 2.0
  add_box(we, a0, r1, b0, r2, z1, z1 + ft, M_METAL_BLK)
  add_box(we, a0, r1, b0, r2, z2 - ft, z2, M_METAL_BLK)
  add_box(we, a0, r1, b0, r1 + ft, z1 + ft, z2 - ft, M_METAL_BLK)
  add_box(we, a0, r2 - ft, b0, r2, z1 + ft, z2 - ft, M_METAL_BLK)
  (1...columns).each do |i|
    c = r1 + i * span
    add_box(we, a0, c - ft / 2, b0, c + ft / 2, z1 + ft, z2 - ft, M_METAL_BLK)
  end
  (1...rows).each do |i|
    z = z1 + ft + i * row_h
    add_box(we, a0, r1 + ft, b0, r2 - ft, z - ft / 2, z + ft / 2, M_METAL_BLK)
  end
  (0...rows).each do |row|
    lower = z1 + ft + row * row_h + (row == 0 ? 0.006 : ft / 2 + 0.006)
    upper = z1 + ft + (row + 1) * row_h - (row == rows - 1 ? 0.006 : ft / 2 + 0.006)
    (0...columns).each do |col|
      left = r1 + col * span + (col == 0 ? ft : ft / 2) + 0.006
      right = r1 + (col + 1) * span - (col == columns - 1 ? ft : ft / 2) - 0.006
      sash = we.add_group
      sash.name = "#{id}_Awning_Row_#{row + 1}_Panel_#{col + 1}"
      e = sash.entities
      add_box(e, fixed_coord - st, left, fixed_coord + st, right, lower, lower + st, M_METAL_BLK)
      add_box(e, fixed_coord - st, left, fixed_coord + st, right, upper - st, upper, M_METAL_BLK)
      add_box(e, fixed_coord - st, left, fixed_coord + st, left + st, lower + st, upper - st, M_METAL_BLK)
      add_box(e, fixed_coord - st, right - st, fixed_coord + st, right, lower + st, upper - st, M_METAL_BLK)
      add_box(e, fixed_coord - 0.005, left + st, fixed_coord + 0.005, right - st, lower + st, upper - st, glass_mat)
      center = (left + right) * 0.5
      add_box(e, fixed_coord - 0.016, center - 0.027, fixed_coord + 0.012, center + 0.027, lower + 0.036, lower + 0.098, M_CHROME)
      hinge = Geom::Point3d.new(fixed_coord.m, left.m, upper.m)
      sash.transform!(Geom::Transformation.rotation(hinge, Y_AXIS, (interior_dir * 18.0).degrees))
      sash.set_attribute('Opening', 'type', 'top-hinged awning')
      sash.set_attribute('Opening', 'display_angle_degrees', 18.0)
    end
  end
end
w_grp.set_attribute('Opening', 'type', 'awning window')
w_grp.set_attribute('Opening', 'stack_rows', rows)
w_grp.set_attribute('Opening', 'columns', columns)
w_grp.set_attribute('Glazing', 'privacy', 'obscure frosted') if ['W2', 'W_TB2_Rear'].include?(id)
w_grp
end

def add_fine_mosquito_screen(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir)
  sg = parent_ents.add_group
  sg.name = "#{id}_Removable_Mosquito_Screen"
  se = sg.entities
  pad = 0.015
  rail = 0.009
  depth = 0.004
  plane = fixed_coord + interior_dir * (wall_t * 0.5 + 0.022)
  a = r1 + pad
  b = r2 - pad
  low = z1 + pad
  high = z2 - pad
  return sg if b <= a || high <= low
  if horizontal
    add_box(se, a, plane - depth, b, plane + depth, low, low + rail, M_METAL_BLK)
    add_box(se, a, plane - depth, b, plane + depth, high - rail, high, M_METAL_BLK)
    add_box(se, a, plane - depth, a + rail, plane + depth, low, high, M_METAL_BLK)
    add_box(se, b - rail, plane - depth, b, plane + depth, low, high, M_METAL_BLK)
    sf = se.add_face([Geom::Point3d.new((a + rail).m, plane.m, (low + rail).m), Geom::Point3d.new((b - rail).m, plane.m, (low + rail).m), Geom::Point3d.new((b - rail).m, plane.m, (high - rail).m), Geom::Point3d.new((a + rail).m, plane.m, (high - rail).m)])
  else
    add_box(se, plane - depth, a, plane + depth, b, low, low + rail, M_METAL_BLK)
    add_box(se, plane - depth, a, plane + depth, b, high - rail, high, M_METAL_BLK)
    add_box(se, plane - depth, a, plane + depth, a + rail, low, high, M_METAL_BLK)
    add_box(se, plane - depth, b - rail, plane + depth, b, low, high, M_METAL_BLK)
    sf = se.add_face([Geom::Point3d.new(plane.m, (a + rail).m, (low + rail).m), Geom::Point3d.new(plane.m, (b - rail).m, (low + rail).m), Geom::Point3d.new(plane.m, (b - rail).m, (high - rail).m), Geom::Point3d.new(plane.m, (a + rail).m, (high - rail).m)])
  end
  face_mat(sf, M_WINDOW_MOSQUITO_MESH) if sf
  sg.set_attribute('Specification', 'type', 'Removable fine insect screen; actual mesh and track to be specified')
  sg
end

def add_window_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir = 1, panels = 2, has_curtains = true)
awning_ids = ['W3', 'W2', 'W_Fam_Rear', 'W_TB2_Rear']
if awning_ids.include?(id)
  w_grp = add_awning_window_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir, panels)
else
  w_grp = add_sliding_window_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir, [panels.to_i, 2].max)
end
add_fine_mosquito_screen(w_grp.entities, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t, interior_dir)
add_curtain_unit(w_grp.entities, id, horizontal, fixed_coord, interior_dir, r1, r2, z1 - 0.04, z2 + 0.02, wall_t) if has_curtains
w_grp.set_attribute('Opening', 'operable', true)
w_grp.set_attribute('Opening', 'fixed_glass', false)
w_grp
end
def add_door_unit(parent_ents, id, horizontal, fixed_coord, r1, r2, z1, z2, wall_t)
d_grp = parent_ents.add_group; d_grp.name = "Door_#{id}"; de = d_grp.entities
jt = 0.045; jd = wall_t + 0.02; dt = 0.045
if horizontal
y1 = fixed_coord - jd / 2.0; y2 = fixed_coord + jd / 2.0
add_box(de, r1, y1, r1 + jt, y2, z1, z2, M_METAL_BLK)
add_box(de, r2 - jt, y1, r2, y2, z1, z2, M_METAL_BLK)
add_box(de, r1 + jt, y1, r2 - jt, y2, z2 - jt, z2, M_METAL_BLK)
add_box(de, r1 + jt, fixed_coord - dt / 2.0, r2 - jt, fixed_coord + dt / 2.0, z1, z2 - jt, M_WOOD_DOOR)
add_box(de, r1 + 0.14, fixed_coord - dt / 2.0 - 0.006, r2 - 0.14, fixed_coord + dt / 2.0 + 0.006, z1 + 0.18, z1 + 0.95, M_WOOD_OAK)
add_box(de, r1 + 0.14, fixed_coord - dt / 2.0 - 0.006, r2 - 0.14, fixed_coord + dt / 2.0 + 0.006, z1 + 1.12, z2 - 0.18, M_WOOD_OAK)
add_box(de, r2 - jt - 0.12, fixed_coord - 0.065, r2 - jt - 0.03, fixed_coord + 0.065, z1 + 0.98, z1 + 1.02, M_BRASS)
else
x1 = fixed_coord - jd / 2.0; x2 = fixed_coord + jd / 2.0
add_box(de, x1, r1, x2, r1 + jt, z1, z2, M_METAL_BLK)
add_box(de, x1, r2 - jt, x2, r2, z1, z2, M_METAL_BLK)
add_box(de, x1, r1 + jt, x2, r2 - jt, z2 - jt, z2, M_METAL_BLK)
add_box(de, fixed_coord - dt / 2.0, r1 + jt, fixed_coord + dt / 2.0, r2 - jt, z1, z2 - jt, M_WOOD_DOOR)
add_box(de, fixed_coord - dt / 2.0 - 0.006, r1 + 0.14, fixed_coord + dt / 2.0 + 0.006, r2 - 0.14, z1 + 0.18, z1 + 0.95, M_WOOD_OAK)
add_box(de, fixed_coord - dt / 2.0 - 0.006, r1 + 0.14, fixed_coord + dt / 2.0 + 0.006, r2 - 0.14, z1 + 1.12, z2 - 0.18, M_WOOD_OAK)
add_box(de, fixed_coord - 0.065, r2 - jt - 0.12, fixed_coord + 0.065, r2 - jt - 0.03, z1 + 0.98, z1 + 1.02, M_BRASS)
end
d_grp.set_attribute('Opening', 'recommended_swing', 'Bedroom 2 inward into bedroom, off the level 2F landing. Door hinge at east jamb; finish swing must be checked onsite.') if id == 'D_B2'
d_grp
end
def build_monolithic_wall(shell_ents, fixtures_ents, id, x1, y1, x2, y2, t, z_base, z_top_start, z_top_end, openings)
wall_grp = shell_ents.add_group; wall_grp.name = "Wall_Solid_#{id}"; we = wall_grp.entities
horizontal = (y1 - y2).abs < 1e-4
s_min, s_max = horizontal ? [x1, x2].minmax : [y1, y2].minmax
# #region agent log
zt = [z_top_start.to_f, z_top_end.to_f].max
if horizontal
  agent_record_box("Wall_Solid_#{id}", s_min, y1 - t / 2.0, s_max, y1 + t / 2.0, z_base, zt, 'wall')
else
  agent_record_box("Wall_Solid_#{id}", x1 - t / 2.0, s_min, x1 + t / 2.0, s_max, z_base, zt, 'wall')
end
# #endregion
doors = openings.select { |op| op[:type] == :door || op[:type] == :sliding_glass }.sort_by { |op| op[:r][0] }
windows = openings.select { |op| op[:type] == :window }.sort_by { |op| op[:r][0] }
vents = openings.select { |op| op[:type] == :vent }.sort_by { |op| op[:r][0] }
wall_holes = windows + vents
if horizontal
yf = y1 - t / 2.0
pts = [Geom::Point3d.new(s_min.m, yf.m, z_base.m)]
doors.each do |d|
d1, d2 = d[:r]; dh = d[:z_head] || (z_base + 2.1)
pts << Geom::Point3d.new(d1.m, yf.m, z_base.m) if (d1 - s_min).abs > 1e-4
pts << Geom::Point3d.new(d1.m, yf.m, dh.m) << Geom::Point3d.new(d2.m, yf.m, dh.m) << Geom::Point3d.new(d2.m, yf.m, z_base.m)
end
pts << Geom::Point3d.new(s_max.m, yf.m, z_base.m) if (pts.last.x - s_max.m).abs > 1e-4
pts << Geom::Point3d.new(s_max.m, yf.m, z_top_end.m) << Geom::Point3d.new(s_min.m, yf.m, z_top_start.m)
main_face = we.add_face(pts)
wall_holes.each do |w|
w1, w2 = w[:r]; zs = w[:z_sill] || (z_base + 0.9); zh = w[:z_head] || (z_base + 2.1)
hole = we.add_face([Geom::Point3d.new(w1.m, yf.m, zs.m), Geom::Point3d.new(w2.m, yf.m, zs.m), Geom::Point3d.new(w2.m, yf.m, zh.m), Geom::Point3d.new(w1.m, yf.m, zh.m)])
hole.erase! if hole
end
main_face.reverse! if main_face.normal.y < 0
main_face.pushpull(t.m)
else
xf = x1 - t / 2.0
pts = [Geom::Point3d.new(xf.m, s_min.m, z_base.m)]
doors.each do |d|
d1, d2 = d[:r]; dh = d[:z_head] || (z_base + 2.1)
pts << Geom::Point3d.new(xf.m, d1.m, z_base.m) if (d1 - s_min).abs > 1e-4
pts << Geom::Point3d.new(xf.m, d1.m, dh.m) << Geom::Point3d.new(xf.m, d2.m, dh.m) << Geom::Point3d.new(xf.m, d2.m, z_base.m)
end
pts << Geom::Point3d.new(xf.m, s_max.m, z_base.m) if (pts.last.y - s_max.m).abs > 1e-4
pts << Geom::Point3d.new(xf.m, s_max.m, z_top_end.m) << Geom::Point3d.new(xf.m, s_min.m, z_top_start.m)
main_face = we.add_face(pts)
wall_holes.each do |w|
w1, w2 = w[:r]; zs = w[:z_sill] || (z_base + 0.9); zh = w[:z_head] || (z_base + 2.1)
hole = we.add_face([Geom::Point3d.new(xf.m, w1.m, zs.m), Geom::Point3d.new(xf.m, w2.m, zs.m), Geom::Point3d.new(xf.m, w2.m, zh.m), Geom::Point3d.new(xf.m, w1.m, zh.m)])
hole.erase! if hole
end
main_face.reverse! if main_face.normal.x < 0
main_face.pushpull(t.m)
end
doors.each do |d|
dh = d[:z_head] || (z_base + 2.1)
if d[:type] == :sliding_glass
add_window_unit(fixtures_ents, d[:id], horizontal, horizontal ? y1 : x1, d[:r][0], d[:r][1], z_base, dh, t, d[:in_dir] || 1, d[:panels] || 3, true)
else
add_door_unit(fixtures_ents, d[:id], horizontal, horizontal ? y1 : x1, d[:r][0], d[:r][1], z_base, dh, t)
end
end
windows.each do |w|
zs = w[:z_sill] || (z_base + 0.9); zh = w[:z_head] || (z_base + 2.1)
curt = w.key?(:curtains) ? w[:curtains] : true
add_window_unit(fixtures_ents, w[:id], horizontal, horizontal ? y1 : x1, w[:r][0], w[:r][1], zs, zh, t, w[:in_dir] || 1, w[:panels] || 2, curt)
end
wall_grp
end
def add_clipped_diagonal_bars(parent_ents, x1, x2, y_min, y_max, z1, z2, slope_sign, pitch, bar_half_w, mat)
w = x2 - x1; h = z2 - z1
return if w < 0.02 || h < 0.02
depth = (y_max - y_min).abs
c_min = (slope_sign > 0) ? (z1 - x2) : (z1 + x1)
c_max = (slope_sign > 0) ? (z2 - x1) : (z2 + x2)
c = c_min + pitch * 0.45
while c < c_max - pitch * 0.15
c_low = c - bar_half_w; c_high = c + bar_half_w
candidates = [
[x1, z1], [x2, z1], [x2, z2], [x1, z2],
[x1, slope_sign * x1 + c_low], [x1, slope_sign * x1 + c_high],
[x2, slope_sign * x2 + c_low], [x2, slope_sign * x2 + c_high],
[(z1 - c_low) * slope_sign, z1], [(z1 - c_high) * slope_sign, z1],
[(z2 - c_low) * slope_sign, z2], [(z2 - c_high) * slope_sign, z2]
]
eps = 1e-4
valid = candidates.select { |(px, pz)| val = pz - slope_sign * px; px >= x1 - eps && px <= x2 + eps && pz >= z1 - eps && pz <= z2 + eps && val >= c_low - eps && val <= c_high + eps }
uniq = []
valid.each { |(px, pz)| uniq << [px, pz] unless uniq.any? { |(ux, uz)| (ux - px).abs < 1e-3 && (uz - pz).abs < 1e-3 } }
if uniq.length >= 3
cx = uniq.sum { |p| p[0] } / uniq.length.to_f; cz = uniq.sum { |p| p[1] } / uniq.length.to_f
uniq.sort_by! { |(px, pz)| Math.atan2(pz - cz, px - cx) }
b_grp = parent_ents.add_group
face = b_grp.entities.add_face(uniq.map { |(px, pz)| Geom::Point3d.new(px.m, y_min.m, pz.m) })
if face
face.reverse! if face.normal.y < 0
face.pushpull(depth.m)
end
b_grp.material = mat
end
c += pitch
end
end
def add_hyper_realistic_balcony_railing(parent_ents, name, x1, x2, y_center, z1, z2)
g = parent_ents.add_group; g.name = name; ge = g.entities
# #region agent log
agent_record_box(name, x1, y_center - 0.048, x2, y_center + 0.048, z1, z2, 'railing')
agent_dbg('B', 'sketchupBambanin.rb:balcony_railing', 'railing_aabb', { 'name' => name, 'x1' => x1, 'x2' => x2, 'y' => y_center, 'z1' => z1, 'z2' => z2 })
# #endregion
add_box(ge, x1, y_center - 0.04, x2, y_center + 0.04, z1, z1 + 0.045, M_METAL_BLK)
add_box(ge, x1, y_center - 0.042, x2, y_center + 0.042, z1 + 0.045, z1 + 0.052, M_CHROME)
add_box(ge, x1, y_center - 0.042, x2, y_center + 0.042, z2 - 0.045, z2, M_METAL_BLK)
add_box(ge, x1, y_center - 0.032, x2, y_center + 0.032, z2 - 0.062, z2 - 0.045, M_CHROME)
num_bays = 3; post_w = 0.048; bay_span = (x2 - x1 - post_w) / num_bays.to_f
z_inner1 = z1 + 0.052; z_inner2 = z2 - 0.062
(0..num_bays).each do |i|
px1 = x1 + i * bay_span; px2 = px1 + post_w
add_box(ge, px1 - 0.012, y_center - 0.048, px2 + 0.012, y_center + 0.048, z1, z1 + 0.058, M_METAL_BLK)
add_box(ge, px1, y_center - 0.032, px2, y_center + 0.032, z_inner1, z_inner2, M_METAL_BLK)
end
num_bays.times do |b|
bx1 = x1 + b * bay_span + post_w; bx2 = x1 + (b + 1) * bay_span
bx_mid = (bx1 + bx2) / 2.0; bz_mid = (z_inner1 + z_inner2) / 2.0
gx1 = bx1 + 0.018; gx2 = bx2 - 0.018; gz1 = z_inner1 + 0.018; gz2 = z_inner2 - 0.018
add_box(ge, gx1, y_center + 0.010, gx2, y_center + 0.024, gz1, gz2, M_RAIL_GLASS)
m_t = 0.024
add_box(ge, bx1, y_center - 0.024, bx2, y_center - 0.002, bz_mid - m_t / 2.0, bz_mid + m_t / 2.0, M_METAL_BLK)
add_box(ge, bx_mid - m_t / 2.0, y_center - 0.024, bx_mid + m_t / 2.0, y_center - 0.002, z_inner1, z_inner2, M_METAL_BLK)
add_clipped_diagonal_bars(ge, bx1, bx_mid - m_t / 2.0, y_center - 0.020, y_center - 0.005, bz_mid + m_t / 2.0, z_inner2, 1, 0.11, 0.012, M_METAL_BLK)
add_clipped_diagonal_bars(ge, bx_mid + m_t / 2.0, bx2, y_center - 0.020, y_center - 0.005, bz_mid + m_t / 2.0, z_inner2, -1, 0.11, 0.012, M_METAL_BLK)
add_clipped_diagonal_bars(ge, bx1, bx_mid - m_t / 2.0, y_center - 0.020, y_center - 0.005, z_inner1, bz_mid - m_t / 2.0, -1, 0.11, 0.012, M_METAL_BLK)
add_clipped_diagonal_bars(ge, bx_mid + m_t / 2.0, bx2, y_center - 0.020, y_center - 0.005, z_inner1, bz_mid - m_t / 2.0, 1, 0.11, 0.012, M_METAL_BLK)
end
g
end
def add_hyper_realistic_interior_glass_railing(parent_ents, name, x1, x2, y_center, z1, z2, num_bays = 4)
g = parent_ents.add_group; g.name = name; ge = g.entities
# #region agent log
agent_record_box(name, x1, y_center - 0.040, x2, y_center + 0.040, z1, z2, 'railing')
agent_dbg('B', 'sketchupBambanin.rb:interior_railing_x', 'railing_aabb', { 'name' => name, 'x1' => x1, 'x2' => x2, 'y' => y_center, 'z1' => z1, 'z2' => z2 })
# #endregion
add_box(ge, x1, y_center - 0.038, x2, y_center + 0.038, z1, z1 + 0.055, M_METAL_BLK)
add_box(ge, x1, y_center - 0.040, x2, y_center + 0.040, z1 + 0.055, z1 + 0.062, M_CHROME)
add_box(ge, x1, y_center - 0.038, x2, y_center + 0.038, z2 - 0.042, z2, M_WOOD_DARK)
post_w = 0.038; bay_span = (x2 - x1 - post_w) / num_bays.to_f
z_glass1 = z1 + 0.062; z_glass2 = z2 - 0.058
(0..num_bays).each do |i|
px1 = x1 + i * bay_span
add_box(ge, px1, y_center - 0.024, px1 + post_w, y_center + 0.024, z_glass1, z_glass2, M_METAL_BLK)
end
num_bays.times do |b|
bx1 = x1 + b * bay_span + post_w; bx2 = x1 + (b + 1) * bay_span
add_box(ge, bx1 + 0.016, y_center - 0.008, bx2 - 0.016, y_center + 0.008, z_glass1 + 0.015, z_glass2 - 0.015, M_RAIL_GLASS)
end
g
end
def add_hyper_realistic_interior_glass_railing_y(parent_ents, name, x_center, y1, y2, z1, z2)
g = parent_ents.add_group; g.name = name; ge = g.entities
# #region agent log
agent_record_box(name, x_center - 0.036, y1, x_center + 0.036, y2, z1, z2, 'railing')
agent_dbg('B', 'sketchupBambanin.rb:interior_railing_y', 'railing_aabb', { 'name' => name, 'x' => x_center, 'y1' => y1, 'y2' => y2, 'z1' => z1, 'z2' => z2 })
# #endregion
add_box(ge, x_center - 0.034, y1, x_center + 0.034, y2, z1, z1 + 0.055, M_METAL_BLK)
add_box(ge, x_center - 0.036, y1, x_center + 0.036, y2, z2 - 0.042, z2, M_WOOD_DARK)
add_box(ge, x_center - 0.008, y1 + 0.04, x_center + 0.008, y2 - 0.04, z1 + 0.06, z2 - 0.05, M_RAIL_GLASS)
g
end
base_grp = ents.add_group
base_grp.name = '01_Site_and_Realistic_Gardens'
base_grp.layer = L_SITE
be = base_grp.entities
add_box(be, 0.0, 0.0, 10.0, 10.0, -0.15, 0.0, M_SLAB, 'Lot_Slab')
add_luxury_tiled_floor(be, 'GF_Living_Dining_Kitchen_Porcelanato_60x60', 3.225, 2.075, 6.95, 7.925, 0.0, 0.02, 0.60, 0.60, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_plank_floor(be, 'GF_Bedroom1_SPC_Light_Oak_Planks', 7.05, 1.575, 9.85, 4.85, 0.0, 0.02, 0.18, 1.22, M_SPC_OAK, M_SPC_GROUT)
add_luxury_tiled_floor(be, 'GF_TB1_Pietrasanta_Light_Grey_35x35', 7.05, 6.55, 9.85, 7.925, 0.0, 0.02, 0.35, 0.35, M_TILE_BATH1, M_TILE_BATH1, M_GROUT_PLAT)
add_luxury_tiled_floor(be, 'GF_Stairwell_Porcelanato_60x60', 6.95, 4.85, 9.85, 6.55, 0.0, 0.02, 0.60, 0.60, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_tiled_floor(be, 'GF_Garage_Luxury_Paver_Tiles', 0.15, 0.15, 3.075, 6.00, 0.0, 0.015, 0.60, 0.60, M_TILE_GARAGE, M_TILE_GARAGE, M_GROUT_DARK)
add_luxury_tiled_floor(be, 'GF_Entry_Walk_Porcelanato_60x60', 3.075, 0.15, 4.40, 1.925, 0.0, 0.015, 0.60, 0.60, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_tiled_floor(be, 'GF_Service_Area_Tiles', 3.075, 8.075, 9.85, 9.85, 0.0, 0.015, 0.50, 0.50, M_SIDEWALK, M_SIDEWALK, M_GROUT_DARK)
add_box(be, -0.4, -1.0, 0.15, 0.0, -0.15, 0.0, M_SIDEWALK, 'Sidewalk_Left')
add_box(be, 0.15, -1.0, 4.30, 0.0, -0.15, -0.02, M_SLAB, 'Driveway_Ramp')
add_box(be, 4.30, -1.0, 10.4, 0.0, -0.15, 0.0, M_SIDEWALK, 'Sidewalk_Right')
g2_grp = be.add_group; g2_grp.name = 'Front_Garden_2_Botanical'; g2e = g2_grp.entities
add_box(g2e, 4.40, 0.15, 4.48, 1.925, 0.0, 0.34, M_WALL_EXT)
add_box(g2e, 4.48, 0.15, 9.85, 1.12, 0.0, 0.025, M_GRASS)
add_box(g2e, 4.48, 1.12, 9.85, 1.425, 0.0, 0.022, M_PEBBLES)
[4.75, 5.45, 6.15, 6.85, 7.55].each_with_index { |sx, i| add_box(g2e, sx, 0.45, sx + 0.48, 0.88, 0.025, 0.045, M_STONE, "Garden_Stepping_Stone_#{i + 1}") }
add_box(g2e, 4.48, 1.425, 6.925, 1.925, 0.0, 0.34, M_WALL_EXT)
add_box(g2e, 4.54, 1.48, 6.86, 1.87, 0.34, 0.37, M_SOIL)
add_trimmed_hedge(g2e, 'Planter_Boxwood_Hedge', 4.62, 1.56, 6.78, 1.79, 0.37, 0.28)
add_rosette_plant(g2e, 'Planter_Agave_1', 5.05, 1.67, 0.37, 0.14, 0.36)
add_rosette_plant(g2e, 'Planter_Agave_2', 6.20, 1.67, 0.37, 0.14, 0.36)
add_trimmed_hedge(g2e, 'Front_Fence_Hedge_1', 4.65, 0.22, 6.95, 0.42, 0.025, 0.28)
add_trimmed_hedge(g2e, 'Front_Fence_Hedge_2', 7.40, 0.22, 8.25, 0.42, 0.025, 0.28)
add_rosette_plant(g2e, 'Front_Tropical_Fern_1', 8.05, 0.82, 0.025, 0.24, 0.42)
add_rosette_plant(g2e, 'Front_Tropical_Fern_2', 9.42, 0.52, 0.025, 0.22, 0.38)
[5.80, 7.15, 8.20].each do |lx|
add_box(g2e, lx, 1.20, lx + 0.06, 1.26, 0.02, 0.42, M_METAL_BLK)
add_box(g2e, lx - 0.005, 1.195, lx + 0.065, 1.265, 0.42, 0.48, M_LED_GLOW)
end
add_realistic_palm_tree(g2e, 'Front_Garden_Palm_Tree', 8.95, 0.78, 0.025, 2.75, 0.44)
g1_grp = be.add_group; g1_grp.name = 'Rear_Garden_1_Botanical'; g1e = g1_grp.entities
add_box(g1e, 0.15, 6.0, 3.075, 9.85, 0.0, 0.015, M_SIDEWALK)
add_box(g1e, 0.25, 6.15, 2.75, 9.65, 0.015, 0.03, M_GRASS)
add_trimmed_hedge(g1e, 'Rear_West_Hedge', 0.30, 6.25, 0.65, 8.05, 0.03, 0.38)
add_rosette_plant(g1e, 'Rear_Tropical_Plant_1', 0.60, 6.55, 0.03, 0.26, 0.45)
add_rosette_plant(g1e, 'Rear_Tropical_Plant_2', 0.60, 7.50, 0.03, 0.26, 0.42)
add_rosette_plant(g1e, 'Rear_Tropical_Plant_3', 0.80, 9.20, 0.03, 0.28, 0.46)
add_realistic_palm_tree(g1e, 'Rear_Garden_Palm_Tree', 1.55, 8.65, 0.03, 2.95, 0.68)
perim_grp = ents.add_group; perim_grp.name = '02_Smooth_Perimeter_Firewalls'; perim_grp.layer = L_PERIM; pe = perim_grp.entities
perim_parts = []
e1_grp = pe.add_group
f_e1 = e1_grp.entities.add_face([
Geom::Point3d.new(0.0.m, 0.0.m, 0.0.m), Geom::Point3d.new(0.0.m, 10.0.m, 0.0.m), Geom::Point3d.new(0.0.m, 10.0.m, 2.0.m),
Geom::Point3d.new(0.0.m, 8.22.m, 2.0.m), Geom::Point3d.new(0.0.m, 8.22.m, 5.70.m), Geom::Point3d.new(0.0.m, 3.38.m, 6.04.m),
Geom::Point3d.new(0.0.m, 3.38.m, 5.15.m), Geom::Point3d.new(0.0.m, 3.925.m, 5.15.m), Geom::Point3d.new(0.0.m, 3.925.m, 4.10.m),
Geom::Point3d.new(0.0.m, 1.925.m, 4.10.m), Geom::Point3d.new(0.0.m, 1.925.m, 2.0.m), Geom::Point3d.new(0.0.m, 0.0.m, 2.0.m)
])
f_e1.reverse! if f_e1.normal.x < 0; f_e1.pushpull(0.15.m); perim_parts << e1_grp
e2_grp = pe.add_group
f_e2 = e2_grp.entities.add_face([
Geom::Point3d.new(9.85.m, 0.0.m, 0.0.m), Geom::Point3d.new(9.85.m, 10.0.m, 0.0.m), Geom::Point3d.new(9.85.m, 10.0.m, 2.0.m),
Geom::Point3d.new(9.85.m, 8.22.m, 2.0.m), Geom::Point3d.new(9.85.m, 8.22.m, 6.02.m), Geom::Point3d.new(9.85.m, 0.83.m, 6.54.m),
Geom::Point3d.new(9.85.m, 0.83.m, 5.65.m), Geom::Point3d.new(9.85.m, 1.425.m, 5.65.m), Geom::Point3d.new(9.85.m, 1.425.m, 2.0.m),
Geom::Point3d.new(9.85.m, 0.0.m, 2.0.m)
])
f_e2.reverse! if f_e2.normal.x < 0; f_e2.pushpull(0.15.m); perim_parts << e2_grp
perim_parts << add_box(pe, 0.0, 9.85, 10.0, 10.0, 0.0, 2.0, M_WALL_FENCE)
weld_groups_into_monolithic_shell!(perim_grp, perim_parts, M_WALL_FENCE)
gate_grp = ents.add_group; gate_grp.name = '03_Front_Gates_and_Fence_E4'; gate_grp.layer = L_FENCE; ge = gate_grp.entities
[[3.075, 3.24], [4.30, 4.48], [7.10, 7.26]].each_with_index { |(px1, px2), idx| add_box(ge, px1, 0.0, px2, 0.15, 0.0, 2.0, M_WALL_FENCE, "Fence_Post_#{idx + 1}") }
def build_steel_gate_leaf(parent_ents, name, x1, x2, y_center, z1, z2)
g = parent_ents.add_group; g.name = name; ge = g.entities
ft = 0.045; y1 = y_center - 0.022; y2 = y_center + 0.022
add_box(ge, x1, y1, x2, y2, z1, z1 + ft, M_METAL_BLK)
add_box(ge, x1, y1, x2, y2, z2 - ft, z2, M_METAL_BLK)
add_box(ge, x1, y1, x1 + ft, y2, z1 + ft, z2 - ft, M_METAL_BLK)
add_box(ge, x2 - ft, y1, x2, y2, z1 + ft, z2 - ft, M_METAL_BLK)
add_box(ge, x1 + ft, y1 + 0.006, x2 - ft, y2 - 0.006, (z1 + z2) / 2.0 - 0.02, (z1 + z2) / 2.0 + 0.02, M_METAL_BLK)
curr_x = x1 + ft + 0.055
while curr_x + 0.028 < x2 - ft - 0.02
add_box(ge, curr_x, y1 + 0.005, curr_x + 0.028, y2 - 0.005, z1 + ft, z2 - ft, M_METAL_BLK)
curr_x += 0.085
end
end
mid_garage = (0.15 + 3.075) / 2.0
build_steel_gate_leaf(ge, 'D1_Garage_Gate_Left', 0.16, mid_garage - 0.01, 0.075, 0.05, 1.92)
build_steel_gate_leaf(ge, 'D1_Garage_Gate_Right', mid_garage + 0.01, 3.065, 0.075, 0.05, 1.92)
build_steel_gate_leaf(ge, 'D2_Main_Pedestrian_Gate', 3.25, 4.29, 0.075, 0.05, 1.92)
add_box(ge, 4.16, 0.03, 4.25, 0.12, 0.95, 1.12, M_BRASS, 'Gate_Latch_Box')
[[4.48, 7.10], [7.26, 9.85]].each_with_index do |(fx1, fx2), idx|
add_box(ge, fx1, 0.02, fx2, 0.15, 0.0, 1.05, M_WALL_FENCE, "Fence_Base_#{idx + 1}")
add_box(ge, fx1, 0.0, fx2, 0.02, 0.0, 1.05, M_STONE, "Fence_Stone_Cladding_#{idx + 1}")
add_box(ge, fx1, -0.02, fx2, 0.16, 1.05, 1.11, M_WALL_EXT, "Fence_Coping_Ledge_#{idx + 1}")
add_box(ge, fx1, 0.055, fx2, 0.105, 1.11, 1.15, M_METAL_BLK)
add_box(ge, fx1, 0.055, fx2, 0.105, 1.88, 1.92, M_METAL_BLK)
z_bar = 1.20
while z_bar < 1.86
add_box(ge, fx1, 0.065, fx2, 0.095, z_bar, z_bar + 0.025, M_METAL_BLK)
z_bar += 0.075
end
mid_fx = (fx1 + fx2) / 2.0
add_box(ge, mid_fx - 0.24, 0.05, mid_fx - 0.20, 0.11, 1.15, 1.88, M_METAL_BLK)
add_box(ge, mid_fx + 0.20, 0.05, mid_fx + 0.24, 0.11, 1.15, 1.88, M_METAL_BLK)
add_box(ge, mid_fx - 0.20, 0.05, mid_fx + 0.20, 0.11, 1.50, 1.53, M_METAL_BLK)
add_clipped_diagonal_bars(ge, mid_fx - 0.20, mid_fx + 0.20, 0.06, 0.10, 1.53, 1.88, 1, 0.09, 0.012, M_METAL_BLK)
add_clipped_diagonal_bars(ge, mid_fx - 0.20, mid_fx + 0.20, 0.06, 0.10, 1.15, 1.50, -1, 0.09, 0.012, M_METAL_BLK)
end
def add_bathroom_exhaust_fan(parent_ents, name, xc, wall_y, z_center)
  grp = parent_ents.add_group
  grp.name = name
  e = grp.entities
  add_box(e, xc - 0.110, wall_y - 0.085, xc + 0.110, wall_y + 0.085, z_center - 0.100, z_center + 0.100, M_METAL_BLK, 'Ventilation_Duct_Sleeve')
  add_box(e, xc - 0.125, wall_y - 0.091, xc + 0.125, wall_y - 0.074, z_center - 0.116, z_center + 0.116, M_FIXTURE, 'Washroom_Fan_Interior_Cover')
  6.times do |i|
    z = z_center - 0.066 + i * 0.027
    add_box(e, xc - 0.083, wall_y - 0.098, xc + 0.083, wall_y - 0.090, z, z + 0.010, M_METAL_BLK, "Fan_Grille_#{i + 1}")
  end
  add_box(e, xc - 0.115, wall_y + 0.085, xc + 0.115, wall_y + 0.099, z_center - 0.105, z_center + 0.105, M_METAL_BLK, 'Exterior_Backdraft_Damper_Frame')
  grp.set_attribute('MEP', 'role', 'Bathroom ducted exhaust fan with backdraft damper; real capacity, duct route and electrical protection require specification')
  grp
end

def finish_exterior_canopy(ents, name, x1, y1, x2, y2, bottom, top)
  finish = ents.add_group
  finish.name = name
  fe = finish.entities
  f = fe.add_face([
    Geom::Point3d.new(x1.m, y1.m, (top + 0.006).m),
    Geom::Point3d.new(x1.m, y2.m, (top + 0.019).m),
    Geom::Point3d.new(x1.m, y2.m, (top + 0.027).m),
    Geom::Point3d.new(x1.m, y1.m, (top + 0.014).m)
  ])
  if f
    f.reverse! if f.normal.x < 0
    f.pushpull((x2 - x1).m)
  end
  fe.grep(Sketchup::Face).each { |face| face_mat(face, M_CANOPY) }
  add_box(fe, x1, y1 - 0.025, x2, y1, bottom - 0.010, bottom + 0.025, M_FASCIA_RED, 'Canopy_Front_Drip_Edge')
  finish
end

gf_grp = ents.add_group; gf_grp.name = '04_Ground_Floor_Architecture'; gfe = gf_grp.entities
gf_front_grp = gfe.add_group; gf_front_grp.name = 'GF_Front_Facade_Walls_and_Canopies'; gf_front_grp.layer = L_GF_EXT; gffe = gf_front_grp.entities
gf_front_shell = gffe.add_group; gf_front_shell.name = 'GF_Front_Wall_Shell'
gf_front_ops = gffe.add_group; gf_front_ops.name = 'GF_Front_Doors_Windows'
gf_front_parts = [
build_monolithic_wall(gf_front_shell.entities, gf_front_ops.entities, 'E7', 3.075, 2.0, 7.05, 2.0, 0.15, 0.0, 3.0, 3.0, [
{ id: 'D3', type: :door, r: [3.35, 4.30] }, { id: 'W5', type: :window, r: [4.90, 6.30], in_dir: 1 }
]),
build_monolithic_wall(gf_front_shell.entities, gf_front_ops.entities, 'E7_E8_Corner', 7.0, 1.425, 7.0, 2.075, 0.10, 0.0, 3.0, 3.0, []),
build_monolithic_wall(gf_front_shell.entities, gf_front_ops.entities, 'E8', 6.95, 1.5, 9.85, 1.5, 0.15, 0.0, 3.0, 3.0, [
{ id: 'W4', type: :window, r: [7.70, 9.10], in_dir: 1 }
])
]
weld_groups_into_monolithic_shell!(gf_front_shell, gf_front_parts, M_WALL_EXT, [3.0], [2.075, 1.575], [3.075, 9.85])
def add_stone_window_frame(parent_ents, name, x_out1, x_out2, x_in1, x_in2, y_front, thickness, z_bot, z_top, z_sill, z_head)
s_grp = parent_ents.add_group; s_grp.name = name; se = s_grp.entities
f_out = se.add_face([Geom::Point3d.new(x_out1.m, y_front.m, z_bot.m), Geom::Point3d.new(x_out2.m, y_front.m, z_bot.m), Geom::Point3d.new(x_out2.m, y_front.m, z_top.m), Geom::Point3d.new(x_out1.m, y_front.m, z_top.m)])
f_in = se.add_face([Geom::Point3d.new(x_in1.m, y_front.m, z_sill.m), Geom::Point3d.new(x_in2.m, y_front.m, z_sill.m), Geom::Point3d.new(x_in2.m, y_front.m, z_head.m), Geom::Point3d.new(x_in1.m, y_front.m, z_head.m)])
f_in.erase! if f_in
f_out.reverse! if f_out.normal.y < 0
f_out.pushpull(thickness.m)
s_grp.material = M_STONE
end
add_stone_window_frame(gffe, 'GF_Living_Stone', 4.70, 6.55, 4.90, 6.30, 1.90, 0.025, 0.0, 2.25, 0.90, 2.10)
add_stone_window_frame(gffe, 'GF_Bedroom_Stone', 7.50, 9.30, 7.70, 9.10, 1.40, 0.025, 0.0, 2.25, 0.90, 2.10)
add_box(gffe, 3.075, 1.48, 7.05, 1.925, 2.27, 2.35, M_CANOPY, 'Canopy_GF_Living_Entry')
finish_exterior_canopy(gffe, 'Canopy_GF_Living_Entry_Coping', 3.075, 1.48, 7.05, 1.925, 2.27, 2.35)
add_box(gffe, 7.45, 1.05, 9.40, 1.425, 2.27, 2.35, M_CANOPY, 'Canopy_GF_Bedroom1')
finish_exterior_canopy(gffe, 'Canopy_GF_Bedroom1_Coping', 7.45, 1.05, 9.40, 1.425, 2.27, 2.35)
gf_int_grp = gfe.add_group; gf_int_grp.name = 'GF_Rear_and_Interior_Walls'; gf_int_grp.layer = L_GF_WALLS; gfie = gf_int_grp.entities
gf_int_shell = gfie.add_group; gf_int_shell.name = 'GF_Interior_Wall_Shell'
gf_int_ops = gfie.add_group; gf_int_ops.name = 'GF_Interior_Doors_Windows'
gf_int_parts = [
build_monolithic_wall(gf_int_shell.entities, gf_int_ops.entities, 'E5', 3.15, 2.075, 3.15, 8.075, 0.15, 0.0, 3.0, 3.0, [{ id: 'W3', type: :window, r: [4.90, 6.30], z_sill: 0.84, z_head: 2.34, in_dir: 1, curtains: false }]),
build_monolithic_wall(gf_int_shell.entities, gf_int_ops.entities, 'E6', 3.075, 8.0, 9.85, 8.0, 0.15, 0.0, 3.0, 3.0, [
{ id: 'W1', type: :window, r: [3.90, 5.40], z_sill: 0.945, z_head: 1.640, in_dir: -1, curtains: false },
{ id: 'KITCHEN_EXHAUST_VENT', type: :vent, r: [5.53, 5.88], z_sill: 2.41, z_head: 2.65 },
{ id: 'D5', type: :door, r: [6.20, 6.95] }, { id: 'W2', type: :window, r: [8.075, 8.625], z_sill: 1.54, z_head: 2.14, in_dir: -1, panels: 1, curtains: false }, { id: 'TB1_FAN_VENT', type: :vent, r: [9.12, 9.34], z_sill: 2.55, z_head: 2.75 }
]),
build_monolithic_wall(gf_int_shell.entities, gf_int_ops.entities, 'I1', 7.0, 2.075, 7.0, 4.95, 0.10, 0.0, 3.0, 3.0, []),
build_monolithic_wall(gf_int_shell.entities, gf_int_ops.entities, 'I2', 6.95, 4.9, 9.85, 4.9, 0.10, 0.0, 3.0, 3.0, [{ id: 'D6', type: :door, r: [7.05, 7.85] }]),
build_monolithic_wall(gf_int_shell.entities, gf_int_ops.entities, 'I3', 6.95, 6.5, 9.85, 6.5, 0.10, 0.0, 3.0, 3.0, []),
build_monolithic_wall(gf_int_shell.entities, gf_int_ops.entities, 'I4', 7.0, 6.45, 7.0, 7.925, 0.10, 0.0, 3.0, 3.0, [{ id: 'D4', type: :door, r: [6.70, 7.40] }])
]
weld_groups_into_monolithic_shell!(gf_int_shell, gf_int_parts, M_WALL_EXT, [3.0], [2.075, 1.575], [3.075, 9.85])
add_bathroom_exhaust_fan(gf_int_ops.entities, 'TB1_Ducted_Exhaust_Fan', 9.23, 8.0, 2.65)
add_box(gfie, 3.075, 8.075, 9.85, 8.85, 2.25, 2.36, M_CANOPY, 'Canopy_GF_Rear_Service')
sf_grp = ents.add_group; sf_grp.name = '05_Second_Floor_Architecture'; sfe = sf_grp.entities
slab_2f_grp = sfe.add_group; slab_2f_grp.name = 'Second_Floor_Slabs_and_Luxury_Tiled_Floors'; slab_2f_grp.layer = L_2F_SLAB; s2e = slab_2f_grp.entities
conc_2f_grp = s2e.add_group; conc_2f_grp.name = 'Monolithic_2F_Concrete_Slabs'
conc_2f_parts = [
add_box(conc_2f_grp.entities, 0.15, 1.925, 3.075, 7.925, 2.85, 3.00, M_WALL_EXT),
add_box(conc_2f_grp.entities, 3.225, 4.90, 6.95, 7.925, 2.85, 3.00, M_WALL_EXT),
add_box(conc_2f_grp.entities, 6.95, 4.90, 7.855, 5.730, 2.85, 3.00, M_WALL_EXT),
add_box(conc_2f_grp.entities, 7.05, 4.85, 7.80, 4.90, 2.85, 3.00, M_WALL_EXT),
add_box(conc_2f_grp.entities, 6.95, 5.730, 7.05, 6.55, 2.85, 3.00, M_WALL_EXT),
add_box(conc_2f_grp.entities, 7.05, 1.575, 9.85, 4.85, 2.85, 3.00, M_WALL_EXT),
add_box(conc_2f_grp.entities, 7.05, 6.55, 9.85, 7.925, 2.85, 3.00, M_WALL_EXT)
]
weld_groups_into_monolithic_shell!(conc_2f_grp, conc_2f_parts, M_WALL_EXT, [2.85, 3.0], [], [0.15, 3.075, 9.85])
add_luxury_tiled_floor(s2e, 'SF_Family_Hall_Porcelanato_60x60_South', 3.225, 4.90, 6.95, 5.73, 3.00, 3.02, 0.60, 0.60, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_tiled_floor(s2e, 'SF_Family_Hall_Porcelanato_60x60_North', 3.225, 5.73, 6.95, 7.925, 3.00, 3.02, 0.60, 0.60, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_tiled_floor(s2e, 'Bedroom2_North_Door_Protected_Stair_Landing_Tiles', 6.95, 4.90, 7.855, 5.730, 3.00, 3.02, 0.395, 0.415, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_tiled_floor(s2e, 'Bedroom2_North_Door_Flush_Threshold_Tiles', 7.05, 4.85, 7.80, 4.90, 3.00, 3.02, 0.375, 0.05, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_tiled_floor(s2e, 'SF_Stair_Landing_North_Edge_Porcelanato_60x60', 6.95, 5.730, 7.05, 6.55, 3.00, 3.02, 0.10, 0.41, M_MARBLE_ICE, M_MARBLE_ICE, M_GROUT_PLAT)
add_luxury_plank_floor(s2e, 'SF_Bedroom2_SPC_Light_Oak_Planks', 7.05, 1.575, 9.85, 4.85, 3.00, 3.02, 0.18, 1.22, M_SPC_OAK, M_SPC_GROUT)
add_luxury_plank_floor(s2e, 'SF_Bedroom3_SPC_Light_Oak_Planks', 0.15, 4.075, 3.075, 7.925, 3.00, 3.02, 0.18, 1.22, M_SPC_OAK, M_SPC_GROUT)
add_luxury_tiled_floor(s2e, 'SF_Terrace_Basalt_Deck_Tiles', 0.15, 1.925, 3.075, 3.925, 3.00, 3.015, 0.50, 0.50, M_TILE_TERRACE, M_TILE_TERRACE, M_GROUT_DARK)
add_luxury_tiled_floor(s2e, 'SF_TB2_Aston_Nature_47x47', 7.05, 6.55, 9.85, 7.925, 3.00, 3.02, 0.47, 0.47, M_TILE_BATH2, M_TILE_BATH2, M_GROUT_PLAT)
sf_front_grp = sfe.add_group; sf_front_grp.name = 'SF_Front_Facade_and_Terrace'; sf_front_grp.layer = L_2F_EXT; sffe = sf_front_grp.entities
sf_front_shell = sffe.add_group; sf_front_shell.name = 'SF_Front_Wall_Shell'
sf_front_ops = sffe.add_group; sf_front_ops.name = 'SF_Front_Windows_Doors'
z_b3_front = z_lower_soffit(4.0); z_c_front = z_upper_soffit(2.0); z_b2_front = z_upper_soffit(1.5)
sf_front_parts = [
build_monolithic_wall(sf_front_shell.entities, sf_front_ops.entities, 'SF_B3_South', 0.15, 4.0, 3.225, 4.0, 0.15, 3.0, z_b3_front, z_b3_front, [{ id: 'D_Terrace', type: :sliding_glass, r: [0.40, 2.85], z_head: 5.05, in_dir: 1, panels: 3 }]),
build_monolithic_wall(sf_front_shell.entities, sf_front_ops.entities, 'SF_Center_Front', 3.075, 2.0, 7.05, 2.0, 0.15, 3.0, z_c_front, z_c_front, [{ id: 'W_2F_Center', type: :window, r: [3.35, 6.75], z_sill: 3.68, z_head: 5.10, in_dir: 1, panels: 4 }]),
build_monolithic_wall(sf_front_shell.entities, sf_front_ops.entities, 'SF_Front_Return', 7.0, 1.425, 7.0, 2.075, 0.10, 3.0, z_b2_front, z_c_front, []),
build_monolithic_wall(sf_front_shell.entities, sf_front_ops.entities, 'SF_B2_Front', 6.95, 1.5, 9.85, 1.5, 0.15, 3.0, z_b2_front, z_b2_front, [{ id: 'W_2F_B2', type: :window, r: [7.72, 9.12], z_sill: 3.90, z_head: 5.10, in_dir: 1, panels: 2 }])
]
weld_groups_into_monolithic_shell!(sf_front_shell, sf_front_parts, M_WALL_EXT, [3.0], [2.075, 1.575, 4.075], [0.15, 3.075, 3.225, 9.85])
add_box(sffe, 3.075, 1.84, 3.35, 1.925, 2.85, z_c_front, M_WALL_EXT)
add_box(sffe, 6.75, 1.84, 6.95, 1.925, 2.85, z_c_front, M_WALL_EXT)
add_box(sffe, 3.075, 1.84, 6.95, 1.925, 2.85, 3.12, M_WALL_EXT)
add_hyper_realistic_balcony_railing(sffe, 'Terrace_Hyper_Realistic_Glass_Railing', 0.15, 3.075, 1.98, 3.00, 4.05)
add_box(sffe, 0.15, 3.90, 3.075, 3.925, 5.15, z_b3_front, M_STONE)
add_box(sffe, 0.15, 3.90, 0.40, 3.925, 3.00, 5.15, M_STONE)
add_box(sffe, 2.85, 3.90, 3.075, 3.925, 3.00, 5.15, M_STONE)
add_box(sffe, 0.15, 3.55, 3.075, 3.925, 5.20, 5.28, M_CANOPY, 'Canopy_2F_Terrace_Door')
finish_exterior_canopy(sffe, 'Canopy_2F_Terrace_Door_Coping', 0.15, 3.55, 3.075, 3.925, 5.20, 5.28)
add_box(sffe, 3.35, 1.88, 6.75, 1.925, 3.12, 3.68, M_STONE)
add_box(sffe, 3.075, 1.48, 7.05, 1.925, 5.20, 5.28, M_CANOPY, 'Canopy_2F_Center_Window')
finish_exterior_canopy(sffe, 'Canopy_2F_Center_Window_Coping', 3.075, 1.48, 7.05, 1.925, 5.20, 5.28)
z_louv = 5.26
while z_louv < z_c_front - 0.04
add_box(sffe, 3.35, 1.86, 6.75, 1.92, z_louv, z_louv + 0.03, M_WALL_EXT)
z_louv += 0.055
end
add_box(sffe, 7.68, 1.40, 9.16, 1.425, 3.05, 3.90, M_WOOD_EXT)
add_box(sffe, 7.68, 1.40, 9.16, 1.425, 5.18, z_upper_soffit(1.425), M_WOOD_EXT)
[3.22, 3.40, 3.58, 3.76, 5.35, 5.53, 5.71, 5.89, 6.05].each { |zg| add_box(sffe, 7.68, 1.392, 9.16, 1.40, zg, zg + 0.015, M_WOOD_DARK) }
add_box(sffe, 7.45, 1.05, 9.40, 1.425, 5.20, 5.28, M_CANOPY, 'Canopy_2F_Bedroom_Window')
finish_exterior_canopy(sffe, 'Canopy_2F_Bedroom_Window_Coping', 7.45, 1.05, 9.40, 1.425, 5.20, 5.28)
[7.35, 9.45].each_with_index do |sx, i|
add_box(sffe, sx, 1.37, sx + 0.09, 1.425, 4.35, 4.72, M_METAL_BLK, "Wall_Sconce_#{i + 1}")
add_box(sffe, sx + 0.01, 1.38, sx + 0.08, 1.41, 4.33, 4.35, M_LED_GLOW)
add_box(sffe, sx + 0.01, 1.38, sx + 0.08, 1.41, 4.72, 4.74, M_LED_GLOW)
end
sf_int_grp = sfe.add_group; sf_int_grp.name = 'SF_Rear_and_Interior_Walls'; sf_int_grp.layer = L_2F_WALLS; sfie = sf_int_grp.entities
sf_int_shell = sfie.add_group; sf_int_shell.name = 'SF_Interior_Wall_Shell'
sf_int_ops = sfie.add_group; sf_int_ops.name = 'SF_Interior_Doors_Windows'
z_rear_w = z_lower_soffit(8.0); z_rear_e = z_upper_soffit(8.0)
sf_int_parts = [
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_West_Div', 3.15, 2.075, 3.15, 8.075, 0.15, 3.0, z_upper_soffit(2.075), z_rear_e, [{ id: 'D_B3', type: :door, r: [7.05, 7.85], z_head: 5.10 }]),
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_Rear_West', 0.15, 8.0, 3.075, 8.0, 0.15, 3.0, z_rear_w, z_rear_w, [{ id: 'W_B3_Rear', type: :window, r: [0.95, 2.35], z_sill: 3.90, z_head: 5.05, in_dir: -1, panels: 2 }]),
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_Rear_East', 3.225, 8.0, 9.85, 8.0, 0.15, 3.0, z_rear_e, z_rear_e, [
{ id: 'W_Fam_Rear', type: :window, r: [4.30, 5.90], z_sill: 3.90, z_head: 5.10, in_dir: -1, panels: 2 },
{ id: 'W_TB2_Rear', type: :window, r: [8.05, 8.60], z_sill: 4.45, z_head: 5.05, in_dir: -1, panels: 1, curtains: false },
{ id: 'TB2_FAN_VENT', type: :vent, r: [9.12, 9.34], z_sill: 5.35, z_head: 5.55 }
]),
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_I1_B2_West', 7.0, 2.075, 7.0, 4.95, 0.10, 3.0, z_c_front, z_upper_soffit(4.95), []),
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_I2_B2_North', 7.05, 4.9, 9.85, 4.9, 0.10, 3.0, z_upper_soffit(4.9), z_upper_soffit(4.9), [{ id: 'D_B2', type: :door, r: [7.05, 7.80], z_head: 5.10 }]),
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_I3_TB2_South', 7.05, 6.5, 9.85, 6.5, 0.10, 3.0, z_upper_soffit(6.5), z_upper_soffit(6.5), []),
build_monolithic_wall(sf_int_shell.entities, sf_int_ops.entities, 'SF_I4_TB2_West', 7.0, 6.45, 7.0, 7.925, 0.10, 3.0, z_upper_soffit(6.45), z_upper_soffit(7.925), [{ id: 'D_TB2', type: :door, r: [6.70, 7.40], z_head: 5.10 }])
]
weld_groups_into_monolithic_shell!(sf_int_shell, sf_int_parts, M_WALL_EXT, [3.0], [2.075, 1.575, 4.075], [0.15, 3.075, 3.225, 9.85])
add_bathroom_exhaust_fan(sf_int_ops.entities, 'TB2_Ducted_Exhaust_Fan', 9.23, 8.0, 5.45)
add_box(sfie, 4.25, 8.075, 5.95, 8.10, 3.00, 3.90, M_STONE)
add_box(sfie, 4.25, 8.075, 5.95, 8.10, 5.18, z_upper_soffit(8.075), M_STONE)
add_box(sfie, 4.05, 8.075, 6.15, 8.48, 5.10, 5.18, M_CANOPY)
add_box(sfie, 0.15, 8.075, 0.95, 8.10, 3.00, z_lower_soffit(8.075), M_WOOD_REAR)
add_box(sfie, 2.35, 8.075, 3.075,8.10, 3.00, z_lower_soffit(8.075), M_WOOD_REAR)
add_box(sfie, 0.95, 8.075, 2.35, 8.10, 3.00, 3.90, M_WOOD_REAR)
add_box(sfie, 0.95, 8.075, 2.35, 8.10, 5.12, z_lower_soffit(8.075), M_WOOD_REAR)
add_box(sfie, 0.65, 8.075, 2.65, 8.45, 5.05, 5.12, M_CANOPY)
add_hyper_realistic_interior_glass_railing(sfie, 'Family_Hall_Hyper_Realistic_Glass_Balustrade', 3.225, 5.91, 4.94, 3.02, 3.98, 3)
add_hyper_realistic_interior_glass_railing(sfie, 'Family_Hall_Guard_Extension_At_Living_Void', 5.91, 7.045, 4.94, 3.02, 4.12, 2)
add_hyper_realistic_interior_glass_railing(sfie, 'Bedroom2_Landing_North_Glass_Guard', 6.955, 7.855, 5.735, 3.02, 4.12, 2)
add_box(sfie, 7.840, 5.702, 7.875, 5.765, 3.02, 4.12, M_METAL_BLK, 'Bedroom2_Landing_Guard_Return_Post')
roof_grp = ents.add_group; roof_grp.name = '06_Two_Tier_Sloped_Red_Roof'; roof_grp.layer = L_ROOF; re = roof_grp.entities
def finish_ribbed_roof_rakes(ents, x1, x2, y_front, y_back, z_front, z_back)
  [x1, x2 - 0.027].each_with_index do |x, i|
    trim = ents.add_group
    trim.name = "Roof_Sloped_Rake_#{i + 1}"
    e = trim.entities
    f = e.add_face([
      Geom::Point3d.new(x.m, y_front.m, (z_front - 0.078).m),
      Geom::Point3d.new(x.m, y_back.m, (z_back - 0.078).m),
      Geom::Point3d.new(x.m, y_back.m, (z_back + 0.116).m),
      Geom::Point3d.new(x.m, y_front.m, (z_front + 0.116).m)
    ])
    if f
      f.reverse! if f.normal.x < 0
      f.pushpull(0.027.m)
    end
    e.grep(Sketchup::Face).each { |face| face_mat(face, M_FASCIA_RED) }
  end
  add_box(ents, x1, y_front - 0.058, x2, y_front - 0.020, z_front - 0.091, z_front - 0.055, M_FASCIA_RED, 'Front_Eave_Drip_Flashing')
end

def build_sloped_ribbed_roof_tier(parent_ents, name, x1, x2, y_front, y_back, z_front, z_back)
t_grp = parent_ents.add_group; t_grp.name = name; te = t_grp.entities
s_grp = te.add_group
s_face = s_grp.entities.add_face([Geom::Point3d.new(x1.m, y_front.m, (z_front - 0.08).m), Geom::Point3d.new(x1.m, y_back.m, (z_back - 0.08).m), Geom::Point3d.new(x1.m, y_back.m, (z_back - 0.07).m), Geom::Point3d.new(x1.m, y_front.m, (z_front - 0.07).m)])
s_face.reverse! if s_face.normal.x < 0; s_face.pushpull((x2 - x1).m); s_grp.material = M_SOFFIT_WOOD
[[-0.070, -0.010, M_ROOF_INSULATION, 'Noncombustible_Mineral_Wool_Batts_60mm'], [-0.010, -0.008, M_ROOF_RADIANT_BARRIER, 'Reflective_Radiant_Barrier_2mm']].each do |low, high, finish, layer_name|
  layer = te.add_group
  layer.name = layer_name
  le = layer.entities
  face = le.add_face([Geom::Point3d.new(x1.m, y_front.m, (z_front + low).m), Geom::Point3d.new(x1.m, y_back.m, (z_back + low).m), Geom::Point3d.new(x1.m, y_back.m, (z_back + high).m), Geom::Point3d.new(x1.m, y_front.m, (z_front + high).m)])
  if face
    face.reverse! if face.normal.x < 0
    face.pushpull((x2 - x1).m)
  end
  le.grep(Sketchup::Face).each { |f| face_mat(f, finish) }
  layer.material = finish
end
t_grp.set_attribute('Roof_Thermal_Assembly', 'composition', '10 mm soffit lining + 60 mm mineral-wool batt + 2 mm radiant foil + 8 mm air gap under unchanged roof geometry; conceptual detail requiring fire, vapor and condensation review')
r_grp = te.add_group
r_face = r_grp.entities.add_face([Geom::Point3d.new(x1.m, y_front.m, z_front.m), Geom::Point3d.new(x1.m, y_back.m, z_back.m), Geom::Point3d.new(x1.m, y_back.m, (z_back + 0.10).m), Geom::Point3d.new(x1.m, y_front.m, (z_front + 0.10).m)])
r_face.reverse! if r_face.normal.x < 0; r_face.pushpull((x2 - x1).m); r_grp.material = M_ROOF_RED
add_box(te, x1, y_front - 0.02, x2, y_front, z_front - 0.08, z_front + 0.13, M_FASCIA_RED)
add_box(te, x1, y_back, x2, y_back + 0.02, z_back - 0.08, z_back + 0.12, M_FASCIA_RED)
curr_x = x1 + 0.12
while curr_x < x2 - 0.08
rib = te.add_group
rf = rib.entities.add_face([Geom::Point3d.new(curr_x.m, y_front.m, (z_front + 0.10).m), Geom::Point3d.new(curr_x.m, y_back.m, (z_back + 0.10).m), Geom::Point3d.new(curr_x.m, y_back.m, (z_back + 0.135).m), Geom::Point3d.new(curr_x.m, y_front.m, (z_front + 0.135).m)])
rf.reverse! if rf.normal.x < 0; rf.pushpull(0.035.m); rib.material = M_ROOF_RED
curr_x += 0.28
end
finish_ribbed_roof_rakes(te, x1, x2, y_front, y_back, z_front, z_back)
end
build_sloped_ribbed_roof_tier(re, 'Upper_Main_Roof_Tier', 3.075, 9.85, 1.20, 8.20, z_upper_deck(1.20), z_upper_deck(8.20))
build_sloped_ribbed_roof_tier(re, 'Lower_West_Roof_Tier', 0.15, 3.075, 3.40, 8.20, 5.82, 5.48)
def add_tabletop_plant(ents, cx_m, cy_m, z_m)
revolve_open_hollow_mesh(ents, 'Ceramic_Pot', [[0, 0], [65, 0], [78, 92], [72, 108], [0, 105]], M_WALL_EXT, 20).transform!(Geom::Transformation.translation(Geom::Vector3d.new(cx_m.m, cy_m.m, z_m.m)))
add_rosette_plant(ents, 'Tabletop_Foliage', cx_m, cy_m, z_m + 0.09, 0.18, 0.22)
end
def add_table_lamp(ents, cx_m, cy_m, z_m)
grp = ents.add_group; grp.name = 'Table_Lamp'; ge = grp.entities
cylinder_mm(ge, 'Lamp_Base', 88, 18, M_BRASS, 20)
cylinder_mm(ge, 'Lamp_Stem', 12, 200, M_METAL_BLK, 16).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, 0, mm(18))))
revolve_open_hollow_mesh(ge, 'Linen_Shade', [[92, 205], [142, 335], [130, 350], [88, 205]], M_PILLOW_CREAM, 24)
cylinder_mm(ge, 'Warm_Bulb', 28, 35, M_LED_GLOW, 16).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, 0, mm(200))))
grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(cx_m.m, cy_m.m, z_m.m)))
end
def add_split_ac_unit(ents, cx_m, cy_m, z_m, rot_deg)
grp = ents.add_group; grp.name = 'Split_AC_Unit'; ge = grp.entities
rounded_box_at(ge, 'AC_Casing', -0.45, -0.25, 0.0, 900, 250, 220, 45, M_WALL_EXT)
rounded_box_at(ge, 'AC_Outlet', -0.40, -0.255, 0.024, 800, 8, 22, 6, M_METAL_BLK)
grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(cx_m.m, cy_m.m, z_m.m)) * Geom::Transformation.rotation(ORIGIN, Z_AXIS, rot_deg.degrees))
end
def add_designer_chair(parent_ents, name, cx, cy, z_floor, facing_dir)
c_grp = parent_ents.add_group; c_grp.name = name; ce = c_grp.entities
w = 0.48; d = 0.50; x1 = cx - w / 2.0; x2 = cx + w / 2.0; y1 = cy - d / 2.0; y2 = cy + d / 2.0
leg_t = 0.032; inset = 0.035; seat_z1 = z_floor + 0.42; seat_z2 = z_floor + 0.48; back_z2 = z_floor + 0.86
[[x1 + inset, y1 + inset], [x2 - inset - leg_t, y1 + inset], [x1 + inset, y2 - inset - leg_t], [x2 - inset - leg_t, y2 - inset - leg_t]].each do |(lx, ly)|
add_box(ce, lx, ly, lx + leg_t, ly + leg_t, z_floor, z_floor + 0.05, M_BRASS)
add_box(ce, lx, ly, lx + leg_t, ly + leg_t, z_floor + 0.05, seat_z1, M_METAL_BLK)
end
add_box(ce, x1 + inset, y1 + inset, x2 - inset, y2 - inset, seat_z1 - 0.025, seat_z1, M_METAL_BLK)
rounded_box_at(ce, 'Chair_Seat', x1, y1, seat_z1, w * 1000, d * 1000, 62, 35, M_CHAIR_FAB)
add_inflated_pillow_mesh(ce, 'Chair_Seat_Pad', cx, cy, seat_z2, 430, 440, 48, 0, false, M_SOFA_MAIN)
bt = 0.065
case facing_dir
when :north
rounded_box_at(ce, 'Chair_Back', x1, y1, seat_z2, w * 1000, bt * 1000, 380, 28, M_CHAIR_FAB)
add_inflated_pillow_mesh(ce, 'Chair_Back_Pad', cx, y1 + bt + 0.025, seat_z2 + 0.18, 400, 260, 45, 0, true, M_SOFA_MAIN)
when :south
rounded_box_at(ce, 'Chair_Back', x1, y2 - bt, seat_z2, w * 1000, bt * 1000, 380, 28, M_CHAIR_FAB)
add_inflated_pillow_mesh(ce, 'Chair_Back_Pad', cx, y2 - bt - 0.025, seat_z2 + 0.18, 400, 260, 45, 180, true, M_SOFA_MAIN)
when :east
rounded_box_at(ce, 'Chair_Back', x1, y1, seat_z2, bt * 1000, d * 1000, 380, 28, M_CHAIR_FAB)
add_inflated_pillow_mesh(ce, 'Chair_Back_Pad', x1 + bt + 0.025, cy, seat_z2 + 0.18, 400, 260, 45, -90, true, M_SOFA_MAIN)
when :west
rounded_box_at(ce, 'Chair_Back', x2 - bt, y1, seat_z2, bt * 1000, d * 1000, 380, 28, M_CHAIR_FAB)
add_inflated_pillow_mesh(ce, 'Chair_Back_Pad', x2 - bt - 0.025, cy, seat_z2 + 0.18, 400, 260, 45, 90, true, M_SOFA_MAIN)
end
end
def build_luxury_bedroom_suite(parent_ents, name, z_fl, bed_wall, bx, by1, by2, ward_box, ward_facing = :south)
b_grp = parent_ents.add_group; b_grp.name = name; be = b_grp.entities
ymid = (by1 + by2) / 2.0
if bed_wall == :east
rounded_box_at(be, 'Headboard', bx - 0.09, by1, z_fl + 0.30, 90, (by2 - by1) * 1000, 1020, 32, M_SOFA_MAIN)
rounded_box_at(be, 'Bed_Frame', bx - 1.80, by1, z_fl, 1720, (by2 - by1) * 1000, 300, 28, M_WOOD_DARK)
rounded_box_at(be, 'Mattress', bx - 1.76, by1 + 0.04, z_fl + 0.30, 1660, (by2 - by1 - 0.08) * 1000, 240, 36, M_BED_WHITE)
add_inflated_pillow_mesh(be, 'Bed_Duvet', bx - 1.02, ymid, z_fl + 0.54, 1280, (by2 - by1 - 0.04) * 1000, 75, 0, false, M_PILLOW_CREAM)
rounded_box_at(be, 'Bed_Runner', bx - 1.74, by1 + 0.03, z_fl + 0.54, 520, (by2 - by1 - 0.06) * 1000, 52, 24, M_BED_THROW)
add_inflated_pillow_mesh(be, 'Sleep_Pillow_L', bx - 0.32, ymid - 0.36, z_fl + 0.58, 340, 520, 95, 0, false, M_PILLOW_CREAM)
add_inflated_pillow_mesh(be, 'Sleep_Pillow_R', bx - 0.32, ymid + 0.36, z_fl + 0.58, 340, 520, 95, 0, false, M_PILLOW_CREAM)
add_inflated_pillow_mesh(be, 'Accent_Pillow_L', bx - 0.62, ymid - 0.32, z_fl + 0.60, 300, 440, 88, -5, false, M_PILLOW_SLATE)
add_inflated_pillow_mesh(be, 'Accent_Pillow_R', bx - 0.62, ymid + 0.32, z_fl + 0.60, 300, 440, 88, 5, false, M_PILLOW_SAGE)
add_box(be, bx - 0.48, by1 - 0.42, bx, by1 - 0.04, z_fl + 0.20, z_fl + 0.48, M_WOOD_OAK)
add_box(be, bx - 0.48, by2 + 0.04, bx, by2 + 0.42, z_fl + 0.20, z_fl + 0.48, M_WOOD_OAK)
add_table_lamp(be, bx - 0.24, by1 - 0.23, z_fl + 0.48)
add_table_lamp(be, bx - 0.24, by2 + 0.23, z_fl + 0.48)
else
rounded_box_at(be, 'Headboard', bx, by1, z_fl + 0.30, 90, (by2 - by1) * 1000, 1020, 32, M_SOFA_MAIN)
rounded_box_at(be, 'Bed_Frame', bx + 0.08, by1, z_fl, 1540, (by2 - by1) * 1000, 300, 28, M_WOOD_DARK)
rounded_box_at(be, 'Mattress', bx + 0.10, by1 + 0.04, z_fl + 0.30, 1480, (by2 - by1 - 0.08) * 1000, 240, 36, M_BED_WHITE)
add_inflated_pillow_mesh(be, 'Bed_Duvet', bx + 0.92, ymid, z_fl + 0.54, 1180, (by2 - by1 - 0.04) * 1000, 75, 0, false, M_PILLOW_CREAM)
rounded_box_at(be, 'Bed_Runner', bx + 1.12, by1 + 0.03, z_fl + 0.54, 460, (by2 - by1 - 0.06) * 1000, 52, 24, M_BED_THROW)
add_inflated_pillow_mesh(be, 'Sleep_Pillow_L', bx + 0.32, ymid - 0.36, z_fl + 0.58, 340, 520, 95, 0, false, M_PILLOW_CREAM)
add_inflated_pillow_mesh(be, 'Sleep_Pillow_R', bx + 0.32, ymid + 0.36, z_fl + 0.58, 340, 520, 95, 0, false, M_PILLOW_CREAM)
add_inflated_pillow_mesh(be, 'Accent_Pillow_L', bx + 0.62, ymid - 0.32, z_fl + 0.60, 300, 440, 88, -5, false, M_PILLOW_SLATE)
add_inflated_pillow_mesh(be, 'Accent_Pillow_R', bx + 0.62, ymid + 0.32, z_fl + 0.60, 300, 440, 88, 5, false, M_PILLOW_SAGE)
add_box(be, bx, by1 - 0.40, bx + 0.45, by1 - 0.04, z_fl + 0.20, z_fl + 0.48, M_WOOD_OAK)
add_box(be, bx, by2 + 0.04, bx + 0.45, by2 + 0.40, z_fl + 0.20, z_fl + 0.48, M_WOOD_OAK)
add_table_lamp(be, bx + 0.22, by1 - 0.22, z_fl + 0.48)
add_table_lamp(be, bx + 0.22, by2 + 0.22, z_fl + 0.48)
end
wx1, wy1, wx2, wy2 = ward_box
add_box(be, wx1, wy1, wx2, wy2, z_fl, z_fl + 2.38, M_WOOD_DARK, 'Wardrobe_Carcass')
if ward_facing == :west
w_mid_y = (wy1 + wy2) / 2.0
add_box(be, wx1 - 0.02, wy1 + 0.04, wx1, w_mid_y - 0.01, z_fl + 0.08, z_fl + 2.32, M_WOOD_OAK)
add_box(be, wx1 - 0.02, w_mid_y + 0.01, wx1, wy2 - 0.04, z_fl + 0.08, z_fl + 2.32, M_WOOD_OAK)
add_box(be, wx1 - 0.025, wy1 + 0.16, wx1 - 0.02, w_mid_y - 0.12, z_fl + 0.30, z_fl + 2.10, M_MIRROR)
add_box(be, wx1 - 0.025, w_mid_y + 0.12, wx1 - 0.02, wy2 - 0.16, z_fl + 0.30, z_fl + 2.10, M_MIRROR)
add_box(be, wx1 - 0.04, w_mid_y - 0.06, wx1 - 0.02, w_mid_y - 0.04, z_fl + 0.85, z_fl + 1.45, M_BRASS)
add_box(be, wx1 - 0.04, w_mid_y + 0.04, wx1 - 0.02, w_mid_y + 0.06, z_fl + 0.85, z_fl + 1.45, M_BRASS)
else
add_box(be, wx1 + 0.04, wy1 - 0.02, wx2 - 0.04, wy1, z_fl + 0.08, z_fl + 2.32, M_WOOD_OAK)
end
end
gf_furn_grp = ents.add_group; gf_furn_grp.name = '07_GF_Interior_Furniture_by_Room'; gf_furn_grp.layer = L_GF_FURN; gffe_furn = gf_furn_grp.entities
liv_grp = gffe_furn.add_group; liv_grp.name = 'Room_GF_Living'; le = liv_grp.entities
add_box(le, 3.65, 2.15, 6.85, 4.25, 0.02, 0.028, M_RUG, 'Living_Area_Rug')
rounded_box_at(le, 'Living_Sectional_Low_Base', 4.68, 2.16, 0.105, 1400, 810, 185, 58, M_SOFA_MAIN)
rounded_box_at(le, 'Living_Chaise_Low_Base', 6.08, 2.25, 0.105, 750, 1660, 185, 58, M_SOFA_MAIN)
[[4.86, 2.22], [5.88, 2.22], [4.86, 2.86], [5.88, 2.86], [6.48, 2.35], [6.48, 3.72]].each_with_index do |(lx, ly), i|
tapered_leg_at(le, "Sofa_Leg_#{i + 1}", lx, ly, 0.028, 28, 42, 78, M_METAL_BLK)
end
rounded_box_at(le, 'Living_Sectional_Left_Arm', 4.60, 2.08, 0.11, 180, 850, 610, 68, M_SOFA_MAIN)
rounded_box_at(le, 'Living_Chaise_Outer_Arm', 6.745, 2.24, 0.11, 175, 1690, 610, 68, M_SOFA_MAIN)
rounded_box_at(le, 'Living_Sectional_Back_Rail',4.60, 2.08, 0.11, 2320, 170, 565, 60, M_SOFA_MAIN)
add_inflated_pillow_mesh(le, 'Living_Seat_L', 5.09, 2.60, 0.29, 650, 660, 118, 0, false, M_SOFA_MAIN)
add_inflated_pillow_mesh(le, 'Living_Seat_C', 5.75, 2.60, 0.29, 650, 660, 118, 0, false, M_SOFA_MAIN)
add_inflated_pillow_mesh(le, 'Living_Chaise_Seat', 6.42, 3.09, 0.29, 650, 1540, 118, 0, false, M_SOFA_MAIN)
[[5.09, 2.34], [5.75, 2.34], [6.40, 2.34]].each_with_index do |(px, py), i|
add_inflated_pillow_mesh(le, "Living_Back_Pad_#{i + 1}", px, py, 0.56, 600, 350, 105, 0, true, M_SOFA_MAIN)
end
add_inflated_pillow_mesh(le, 'Living_Chaise_Back', 6.72, 3.10, 0.56, 600, 350, 105, 90, true, M_SOFA_MAIN)
add_inflated_pillow_mesh(le, 'Scatter_Navy', 4.94, 2.42, 0.49, 440, 340, 95, 12, true, M_PILLOW_SLATE)
add_inflated_pillow_mesh(le, 'Scatter_Pink', 5.39, 2.42, 0.49, 420, 330, 92, -8, true, M_PILLOW_PINK)
add_inflated_pillow_mesh(le, 'Scatter_Rust', 5.88, 2.42, 0.49, 420, 330, 92, 10, true, M_PILLOW_RUST)
add_inflated_pillow_mesh(le, 'Scatter_Cream', 6.37, 2.43, 0.49, 450, 340, 95, -14, true, M_PILLOW_CREAM)
add_inflated_pillow_mesh(le, 'Scatter_Sage', 6.64, 3.35, 0.49, 440, 340, 95, 85, true, M_PILLOW_SAGE)
add_box(le, 4.95, 3.20, 5.72, 3.80, 0.028, 0.34, M_METAL_BLK)
rounded_box_at(le, 'Coffee_Table_Top', 4.91, 3.17, 0.34, 850, 660, 38, 18, M_MARBLE_WHT)
add_box(le, 5.45, 3.45, 5.95, 3.95, 0.028, 0.26, M_BRASS)
rounded_box_at(le, 'Nesting_Table_Top', 5.43, 3.43, 0.26, 540, 540, 28, 16, M_MARBLE_DRK)
rounded_box_at(le, 'Art_Book_1', 5.05, 3.30, 0.378, 230, 165, 22, 6, M_PILLOW_SLATE)
rounded_box_at(le, 'Art_Book_2', 5.07, 3.31, 0.400, 200, 150, 18, 6, M_MUSTARD)
revolve_open_hollow_mesh(le, 'Coffee_Bowl', [[0, 0], [105, 0], [138, 28], [128, 52], [0, 48]], M_FIXTURE, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(5.48.m, 3.52.m, 0.378.m)))
cylinder_mm(le, 'Side_Table_Top', 235, 24, M_WOOD_OAK, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(4.08.m, 3.30.m, 0.455.m)))
3.times do |i|
a = i * 120.0 * Math::PI / 180.0
tapered_leg_at(le, "Side_Table_Leg_#{i + 1}", 4.08 + 0.14 * Math.cos(a), 3.30 + 0.14 * Math.sin(a), 0.028, 22, 32, 427, M_WOOD_DARK)
end
add_tabletop_plant(le, 4.08, 3.30, 0.479)
add_box(le, 3.225, 2.55, 3.26, 4.45, 0.02, 2.85, M_WOOD_DARK)
add_box(le, 3.26, 3.00, 3.30, 4.00, 0.55, 2.65, M_MARBLE_DRK)
add_box(le, 3.26, 2.62, 3.68, 4.38, 0.18, 0.46, M_WOOD_DARK)
add_box(le, 3.26, 2.61, 3.70, 4.39, 0.46, 0.49, M_MARBLE_WHT)
add_box(le, 3.30, 3.08, 3.34, 3.94, 0.88, 1.52, M_METAL_BLK, 'OLED_TV')
add_split_ac_unit(le, 3.260, 3.52, 2.56, 90)
din_grp = gffe_furn.add_group; din_grp.name = 'Room_GF_Dining_and_Kitchen'; de = din_grp.entities
add_box(de, 4.88, 5.05, 5.38, 5.55, 0.02, 0.05, M_BRASS)
add_box(de, 4.96, 5.12, 5.30, 5.48, 0.05, 0.71, M_WOOD_DARK)
rounded_box_at(de, 'Dining_Table_Quartz_Slab', 4.56, 4.74, 0.71, 1140, 1120, 45, 24, M_MARBLE_WHT)
add_designer_chair(de, 'Dining_Chair_S', 5.13, 4.42, 0.02, :north)
add_designer_chair(de, 'Dining_Chair_N', 5.13, 6.18, 0.02, :south)
add_designer_chair(de, 'Dining_Chair_W', 4.24, 5.30, 0.02, :east)
add_designer_chair(de, 'Dining_Chair_E', 6.02, 5.30, 0.02, :west)
add_tabletop_plant(de, 5.02, 5.18, 0.755)
revolve_open_hollow_mesh(de, 'Dining_Bowl', [[0, 0], [110, 0], [145, 28], [136, 52], [0, 48]], M_FIXTURE, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(5.32.m, 5.36.m, 0.755.m)))
cylinder_mm(de, 'Pendant_Canopy', 85, 22, M_BRASS, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(5.13.m, 5.30.m, 2.82.m)))
cylinder_between_mm(de, 'Pendant_Rod', [5130, 5300, 1780], [5130, 5300, 2820], 8, M_METAL_BLK, 16)
revolve_open_hollow_mesh(de, 'Pendant_Shade', [[0, 1650], [88, 1650], [162, 1760], [148, 1785], [0, 1785]], M_BRASS, 28).transform!(Geom::Transformation.translation(Geom::Vector3d.new(5.13.m, 5.30.m, 0.0.m)))
cylinder_mm(de, 'Pendant_Diffuser', 72, 14, M_LED_GLOW, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(5.13.m, 5.30.m, 1.645.m)))
kitchen_grp = de.add_group; kitchen_grp.name = 'Kitchen_Optimized_Layout'; ke = kitchen_grp.entities
k_back = 7.925
k_depth = 0.600
k_front = k_back - k_depth
fx1 = 3.225; fx2 = 3.805
p1x1 = 3.805; p1x2 = 4.410
sx1 = 4.410; sx2 = 4.890
p2x1 = 4.890; p2x2 = 5.500
hx1 = 5.500; hx2 = 5.980
ex2 = 6.185
kitchen_grp.set_attribute('Kitchen_Layout', 'guide', 'Arch Projects correct run: fridge, sink, hob')
kitchen_grp.set_attribute('Kitchen_Layout', 'landing_fridge_to_sink_mm', ((sx1 - fx2) * 1000).round)
kitchen_grp.set_attribute('Kitchen_Layout', 'landing_sink_to_hob_mm', ((hx1 - sx2) * 1000).round)
kitchen_grp.set_attribute('Kitchen_Layout', 'clearance_hob_to_end_mm', ((ex2 - hx2) * 1000).round)
kitchen_grp.set_attribute('Kitchen_Layout', 'counter_depth_mm', (k_depth * 1000).round)
ref_grp = ke.add_group; ref_grp.name = 'Kitchen_Refrigerator_Aligned_Left_End_Bay'; re_k = ref_grp.entities
add_box(re_k, fx1, k_front - 0.035, fx1 + 0.040, k_back + 0.015, 0.02, 2.62, M_CHARCOAL_CAB)
add_box(re_k, fx2 - 0.040, k_front - 0.035, fx2, k_back + 0.015, 0.02, 2.62, M_CHARCOAL_CAB)
add_box(re_k, fx1 + 0.040, k_front - 0.025, fx2 - 0.040, k_back - 0.050, 0.04, 1.90, M_CHROME, 'Refrigerator_Main_Body_Repositioned')
add_box(re_k, fx1 + 0.055, k_front - 0.070, fx1 + 0.335, k_front - 0.025, 0.84, 1.88, M_CHROME, 'Refrigerator_Fresh_Door_Left')
add_box(re_k, fx1 + 0.355, k_front - 0.070, fx2 - 0.055, k_front - 0.025, 0.84, 1.88, M_CHROME, 'Refrigerator_Fresh_Door_Right')
add_box(re_k, fx1 + 0.055, k_front - 0.070, fx2 - 0.055, k_front - 0.025, 0.08, 0.80, M_CHROME, 'Refrigerator_Freezer_Hinged_Door')
add_box(re_k, fx1 + 0.305, k_front - 0.100, fx1 + 0.335, k_front - 0.070, 0.98, 1.66, M_METAL_BLK)
add_box(re_k, fx2 - 0.085, k_front - 0.100, fx2 - 0.055, k_front - 0.070, 0.98, 1.66, M_METAL_BLK)
add_box(re_k, fx1 + 0.315, k_front - 0.100, fx1 + 0.475, k_front - 0.070, 0.66, 0.72, M_METAL_BLK)
add_box(re_k, fx1 + 0.055, k_front - 0.025, fx2 - 0.055, k_back - 0.050, 0.02, 0.04, M_METAL_BLK)
add_box(re_k, fx1 + 0.040, k_front - 0.025, fx2 - 0.040, k_back, 1.94, 2.90, M_CHARCOAL_CAB)
add_box(re_k, fx1 + 0.055, k_front - 0.070, fx1 + 0.335, k_front - 0.025, 1.99, 2.885, M_GREIGE_CAB)
add_box(re_k, fx1 + 0.355, k_front - 0.070, fx2 - 0.055, k_front - 0.025, 1.99, 2.885, M_GREIGE_CAB)
add_box(re_k, fx1 + 0.140, k_front - 0.100, fx1 + 0.230, k_front - 0.070, 2.02, 2.04, M_BRASS)
add_box(re_k, fx1 + 0.445, k_front - 0.100, fx1 + 0.535, k_front - 0.070, 2.02, 2.04, M_BRASS)
add_box(ke, fx2, k_front + 0.015, ex2, k_back, 0.02, 0.10, M_METAL_BLK)
add_box(ke, fx2, k_front, p2x2, k_back, 0.10, 0.86, M_CHARCOAL_CAB)
add_box(ke, hx2, k_front, ex2, k_back, 0.10, 0.86, M_CHARCOAL_CAB)
add_box(ke, fx2 - 0.015, k_front - 0.040, sx1, k_back, 0.86, 0.905, M_KITCHEN_TOP)
add_box(ke, sx2, k_front - 0.040, ex2 + 0.010, k_back, 0.86, 0.905, M_KITCHEN_TOP)
add_box(ke, sx1, k_front - 0.040, sx2, k_front + 0.040, 0.86, 0.905, M_KITCHEN_TOP)
add_box(ke, sx1, k_back - 0.105, sx2, k_back, 0.86, 0.905, M_KITCHEN_TOP)
sink_in1 = sx1 + 0.040; sink_in2 = sx2 - 0.040
sink_yf = k_front + 0.055; sink_yb = k_back - 0.130
add_box(ke, sink_in1, sink_yf, sink_in2, sink_yf + 0.020, 0.895, 0.915, M_CHROME)
add_box(ke, sink_in1, sink_yb - 0.020, sink_in2, sink_yb, 0.895, 0.915, M_CHROME)
add_box(ke, sink_in1, sink_yf, sink_in1 + 0.020, sink_yb, 0.895, 0.915, M_CHROME)
add_box(ke, sink_in2 - 0.020, sink_yf, sink_in2, sink_yb, 0.895, 0.915, M_CHROME)
add_box(ke, sink_in1 + 0.020, sink_yf + 0.025, sink_in1 + 0.040, sink_yb - 0.025, 0.775, 0.895, M_CHROME)
add_box(ke, sink_in2 - 0.040, sink_yf + 0.025, sink_in2 - 0.020, sink_yb - 0.025, 0.775, 0.895, M_CHROME)
add_box(ke, sink_in1 + 0.040, sink_yf + 0.020, sink_in2 - 0.040, sink_yf + 0.040, 0.775, 0.895, M_CHROME)
add_box(ke, sink_in1 + 0.040, sink_yb - 0.040, sink_in2 - 0.040, sink_yb - 0.020, 0.775, 0.895, M_CHROME)
add_box(ke, sink_in1 + 0.040, sink_yf + 0.040, sink_in2 - 0.040, sink_yb - 0.040, 0.765, 0.785, M_METAL_BLK)
sink_cx = (sx1 + sx2) * 0.5; sink_cy = (sink_yf + sink_yb) * 0.5
cylinder_mm(ke, 'Sink_Drain', 32, 4, M_CHROME, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(sink_cx.m, sink_cy.m, 0.785.m)))
fx_mm = (sink_cx * 1000).round; fy_mm = ((k_back - 0.072) * 1000).round
[[fx_mm, fy_mm, 905], [fx_mm, fy_mm, 1080], [fx_mm, fy_mm - 11, 1190], [fx_mm, fy_mm - 41, 1265], [fx_mm, fy_mm - 81, 1290], [fx_mm, fy_mm - 125, 1280], [fx_mm, fy_mm - 165, 1240], [fx_mm, fy_mm - 195, 1175]].each_cons(2).with_index do |pair, i|
cylinder_between_mm(ke, "Kitchen_Gooseneck_Faucet_#{i + 1}", pair[0], pair[1], 8.5, M_CHROME, 16)
end
cylinder_between_mm(ke, 'Kitchen_Faucet_Lever', [fx_mm + 37, fy_mm, 930], [fx_mm + 80, fy_mm, 965], 4.5, M_BRASS, 12)
8.times { |ri| add_box(ke, sink_in1 + 0.050 + ri * 0.042, sink_yf + 0.030, sink_in1 + 0.062 + ri * 0.042, sink_yb - 0.030, 0.915, 0.922, M_CHROME) }
rounded_box_at(ke, 'Oak_Cutting_Board', p2x1 + 0.040, k_front + 0.055, 0.905, 250, 200, 18, 20, M_WOOD_OAK)
revolve_open_hollow_mesh(ke, 'Sink_Soap_Pump', [[0, 0], [32, 0], [36, 95], [14, 115], [12, 145], [0, 145]], M_CHROME, 20).transform!(Geom::Transformation.translation(Geom::Vector3d.new((p2x1 + 0.18).m, (k_back - 0.085).m, 0.905.m)))
add_box(ke, fx2 - 0.015, k_front - 0.050, fx2 + 0.035, k_front - 0.020, 0.14, 0.83, M_CHARCOAL_CAB)
add_box(ke, p1x1 + 0.040, k_front - 0.050, (p1x1 + p1x2) * 0.5 - 0.015, k_front - 0.020, 0.14, 0.68, M_CHARCOAL_CAB)
add_box(ke, (p1x1 + p1x2) * 0.5 + 0.015, k_front - 0.050, p1x2 - 0.020, k_front - 0.020, 0.14, 0.68, M_CHARCOAL_CAB)
add_box(ke, p1x1 + 0.040, k_front - 0.050, p1x2 - 0.020, k_front - 0.020, 0.70, 0.83, M_CHARCOAL_CAB)
add_box(ke, p2x1 + 0.020, k_front - 0.050, p2x2 - 0.020, k_front - 0.020, 0.14, 0.35, M_CHARCOAL_CAB)
add_box(ke, p2x1 + 0.020, k_front - 0.050, p2x2 - 0.020, k_front - 0.020, 0.38, 0.57, M_CHARCOAL_CAB)
add_box(ke, p2x1 + 0.020, k_front - 0.050, p2x2 - 0.020, k_front - 0.020, 0.60, 0.83, M_CHARCOAL_CAB)
[0.245, 0.485, 0.695].each { |hz| add_box(ke, (p2x1 + p2x2) * 0.5 - 0.040, k_front - 0.080, (p2x1 + p2x2) * 0.5 + 0.040, k_front - 0.050, hz, hz + 0.02, M_BRASS) }
add_box(ke, p1x1 + 0.180, k_front - 0.070, p1x1 + 0.250, k_front - 0.050, 0.38, 0.40, M_BRASS)
add_box(ke, p1x2 - 0.250, k_front - 0.070, p1x2 - 0.180, k_front - 0.050, 0.38, 0.40, M_BRASS)
oven_grp = ke.add_group; oven_grp.name = 'Built_In_Oven_Under_Stove'; oe = oven_grp.entities
add_box(oe, hx1, k_front + 0.010, hx2, k_back - 0.025, 0.10, 0.24, M_METAL_BLK)
add_box(oe, hx1, k_back - 0.145, hx2, k_back - 0.025, 0.24, 0.86, M_METAL_BLK)
add_box(oe, hx1, k_front + 0.010, hx1 + 0.055, k_back - 0.145, 0.24, 0.86, M_METAL_BLK)
add_box(oe, hx2 - 0.055, k_front + 0.010, hx2, k_back - 0.145, 0.24, 0.86, M_METAL_BLK)
add_box(oe, hx1 + 0.055, k_front + 0.010, hx2 - 0.055, k_back - 0.145, 0.62, 0.86, M_METAL_BLK)
add_box(oe, hx1 + 0.090, k_back - 0.175, hx2 - 0.090, k_back - 0.145, 0.34, 0.56, M_LED_GLOW)
[0.34, 0.46].each { |rz| add_box(oe, hx1 + 0.065, k_front + 0.030, hx2 - 0.065, k_back - 0.215, rz, rz + 0.012, M_CHROME) }
add_box(oe, hx1 + 0.010, k_front - 0.060, hx2 - 0.010, k_front + 0.010, 0.11, 0.20, M_CHROME)
add_box(oe, hx1 + 0.010, k_front - 0.065, hx1 + 0.070, k_front + 0.010, 0.21, 0.69, M_CHROME)
add_box(oe, hx2 - 0.070, k_front - 0.065, hx2 - 0.010, k_front + 0.010, 0.21, 0.69, M_CHROME)
add_box(oe, hx1 + 0.070, k_front - 0.065, hx2 - 0.070, k_front + 0.010, 0.21, 0.26, M_CHROME)
add_box(oe, hx1 + 0.070, k_front - 0.065, hx2 - 0.070, k_front + 0.010, 0.59, 0.69, M_CHROME)
add_box(oe, hx1 + 0.080, k_front - 0.060, hx2 - 0.080, k_front - 0.040, 0.26, 0.59, M_OVEN_GLASS)
add_box(oe, hx1 + 0.045, k_front - 0.125, hx2 - 0.045, k_front - 0.097, 0.625, 0.650, M_CHROME)
add_box(oe, hx1 + 0.010, k_front - 0.065, hx2 - 0.010, k_front + 0.010, 0.70, 0.85, M_METAL_BLK)
add_box(oe, hx1 + 0.165, k_front - 0.079, hx2 - 0.165, k_front - 0.067, 0.74, 0.81, M_BURNER_RED)
[hx1 + 0.055, hx1 + 0.115, hx2 - 0.155, hx2 - 0.095].each { |kx| add_box(oe, kx, k_front - 0.103, kx + 0.042, k_front - 0.067, 0.755, 0.795, M_BRASS) }
add_box(ke, hx1, k_front, hx1 + 0.045, k_back, 0.10, 0.86, M_CHARCOAL_CAB)
add_box(ke, hx2 - 0.045, k_front, hx2, k_back, 0.10, 0.86, M_CHARCOAL_CAB)
hob_cx = (hx1 + hx2) * 0.5
rounded_box_at(ke, 'Induction_Black_Glass_Hob', hx1 + 0.020, k_front + 0.040, 0.905, ((hx2 - hx1 - 0.040) * 1000).round, 490, 8, 16, M_HOB_GLASS)
[[hob_cx - 0.12, k_front + 0.175], [hob_cx + 0.12, k_front + 0.175], [hob_cx - 0.12, k_front + 0.395], [hob_cx + 0.12, k_front + 0.395]].each_with_index do |(bx, by), i|
cylinder_mm(ke, "Induction_Ring_#{i + 1}", 62, 2.0, M_CHROME, 32).transform!(Geom::Transformation.translation(Geom::Vector3d.new(bx.m, by.m, 0.913.m)))
cylinder_mm(ke, "Induction_Core_#{i + 1}", 56, 2.2, M_HOB_GLASS, 32).transform!(Geom::Transformation.translation(Geom::Vector3d.new(bx.m, by.m, 0.9135.m)))
end
hood_cab = ke.add_group; hood_cab.name = 'Kitchen_Hanging_Cabinet_Integrated_Extractor'; hce = hood_cab.entities
add_box(hce, hx1 - 0.020, 7.52, ex2, k_back, 1.685, 2.90, M_CHARCOAL_CAB)
add_box(hce, hx1 - 0.010, 7.485, hob_cx - 0.015, 7.52, 1.700, 2.882, M_GREIGE_CAB)
add_box(hce, hob_cx + 0.015, 7.485, ex2 - 0.010, 7.52, 1.700, 2.882, M_GREIGE_CAB)
add_box(hce, 5.53, 7.905, 5.88, k_back, 1.685, 2.65, M_METAL_BLK, 'Kitchen_Extractor_Concealed_In_Cabinet_Back')
add_box(hce, hx1 - 0.020, k_front + 0.015, ex2, 7.82, 1.605, 1.685, M_CHROME, 'Under_Cabinet_Range_Hood_Attached')
add_box(hce, hx1 + 0.020, k_front + 0.035, ex2 - 0.020, k_front + 0.075, 1.600, 1.604, M_LED_GLOW)
add_box(hce, hob_cx - 0.110, 7.63, hob_cx - 0.060, 7.68, 1.680, 1.705, M_CHROME, 'Extractor_Mount_Left')
add_box(hce, hob_cx + 0.060, 7.63, hob_cx + 0.110, 7.68, 1.680, 1.705, M_CHROME, 'Extractor_Mount_Right')
[[hob_cx - 0.155, hob_cx - 0.065], [hob_cx + 0.065, hob_cx + 0.155]].each do |x1, x2|
add_box(hce, x1, 7.455, x2, 7.485, 1.718, 1.738, M_BRASS)
end
add_box(ke, 5.53, 8.155, 5.88, 8.19, 2.41, 2.65, M_METAL_BLK)
window_bridge_grp = ke.add_group; window_bridge_grp.name = 'Kitchen_Over_Window_Hanging_Cabinet_Bridge_W1'; wbe = window_bridge_grp.entities
add_box(wbe, fx2, 7.52, hx1 - 0.020, k_back, 1.685, 2.90, M_CHARCOAL_CAB)
[[fx2 + 0.030, p1x2 - 0.020], [sx1 + 0.020, sx2 - 0.020], [p2x1 + 0.020, hx1 - 0.040]].each do |(dx1, dx2)|
add_box(wbe, dx1, 7.485, dx2, 7.52, 1.700, 2.882, M_GREIGE_CAB)
add_box(wbe, (dx1 + dx2) / 2.0 - 0.045, 7.455, (dx1 + dx2) / 2.0 + 0.045, 7.485, 1.718, 1.738, M_BRASS)
end
add_box(wbe, fx2 + 0.040, 7.485, hx1 - 0.040, 7.515, 1.675, 1.684, M_LED_GLOW)
add_box(ke, fx2, 7.472, ex2, 7.485, 1.678, 1.685, M_CHARCOAL_CAB, 'Kitchen_Continuous_Aligned_Upper_Cabinet_Base')
add_box(ke, fx2 - 0.060, k_back - 0.025, fx2, k_back - 0.001, 0.905, 1.60, M_CHARCOAL_CAB, 'Kitchen_Left_Pier_Filler')
add_box(ke, fx2, k_back - 0.025, hx1 - 0.020, k_back - 0.001, 0.905, 0.945, M_SUBWAY_TILE, 'Kitchen_Under_Window_Subway_Backsplash')
add_box(ke, hx1 - 0.020, k_back - 0.025, ex2, k_back - 0.001, 0.905, 1.605, M_SUBWAY_TILE, 'Kitchen_Cooktop_Subway_Backsplash')
srv_grp = gffe_furn.add_group; srv_grp.name = 'Room_GF_Service_Area'; se_srv = srv_grp.entities
add_box(se_srv, 3.30, 8.075, 6.00, 8.65, 0.015, 0.85, M_WOOD_OAK)
add_box(se_srv, 3.28, 8.075, 6.02, 8.68, 0.85, 0.89, M_MARBLE_WHT)
add_box(se_srv, 3.45, 8.18, 4.15, 8.58, 0.89, 0.91, M_CHROME)
add_box(se_srv, 7.05, 8.075, 7.68, 8.68, 0.015, 0.86, M_CHROME, 'Washing_Machine')
add_box(se_srv, 7.20, 8.68, 7.53, 8.71, 0.25, 0.65, M_METAL_BLK)
add_box(se_srv, 7.75, 8.075, 9.85, 8.68, 0.015, 0.86, M_CANOPY)
add_box(se_srv, 8.00, 8.18, 8.75, 8.58, 0.86, 0.89, M_CHROME)
condenser_group = srv_grp.entities.add_group
condenser_group.name = 'Rear_Service_Outdoor_AC_Condenser_Cluster_Concept'
ce = condenser_group.entities
[[7.47, 'Condenser_1'], [8.48, 'Condenser_2']].each do |xleft, unit_name|
  cg = ce.add_group
  cg.name = unit_name
  e = cg.entities
  xright = xleft + 0.70
  add_box(e, xleft - 0.02, 8.89, xright + 0.02, 9.27, 0.10, 0.135, M_METAL_BLK, 'Anti_Vibration_Mounting_Base')
  [xleft + 0.055, xright - 0.075].each do |px|
    add_box(e, px, 8.91, px + 0.025, 9.23, 0.135, 0.172, M_SUV_TIRE, 'Isolator')
  end
  add_box(e, xleft, 8.92, xright, 9.25, 0.175, 0.755, M_WALL_EXT, 'Outdoor_AC_Enclosure')
  add_box(e, xleft + 0.06, 9.250, xright - 0.06, 9.258, 0.24, 0.69, M_METAL_BLK, 'Condenser_Fan_Grille')
  8.times do |j|
    x = xleft + 0.075 + j * ((0.70 - 0.15) / 7.0)
    add_box(e, x, 9.259, x + 0.012, 9.265, 0.25, 0.68, M_CHROME, "Airflow_Grille_Bar_#{j + 1}")
  end
  5.times do |j|
    z = 0.27 + j * 0.085
    add_box(e, xleft + 0.01, 8.91, xright - 0.01, 8.925, z, z + 0.010, M_METAL_BLK, "Condenser_Rear_Coil_#{j + 1}")
  end
  cg.set_attribute('MEP', 'requires_site_design', 'Verify manufacturer minimum hot-air clearance, rear firewall recirculation, line-set routes, noise and access; illustrative position only')
end
screen = ce.add_group
screen.name = 'Ventilated_Rear_Condenser_Screen'
sce = screen.entities
[7.38, 9.34].each do |x|
  add_box(sce, x, 9.48, x + 0.028, 9.515, 0.03, 0.96, M_METAL_BLK)
end
12.times do |i|
  z = 0.10 + i * 0.065
  add_box(sce, 7.40, 9.47, 9.34, 9.490, z, z + 0.022, M_WOOD_EXT, "Open_Louver_#{i + 1}")
end
condenser_group.set_attribute('MEP', 'status', 'Concept layout only. Discharge faces rear yard and not the kitchen or bathroom windows. Manufacturer discharge clearances and boundary conditions must be reviewed before installation.')

build_luxury_bedroom_suite(gffe_furn, 'Room_GF_Bedroom_1', 0.02, :east, 9.85, 2.05, 3.55, [7.88, 4.25, 9.85, 4.85], :south)
bed1_ac = add_split_ac_unit(gffe_furn, 8.78, 4.82, 2.23, 0)
bed1_ac.set_attribute('HVAC', 'airflow', 'Discharge across room from internal north wall, away from bed headboard; verify louver setup onsite')
def add_xz_extrusion(parent_ents, name, y1, y2, xz_pts, mat)
cleaned = []
xz_pts.each { |x, z| cleaned << [x.to_f, z.to_f] if cleaned.empty? || (cleaned.last[0] - x.to_f).abs > 1e-6 || (cleaned.last[1] - z.to_f).abs > 1e-6 }
return nil if cleaned.length < 3
# #region agent log
xs = cleaned.map { |p| p[0] }; zs = cleaned.map { |p| p[1] }
agent_record_box(name.to_s.empty? ? 'xz_extrusion' : name, xs.min, y1, xs.max, y2, zs.min, zs.max, 'xz')
# #endregion
grp = parent_ents.add_group; grp.name = name if name; ge = grp.entities
y_a, y_b = [y1, y2].minmax
face = ge.add_face(cleaned.map { |x, z| Geom::Point3d.new(x.m, y_a.m, z.m) })
unless face; grp.erase!; return nil; end
face.reverse! if face.normal.y < 0; face.pushpull((y_b - y_a).m)
grp.material = mat
ge.grep(Sketchup::Face).each { |f| face_mat(f, mat) unless f.deleted? }
grp
end
def add_raked_rail(parent, name, y1, y2, x1, z1, x2, z2, depth_z, mat)
z_lo1, z_hi1 = [z1, z1 + depth_z].minmax; z_lo2, z_hi2 = [z2, z2 + depth_z].minmax
add_xz_extrusion(parent, name, y1, y2, [[x1, z_lo1], [x2, z_lo2], [x2, z_hi2], [x1, z_hi1]], mat)
end
stair_grp = gffe_furn.add_group; stair_grp.name = 'Room_GF_to_2F_Staircase'; se_st = stair_grp.entities
stair_grp.set_attribute('Stair_Design', 'tread_depth_mm', 275.0)
stair_grp.set_attribute('Stair_Design', 'upper_tread_depth_mm', 280.0)
stair_grp.set_attribute('Stair_Design', 'riser_height_mm', 187.5)
stair_grp.set_attribute('Stair_Design', 'handrail_top_height_above_nosing_mm', 900.0)
stair_grp.set_attribute('Stair_Design', 'handrail_diameter_mm', 40.0)
stair_grp.set_attribute('Stair_Design', 'handrail_design_basis', 'Round graspable profile and 900 mm top height; verify dimensions, extensions, clearances, loads and local-code requirements with the authority having jurisdiction')
stair_grp.set_attribute('Stair_Design', 'winder_guard_wall_clearance_mm', 12.0)
stair_grp.set_attribute('Stair_Design', 'review_note', 'Conceptual 8 lower treads, 3 winder treads, 4 straight upper treads, protected Bedroom 2 door landing entirely inside stairwell. No living-room void encroachment; formal stair and structural compliance NOT established.')
stair_grp.set_attribute('Stair_Design', 'landing_dimensions_mm', [905, 830])
stair_grp.set_attribute('Stair_Design', 'bedroom_1_door', 'Original ground-floor door D6 remains unchanged')
stair_grp.set_attribute('Stair_Design', 'living_room_double_height', 'Unaltered')
zf = 0.020; riser = 3.000 / 16.0; going = 0.275; upper_going = 0.280; tread_t = 0.040; handrail_radius = 0.020; rail_h = 0.900 - handrail_radius; guard_h = 1.100
lower_treads = 8; upper_treads = 4
x0 = 6.775; x_land = x0 + lower_treads * going; x_east = 9.850; x_floor = x_land - upper_treads * upper_going
y_s = 4.850; y_up2 = 5.670; y_lo1 = 5.730; y_n = 6.550
z_land = zf + lower_treads * riser; z_ff2 = zf + 16 * riser
z_low_nosing = lambda { |x| zf + (x - x0) * (riser / going) }
z_up_nosing = lambda { |x| z_ff2 - (x - x_floor) * (riser / upper_going) }
low_profile = [[x0, zf], [x_land, zf], [x_land, zf + lower_treads * riser - tread_t]]
lower_treads.downto(1) do |i|
xs = x0 + (i - 1) * going
low_profile << [xs, zf + i * riser - tread_t]
low_profile << [xs, zf + (i - 1) * riser - tread_t] if i > 1
end
add_xz_extrusion(se_st, 'Lower_Flight_Closed_Carriage', y_lo1, y_n, low_profile, M_WALL_EXT)
lower_treads.times do |idx|
i = idx + 1; z_top = zf + i * riser; x_r = x0 + (i - 1) * going; x_n = x0 + i * going
add_box(se_st, x_r, y_lo1, x_n, y_n, z_top - tread_t, z_top, M_WOOD_OAK)
add_box(se_st, x_n - 0.018, y_lo1, x_n, y_n, zf + (i - 1) * riser, z_top - tread_t, M_WALL_EXT)
add_box(se_st, x_n - 0.018, y_lo1 + 0.012, x_n - 0.002, y_n - 0.012, z_top - 0.006, z_top - 0.001, M_BRASS)
end
add_box(se_st, x_land, y_s, x_east, y_n, zf, z_land - tread_t, M_WALL_EXT, 'U_Turn_Concrete_Support')
add_box(se_st, x_land - 0.018, y_lo1, x_land, y_n, zf + lower_treads * riser, z_land - tread_t, M_WALL_EXT)
centre_x = 8.925; centre_y = 5.700; radius_outer_x = 0.920; radius_outer_y = 0.850; radius_inner_x = 0.170; radius_inner_y = 0.100
3.times do |j|
angle_hi = 90.0 - j * 60.0
angle_lo = angle_hi - 60.0
z_top = z_land + (j + 1) * riser
winder = se_st.add_group
winder.name = "Stair_Turn_Winder_#{j + 1}"
we = winder.entities
outer = (0..12).map do |q|
theta = (angle_hi + (angle_lo - angle_hi) * q / 12.0) * Math::PI / 180.0
Geom::Point3d.new((centre_x + radius_outer_x * Math.cos(theta)).m, (centre_y + radius_outer_y * Math.sin(theta)).m, z_top.m)
end
inner = (0..12).map do |q|
theta = (angle_lo + (angle_hi - angle_lo) * q / 12.0) * Math::PI / 180.0
Geom::Point3d.new((centre_x + radius_inner_x * Math.cos(theta)).m, (centre_y + radius_inner_y * Math.sin(theta)).m, z_top.m)
end
support = we.add_group
support.name = "Stair_Winder_#{j + 1}_Concrete_Support"
support_face = support.entities.add_face((outer + inner).map { |p| Geom::Point3d.new(p.x, p.y, (z_land - tread_t).m) })
if support_face
support_face.reverse! if support_face.normal.z < 0
support_face.pushpull(((j + 1) * riser).m)
support.entities.grep(Sketchup::Face).each { |f| face_mat(f, M_WALL_EXT) unless f.deleted? }
end
face = we.add_face(outer + inner)
if face
face.reverse! if face.normal.z < 0
face.pushpull((-tread_t).m)
we.grep(Sketchup::Face).each { |f| face_mat(f, M_WOOD_OAK) unless f.deleted? }
end
riser_e = we.add_group; riser_e.name = 'White_Winder_Riser_Face'
rad = angle_hi * Math::PI / 180.0
x_inner = centre_x + radius_inner_x * Math.cos(rad)
y_inner = centre_y + radius_inner_y * Math.sin(rad)
x_outer = centre_x + radius_outer_x * Math.cos(rad)
y_outer = centre_y + radius_outer_y * Math.sin(rad)
r_face = riser_e.entities.add_face([
Geom::Point3d.new(x_inner.m, y_inner.m, (z_top-riser).m),
Geom::Point3d.new(x_outer.m, y_outer.m, (z_top-riser).m),
Geom::Point3d.new(x_outer.m, y_outer.m, (z_top-tread_t).m),
Geom::Point3d.new(x_inner.m, y_inner.m, (z_top-tread_t).m)])
if r_face
r_face.reverse! if r_face.normal.z < 0
r_face.material = M_WALL_EXT
r_face.back_material = M_WALL_EXT
end
winder.set_attribute('Stair_Design', 'tread_level_m', z_top)
end
add_box(se_st, x_land, y_s, x_east, y_s + 0.02, z_land - tread_t, z_land + 3 * riser, M_WALL_EXT, 'U_Turn_Low_Carriage_Edge')
up_profile = [[x_floor, z_land + 7 * riser - tread_t - 0.45], [x_land, z_land + 3 * riser - tread_t - 0.45], [x_land, z_land + 4 * riser - tread_t]]
upper_treads.times do |idx|
j = idx + 1; x_w = x_land - j * upper_going
up_profile << [x_w, z_land + (j + 3) * riser - tread_t]
up_profile << [x_w, z_land + (j + 4) * riser - tread_t] if j < upper_treads
end
add_xz_extrusion(se_st, 'Upper_Flight_Closed_Carriage', y_s, y_up2, up_profile, M_WALL_EXT)
upper_treads.times do |idx|
j = idx + 1; z_top = z_land + (j + 3) * riser; x_e = x_land - (j - 1) * upper_going; x_w = x_land - j * upper_going
add_box(se_st, x_w, y_s, x_e, y_up2, z_top - tread_t, z_top, M_WOOD_OAK)
add_box(se_st, x_e - 0.016, y_s, x_e, y_up2, z_top - riser, z_top - tread_t, M_WALL_EXT, "Upper_Flight_White_Riser_#{j}")
add_box(se_st, x_w, y_s + 0.012, x_w + 0.016, y_up2 - 0.012, z_top - 0.006, z_top - 0.001, M_BRASS)
end
add_box(se_st, x_floor, y_s, x_floor + 0.006, y_up2, z_land + 7 * riser, z_ff2, M_WALL_EXT)
add_box(se_st, x_floor - 0.020, y_s, x_floor, y_up2, z_ff2 - 0.005, z_ff2, M_WOOD_OAK)
lower_rail_y = 6.380
upper_rail_y = 5.020
cylinder_between_mm(se_st, 'Handrail_Lower_Outer', [x0 * 1000, lower_rail_y * 1000, (z_low_nosing.call(x0) + rail_h) * 1000], [x_land * 1000, lower_rail_y * 1000, (z_land + rail_h) * 1000], handrail_radius * 1000, M_WOOD_DARK, 24)
cylinder_between_mm(se_st, 'Handrail_Upper_Outer', [x_floor * 1000, upper_rail_y * 1000, (z_up_nosing.call(x_floor) + rail_h) * 1000], [x_land * 1000, upper_rail_y * 1000, (z_up_nosing.call(x_land) + rail_h) * 1000], handrail_radius * 1000, M_WOOD_DARK, 24)
[7.05, 7.86, 8.77].each_with_index do |bx, i|
  bz = z_low_nosing.call(bx) + rail_h
  cylinder_between_mm(se_st, "Stair_Lower_Handrail_Wall_Bracket_#{i + 1}", [bx * 1000, 6395, bz * 1000], [bx * 1000, 6450, bz * 1000], 9, M_CHROME, 12)
end
[8.02, 8.42, 8.82].each_with_index do |bx, i|
  bz = z_up_nosing.call(bx) + rail_h
  cylinder_between_mm(se_st, "Stair_Upper_Handrail_Wall_Bracket_#{i + 1}", [bx * 1000, 5005, bz * 1000], [bx * 1000, 4950, bz * 1000], 9, M_CHROME, 12)
end
turn_guard_grp = se_st.add_group
turn_guard_grp.name = 'Stair_Winder_Outer_Edge_Continuous_Glass_Guard'
tg = turn_guard_grp.entities
outer_guard_rx = radius_outer_x - 0.018
outer_guard_ry = radius_outer_y - 0.018
outer_guard_north_wall_y = 6.45
outer_guard_south_wall_y = 4.95
outer_guard_panels = 3
outer_guard_segments = 16
outer_guard_base_gap = 0.008
outer_guard_cap_height = 0.034
outer_guard_cap_halfwidth = 0.018
outer_guard_first_angle = Math.asin((outer_guard_north_wall_y - 0.030 - centre_y) / outer_guard_ry) * 180.0 / Math::PI
outer_guard_last_angle = -Math.asin((centre_y - outer_guard_south_wall_y - 0.030) / outer_guard_ry) * 180.0 / Math::PI
outer_guard_first_t = (90.0 - outer_guard_first_angle) / 60.0
outer_guard_last_t = (-30.0 - outer_guard_last_angle) / 60.0
outer_guard_arc = lambda do |a, radial_offset = 0.0|
  theta = a * Math::PI / 180.0
  [centre_x + (outer_guard_rx + radial_offset) * Math.cos(theta), centre_y + (outer_guard_ry + radial_offset) * Math.sin(theta)]
end
outer_guard_top_z = lambda do |j, u|
  z_land + (j + 1.0 + (j < 2 ? u : 0.0)) * riser + guard_h
end
outer_guard_panels.times do |j|
  panel = tg.add_group
  panel.name = "Stair_Winder_Outer_Guard_Panel_#{j + 1}"
  pe = panel.entities.add_group.entities
  shoe_ents = panel.entities.add_group.entities
  cap_ents = panel.entities.add_group.entities
  tread_level = z_land + (j + 1) * riser
  panel_t_start = j.zero? ? outer_guard_first_t : 0.0
  panel_t_end = j == outer_guard_panels - 1 ? outer_guard_last_t : 1.0
  (0...outer_guard_segments).each do |k|
    t0 = panel_t_start + (panel_t_end - panel_t_start) * k.to_f / outer_guard_segments
    t1 = panel_t_start + (panel_t_end - panel_t_start) * (k + 1.0) / outer_guard_segments
    a0 = 90.0 - 60.0 * (j + t0)
    a1 = 90.0 - 60.0 * (j + t1)
    x0g, y0g = outer_guard_arc.call(a0)
    x1g, y1g = outer_guard_arc.call(a1)
    top0 = outer_guard_top_z.call(j, t0)
    top1 = outer_guard_top_z.call(j, t1)
    bottom_z = tread_level + outer_guard_base_gap
    low0 = Geom::Point3d.new(x0g.m, y0g.m, bottom_z.m)
    low1 = Geom::Point3d.new(x1g.m, y1g.m, bottom_z.m)
    high0 = Geom::Point3d.new(x0g.m, y0g.m, (top0 - outer_guard_cap_height).m)
    high1 = Geom::Point3d.new(x1g.m, y1g.m, (top1 - outer_guard_cap_height).m)
    f = pe.add_face(low0, low1, high1, high0)
    if f
      f.material = M_RAIL_GLASS
      f.back_material = M_RAIL_GLASS
    end
    shoe0 = Geom::Point3d.new(x0g.m, y0g.m, (bottom_z - 0.005).m)
    shoe1 = Geom::Point3d.new(x1g.m, y1g.m, (bottom_z - 0.005).m)
    shoe2 = Geom::Point3d.new(x1g.m, y1g.m, (bottom_z + 0.030).m)
    shoe3 = Geom::Point3d.new(x0g.m, y0g.m, (bottom_z + 0.030).m)
    f = shoe_ents.add_face(shoe0, shoe1, shoe2, shoe3)
    if f
      f.material = M_METAL_BLK
      f.back_material = M_METAL_BLK
    end
    inner0x, inner0y = outer_guard_arc.call(a0, -outer_guard_cap_halfwidth)
    inner1x, inner1y = outer_guard_arc.call(a1, -outer_guard_cap_halfwidth)
    outer0x, outer0y = outer_guard_arc.call(a0, outer_guard_cap_halfwidth)
    outer1x, outer1y = outer_guard_arc.call(a1, outer_guard_cap_halfwidth)
    t0a = Geom::Point3d.new(inner0x.m, inner0y.m, top0.m)
    t0b = Geom::Point3d.new(outer0x.m, outer0y.m, top0.m)
    t1a = Geom::Point3d.new(inner1x.m, inner1y.m, top1.m)
    t1b = Geom::Point3d.new(outer1x.m, outer1y.m, top1.m)
    b0a = Geom::Point3d.new(inner0x.m, inner0y.m, (top0 - outer_guard_cap_height).m)
    b0b = Geom::Point3d.new(outer0x.m, outer0y.m, (top0 - outer_guard_cap_height).m)
    b1a = Geom::Point3d.new(inner1x.m, inner1y.m, (top1 - outer_guard_cap_height).m)
    b1b = Geom::Point3d.new(outer1x.m, outer1y.m, (top1 - outer_guard_cap_height).m)
    [[t0a, t0b, t1b, t1a], [b0a, b1a, b1b, b0b], [t0a, t1a, b1a, b0a], [t0b, b0b, b1b, t1b]].each do |quad|
      [[quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]].each do |triangle|
        face = cap_ents.add_face(triangle)
        face_mat(face, M_WOOD_DARK) if face
      end
    end
  end
end
[0,1,2,3].each do |point_num|
  ang = if point_num.zero?
    outer_guard_first_angle
  elsif point_num == 3
    outer_guard_last_angle
  else
    90.0 - point_num * 60.0
  end
  sx, sy = outer_guard_arc.call(ang)
  step_num = [point_num + 1, 3].min
  start_z = z_land + step_num * riser + outer_guard_base_gap
  end_z = outer_guard_top_z.call([point_num, 2].min, point_num.zero? ? outer_guard_first_t : 0.0) - outer_guard_cap_height
  end_z = z_land + 3 * riser + guard_h - outer_guard_cap_height if point_num == 3
  cylinder_between_mm(tg, "Stair_Winder_Outer_Guard_Anchor_#{point_num + 1}", [sx * 1000, sy * 1000, start_z * 1000], [sx * 1000, sy * 1000, end_z * 1000], 12, M_METAL_BLK, 14)
end
cylinder_between_mm(tg, 'Stair_Winder_Center_Gap_Protected_Newel', [centre_x * 1000, centre_y * 1000, (z_land - 0.035) * 1000], [centre_x * 1000, centre_y * 1000, (z_land + 3 * riser + guard_h) * 1000], 78, M_WOOD_DARK, 24)
turn_guard_grp.set_attribute('Stair_Guard', 'purpose', 'Outer radius falling-edge protection: tread-mounted curved glass and wood cap, with central gap protected by newel')
turn_guard_grp.set_attribute('Stair_Guard', 'design_status', 'Concept only; actual guard anchorages, stair clearance, handrails and fire-code compliance require review before construction')
add_xz_extrusion(se_st, 'Centre_Well_Glass_Guard', 5.690, 5.705, [[7.855, z_low_nosing.call(7.855) + 0.040], [x_land - 0.010, z_low_nosing.call(x_land - 0.010) + 0.040], [x_land - 0.010, z_land + 3 * riser + guard_h - 0.040], [7.855, z_up_nosing.call(7.855) + guard_h - 0.040]], M_RAIL_GLASS)
add_raked_rail(se_st, 'Centre_Guard_Cap_U', 5.678, 5.722, x_land, z_land + 3 * riser + guard_h - 0.040, 7.855, z_up_nosing.call(7.855) + guard_h - 0.040, 0.040, M_WOOD_DARK)
add_hyper_realistic_interior_glass_railing_y(se_st, 'Stair_2F_North_Well_Guard', 7.008, 5.735, 6.430, z_ff2, z_ff2 + guard_h)
add_box(se_st, 6.975, 5.735, 7.04, 5.775, z_ff2, z_ff2 + guard_h, M_METAL_BLK, 'Stair_2F_Guard_Start_Anchor')
add_box(se_st, 6.975, 6.410, 7.04, outer_guard_north_wall_y, z_ff2, z_ff2 + guard_h, M_METAL_BLK, 'Stair_2F_Guard_End_Anchor')
sf_furn_grp = ents.add_group; sf_furn_grp.name = '08_2F_Interior_Furniture_by_Room'; sf_furn_grp.layer = L_2F_FURN; sffe_furn = sf_furn_grp.entities
build_luxury_bedroom_suite(sffe_furn, 'Room_2F_Bedroom_2', 3.02, :east, 9.85, 2.05, 3.55, [7.88, 4.25, 9.85, 4.85], :south)
bed2_ac = add_split_ac_unit(sffe_furn, 7.065, 2.94, 5.25, 90)
bed2_ac.set_attribute('HVAC', 'mounting_wall', 'Bedroom 2 west interior wall')
bed2_ac.set_attribute('HVAC', 'airflow', 'Wall-mounted split indoor unit facing east, high on west bedroom wall, clear of entry and wardrobe')
build_luxury_bedroom_suite(sffe_furn, 'Room_2F_Bedroom_3', 3.02, :west, 0.15, 5.15, 6.65, [2.595, 4.65, 3.075, 6.75], :west)
bed3_ac = add_split_ac_unit(sffe_furn, 2.55, 4.10, 5.22, 180)
bed3_ac.set_attribute('HVAC', 'airflow', 'Discharge across bedroom from balcony-side south wall, not at headboard; confirm clearance above terrace door onsite')
fam_grp = sffe_furn.add_group; fam_grp.name = 'Room_2F_Family_Hall'; fme = fam_grp.entities
add_box(fme, 3.85, 5.45, 6.35, 7.65, 3.02, 3.028, M_RUG, 'Family_Hall_Rug')
rounded_box_at(fme, 'Family_Sofa_Base_L', 4.40, 7.14, 3.105, 740, 580, 205, 52, M_SOFA_MAIN)
rounded_box_at(fme, 'Family_Sofa_Base_R', 5.16, 7.14, 3.105, 740, 580, 205, 52, M_SOFA_MAIN)
rounded_box_at(fme, 'Family_Sofa_Back', 4.25, 7.72, 3.105, 1800, 165, 540, 52, M_SOFA_MAIN)
rounded_box_at(fme, 'Family_Sofa_Arm_L', 4.25, 7.12, 3.105, 150, 760, 555, 52, M_SOFA_MAIN)
rounded_box_at(fme, 'Family_Sofa_Arm_R', 5.90, 7.12, 3.105, 150, 760, 555, 52, M_SOFA_MAIN)
[[4.53, 7.20], [5.84, 7.20], [4.53, 7.62], [5.84, 7.62]].each_with_index do |(lx, ly), i|
tapered_leg_at(fme, "Fam_Sofa_Leg_#{i + 1}", lx, ly, 3.028, 26, 38, 78, M_METAL_BLK)
end
add_inflated_pillow_mesh(fme, 'Fam_Seat_1', 4.77, 7.43, 3.31, 710, 540, 112, 0, false, M_SOFA_MAIN)
add_inflated_pillow_mesh(fme, 'Fam_Seat_2', 5.53, 7.43, 3.31, 710, 540, 112, 0, false, M_SOFA_MAIN)
add_inflated_pillow_mesh(fme, 'Fam_Back_1', 4.77, 7.68, 3.55, 600, 350, 105, 180, true, M_SOFA_MAIN)
add_inflated_pillow_mesh(fme, 'Fam_Back_2', 5.53, 7.68, 3.55, 600, 350, 105, 180, true, M_SOFA_MAIN)
add_inflated_pillow_mesh(fme, 'Fam_Scatter_Navy', 4.92, 7.56, 3.46, 420, 330, 92, 168, true, M_PILLOW_SLATE)
add_inflated_pillow_mesh(fme, 'Fam_Scatter_Pink', 5.42, 7.56, 3.46, 420, 330, 92, 192, true, M_PILLOW_PINK)
rounded_box_at(fme, 'Fam_Coffee_Table', 4.75, 6.15, 3.028, 800, 500, 350, 18, M_MARBLE_WHT)
revolve_open_hollow_mesh(fme, 'Fam_Sculptural_Vase', [[0, 0], [72, 0], [102, 45], [116, 145], [95, 240], [42, 310], [0, 305]], M_WALL_EXT, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(5.15.m, 6.40.m, 3.378.m)))
rounded_box_at(fme, 'Fam_Side_Console', 3.25, 5.35, 3.028, 580, 1280, 420, 16, M_WOOD_OAK)
add_split_ac_unit(fme, 5.10, 7.925, 5.15, 0)
bal_grp = sffe_furn.add_group; bal_grp.name = 'Room_2F_Balcony_Bistro'; ble = bal_grp.entities
cylinder_mm(ble, 'Bistro_Table_Top', 275, 24, M_WOOD_OAK, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(1.62.m, 2.95.m, 3.725.m)))
3.times do |i|
a = i * 120.0 * Math::PI / 180.0
tapered_leg_at(ble, "Bistro_Leg_#{i + 1}", 1.62 + 0.16 * Math.cos(a), 2.95 + 0.16 * Math.sin(a), 3.015, 20, 28, 710, M_WOOD_TAN)
end
add_tabletop_plant(ble, 1.62, 2.95, 3.749)
[[0.95, 2.95, :east], [2.29, 2.95, :west]].each_with_index do |(cx, cy, dir), idx|
add_designer_chair(ble, "Balcony_Chair_#{idx + 1}", cx, cy, 3.015, dir)
end
revolve_open_hollow_mesh(ble, 'Balcony_Planter_Pot', [[0, 0], [112, 0], [132, 175], [122, 192], [0, 188]], M_WOOD_OAK, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(2.65.m, 2.38.m, 3.015.m)))
add_rosette_plant(ble, 'Balcony_Planter_Foliage', 2.65, 2.38, 3.19, 0.24, 0.34)
def build_detailed_bathroom_suite(parent_ents, name, z_fl, floor_mat = nil)
grp = parent_ents.add_group; grp.name = name; ge = grp.entities
vx = 7.56; vy = 7.845; vz = z_fl + 0.005
v_grp = ge.add_group; v_grp.name = "#{name}_Fluted_Vanity_Suite"; ve = v_grp.entities
rounded_box_at(ve, 'Vanity_Carcass', -0.39, -0.485, 0.28, 780, 480, 500, 18, M_WOOD_OAK)
[0.292, 0.538].each_with_index do |dz, di|
rounded_box_at(ve, "Drawer_#{di + 1}", -0.378, -0.499, dz, 756, 16, 230, 8, M_WOOD_OAK)
24.times { |fi| rounded_box_at(ve, "Flute_#{di}_#{fi}", -0.368 + fi * 0.031, -0.504, dz + 0.006, 18, 6, 218, 4, M_WOOD_TAN) }
cylinder_between_mm(ve, "Pull_#{di + 1}", [-90, -516, (dz + 0.195) * 1000], [90, -516, (dz + 0.195) * 1000], 4.5, M_BRASS, 14)
end
rounded_box_at(ve, 'Vanity_Quartz_Countertop', -0.40, -0.50, 0.78, 800, 505, 32, 12, M_MARBLE_WHT)
rounded_box_at(ve, 'Vanity_Quartz_Upstand', -0.40, -0.018, 0.812, 800, 18, 80, 6, M_MARBLE_WHT)
vessel_prof = [[0, 812], [108, 812], [152, 835], [178, 885], [184, 936], [177, 942], [169, 936], [156, 888], [122, 845], [70, 828], [0, 825]]
revolve_open_hollow_mesh(ve, 'Open_Hollow_Vessel_Sink', vessel_prof, M_FIXTURE, 40, 0.80).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, mm(-265), 0)))
cylinder_mm(ve, 'Vessel_Popup_Drain', 22, 5, M_BRASS, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, mm(-265), mm(825))))
[[0, -92, 812], [0, -92, 985], [0, -108, 1045], [0, -145, 1072], [0, -188, 1060], [0, -218, 1018]].each_cons(2).with_index do |pair, i|
cylinder_between_mm(ve, "Basin_Faucet_Arc_#{i + 1}", pair[0], pair[1], 9.0, M_BRASS, 16)
end
cylinder_between_mm(ve, 'Basin_Faucet_Lever', [12, -92, 865], [58, -92, 885], 4.5, M_BRASS, 12)
vertical_capsule_xz(ve, 'Mirror_Halo', -270, -6, 1040, 540, 8, 840, 260, M_LED_GLOW)
vertical_capsule_xz(ve, 'Mirror_Frame', -255, -14, 1055, 510, 14, 810, 245, M_BRASS)
vertical_capsule_xz(ve, 'Mirror_Glass', -241, -28, 1069, 482, 6, 782, 230, M_MIRROR)
revolve_open_hollow_mesh(ve, 'Vanity_Soap_Pump', [[0, 0], [30, 0], [34, 88], [12, 105], [10, 132], [0, 132]], M_CHROME, 18).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(275), mm(-185), mm(812))))
add_inflated_pillow_mesh(ve, 'Rolled_Hand_Towel', -0.28, -0.26, 0.835, 240, 105, 48, 0, false, M_PILLOW_CREAM)
v_grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(vx.m, vy.m, vz.m)))
tx = 8.46; ty = 7.845; tz = z_fl + 0.005
t_grp = ge.add_group; t_grp.name = "#{name}_Sculpted_Toilet_Suite"; te = t_grp.entities
bowl_prof = [[0, 0], [114, 0], [130, 95], [150, 210], [174, 325], [182, 382], [182, 398], [168, 402], [146, 396], [134, 335], [106, 250], [66, 195], [0, 188]]
revolve_open_hollow_mesh(te, 'Open_Hollow_Toilet_Bowl', bowl_prof, M_FIXTURE, 36, 1.28).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, mm(-370), 0)))
cylinder_mm(te, 'Toilet_Water_Seal', 76, 4, M_WATER_BLUE, 28).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, mm(-370), mm(192))) * Geom::Transformation.scaling(ORIGIN, 1.0, 1.25, 1.0))
rounded_box_at(te, 'Toilet_Rear_Pedestal', -0.108, -0.205, 0.0, 216, 205, 392, 42, M_FIXTURE)
seat_prof = [[134, 400], [184, 400], [186, 412], [174, 418], [138, 416], [132, 406], [134, 400]]
revolve_open_hollow_mesh(te, 'Contoured_Toilet_Seat', seat_prof, M_FIXTURE, 36, 1.28).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, mm(-370), 0)))
[-62, 62].each_with_index { |hx, idx| cylinder_mm(te, "Hinge_#{idx + 1}", 9, 16, M_BRASS, 16).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(hx), mm(-182), mm(398)))) }
rounded_box_at(te, 'Cistern_Tank', -0.185, -0.178, 0.392, 370, 175, 355, 34, M_FIXTURE)
rounded_box_at(te, 'Cistern_Lid', -0.193, -0.184, 0.747, 386, 188, 26, 36, M_FIXTURE)
cylinder_mm(te, 'Flush_Bezel', 30, 5, M_BRASS, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, mm(-90), mm(773))))
cylinder_mm(te, 'Half_Flush', 10, 8, M_CHROME, 20).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(-12), mm(-90), mm(773))))
cylinder_mm(te, 'Full_Flush', 13, 8, M_BRASS, 20).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(11), mm(-90), mm(773))))
cylinder_between_mm(te, 'Angle_Valve', [-210, -5, 190], [-210, -55, 190], 11, M_CHROME, 14)
cylinder_between_mm(te, 'Supply_Hose', [-210, -45, 190], [-140, -95, 395], 5, M_CHROME, 12)
cylinder_between_mm(te, 'Paper_Post', [-245, -5, 620], [-245, -75, 620], 6, M_BRASS, 12)
cylinder_between_mm(te, 'Paper_Bar', [-245, -75, 620], [-155, -75, 620], 6, M_BRASS, 12)
cylinder_between_mm(te, 'Paper_Roll', [-232, -75, 620], [-168, -75, 620], 46, M_FIXTURE, 20)
t_grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(tx.m, ty.m, tz.m)))
sx = 9.84; sy = 7.845; sz = z_fl + 0.005
s_grp = ge.add_group; s_grp.name = "#{name}_WalkIn_Rain_Shower"; se = s_grp.entities
bath_tile = floor_mat || M_TILE_BATH1
rounded_box_at(se, 'Shower_Curb', -0.92, -1.29, 0.0, 65, 1290, 48, 8, bath_tile)
rounded_box_at(se, 'Shower_Tray', -0.855,-1.29, 0.0, 855, 1290, 22, 6, bath_tile)
rounded_box_at(se, 'Linear_Drain',-0.135,-1.12, 0.022, 75, 940, 4, 4, M_CHROME)
12.times { |si| rounded_box_at(se, "Drain_Slot_#{si + 1}", -0.118, -1.095 + si * 0.076, 0.026, 42, 60, 2, 2, M_METAL_BLK) }
rounded_box_at(se, 'Glass_Screen', -0.892, -0.825, 0.048, 10, 820, 2040, 2, M_SHOWER_GL)
rounded_box_at(se, 'Glass_Frame_Bot', -0.899, -0.830, 0.048, 24, 830, 22, 3, M_METAL_BLK)
rounded_box_at(se, 'Glass_Frame_Top', -0.899, -0.830, 2.075, 24, 830, 22, 3, M_METAL_BLK)
rounded_box_at(se, 'Glass_Frame_N', -0.899, -0.022, 0.048, 24, 22, 2045, 3, M_METAL_BLK)
rounded_box_at(se, 'Glass_Frame_S', -0.899, -0.830, 0.048, 24, 22, 2045, 3, M_METAL_BLK)
cylinder_between_mm(se, 'Glass_Stabilizer', [-888, -818, 2060], [0, -818, 2060], 7.0, M_METAL_BLK, 14)
cylinder_between_mm(se, 'Shower_Towel_Bar', [-935, -750, 1020], [-935, -300, 1020], 6.5, M_BRASS, 14)
cylinder_between_mm(se, 'Towel_Mount_1', [-892, -730, 1020], [-935, -730, 1020], 5.0, M_BRASS, 12)
cylinder_between_mm(se, 'Towel_Mount_2', [-892, -320, 1020], [-935, -320, 1020], 5.0, M_BRASS, 12)
rounded_box_at(se, 'Shower_Niche_Surround', -0.032, -0.70, 1.12, 32, 480, 320, 6, M_MARBLE_WHT)
rounded_box_at(se, 'Shower_Niche_LED', -0.026, -0.675, 1.412, 18, 430, 6, 2, M_LED_GLOW)
[-590, -470, -350].each_with_index do |by, bi|
b_mat = (bi == 0 ? M_TEAL : (bi == 1 ? M_FIXTURE : M_MUSTARD))
revolve_open_hollow_mesh(se, "Shower_Bottle_#{bi + 1}", [[0, 0], [28, 0], [32, 95], [12, 115], [10, 135], [0, 135]], b_mat, 18).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(-18), mm(by), mm(1142))))
end
[-520, -340].each_with_index { |vy, vi| cylinder_between_mm(se, "Rosette_#{vi + 1}", [0, vy, 1050], [-28, vy, 1050], 28, M_BRASS, 20) }
cylinder_between_mm(se, 'Thermostatic_Bar', [-38, -555, 1050], [-38, -305, 1050], 18, M_BRASS, 20)
cylinder_between_mm(se, 'Dial_L', [-38, -555, 1050], [-38, -582, 1050], 20, M_METAL_BLK, 20)
cylinder_between_mm(se, 'Dial_R', [-38, -305, 1050], [-38, -278, 1050], 20, M_METAL_BLK, 20)
[[-38, -430, 1050], [-38, -430, 2060], [-65, -430, 2115], [-180, -430, 2130], [-420, -430, 2130], [-420, -430, 2050]].each_cons(2).with_index do |pair, i|
cylinder_between_mm(se, "Shower_Riser_#{i + 1}", pair[0], pair[1], 9.5, M_BRASS, 16)
end
cylinder_mm(se, 'Rain_Disc', 140, 12, M_BRASS, 32).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(-420), mm(-430), mm(2038))))
cylinder_mm(se, 'Rain_Nozzles', 126, 3, M_METAL_BLK, 28).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(-420), mm(-430), mm(2035))))
cylinder_between_mm(se, 'Wand_Bracket', [-38, -430, 1380], [-82, -350, 1380], 12, M_BRASS, 14)
cylinder_between_mm(se, 'Wand_Handle', [-82, -350, 1340], [-82, -350, 1470], 13, M_BRASS, 16)
revolve_open_hollow_mesh(se, 'Wand_Head', [[0, 1470], [16, 1470], [42, 1520], [42, 1555], [0, 1555]], M_BRASS, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(mm(-82), mm(-350), 0)))
[[-38, -430, 1032], [-48, -415, 900], [-65, -385, 850], [-78, -360, 1040], [-82, -350, 1340]].each_cons(2).with_index do |pair, i|
cylinder_between_mm(se, "Wand_Hose_#{i + 1}", pair[0], pair[1], 5.5, M_CHROME, 12)
end
s_grp.transform!(Geom::Transformation.translation(Geom::Vector3d.new(sx.m, sy.m, sz.m)))
rounded_box_at(ge, 'Bath_Mat', 7.28, 6.82, z_fl + 0.006, 560, 420, 9, 42, M_PILLOW_CREAM)
revolve_open_hollow_mesh(ge, 'Linen_Basket', [[0, 0], [110, 0], [135, 35], [125, 210], [108, 220], [0, 215]], M_WOOD_OAK, 24).transform!(Geom::Transformation.translation(Geom::Vector3d.new(8.02.m, 6.75.m, (z_fl + 0.006).m)))
end
build_detailed_bathroom_suite(gffe_furn, 'Room_GF_Bathroom_TB1', 0.020, M_TILE_BATH1)
build_detailed_bathroom_suite(sffe_furn, 'Room_2F_Bathroom_TB2', 3.020, M_TILE_BATH2)
def build_front_facing_bmw_x7_suv(parent_ents, layer_suv)
suv_grp = parent_ents.add_group; suv_grp.name = '09_GF_Garage_Black_SUV'; suv_grp.layer = layer_suv; se = suv_grp.entities
x_left = 0.68; x_right = 2.54; width = x_right - x_left; x_mid = (x_left + x_right) / 2.0
body_grp = se.add_group; body_grp.name = 'Black_SUV_Body_Shell'; be = body_grp.entities
profile_yz = [[0.64, 0.25], [0.56, 0.34], [0.56, 0.62], [0.58, 0.90], [0.72, 0.98], [1.92, 1.10], [2.68, 1.74], [4.95, 1.74], [5.05, 1.70], [4.82, 1.64], [5.18, 1.08], [5.22, 0.68], [5.26, 0.62], [5.26, 0.34], [5.18, 0.26]]
face = be.add_face(profile_yz.map { |(py, pz)| Geom::Point3d.new(x_left.m, py.m, pz.m) })
if face; face.reverse! if face.normal.x < 0; face.pushpull(width.m); end
body_grp.material = M_SUV_BLACK
add_box(se, x_left + 0.30, 0.68, x_right - 0.30, 1.90, 0.96, 1.03, M_SUV_BLACK)
add_box(se, 1.24, 0.535, 1.98, 0.58, 0.56, 0.91, M_CHROME)
add_box(se, 1.275, 0.530, 1.59, 0.55, 0.59, 0.88, M_SUV_TRIM)
add_box(se, 1.63, 0.530, 1.945,0.55, 0.59, 0.88, M_SUV_TRIM)
7.times do |i|
add_box(se, 1.30 + i * 0.042, 0.525, 1.314 + i * 0.042, 0.545, 0.59, 0.88, M_CHROME)
add_box(se, 1.655 + i * 0.042, 0.525, 1.669 + i * 0.042, 0.545, 0.59, 0.88, M_CHROME)
end
add_box(se, x_mid - 0.045, 0.60, x_mid + 0.045, 0.65, 0.915, 0.935, M_BMW_BLUE)
add_box(se, 0.72, 0.55, 1.24, 0.60, 0.76, 0.89, M_SUV_TRIM)
add_box(se, 0.75, 0.535, 1.21, 0.555, 0.77, 0.86, M_SUV_HEAD_W)
add_box(se, 1.98, 0.55, 2.50, 0.60, 0.76, 0.89, M_SUV_TRIM)
add_box(se, 2.01, 0.535, 2.47, 0.555, 0.77, 0.86, M_SUV_HEAD_W)
add_box(se, 0.72, 0.530, 2.50, 0.555, 0.38, 0.41, M_CHROME)
add_box(se, 1.10, 0.535, 2.12, 0.560, 0.25, 0.32, M_SUV_RIM)
[x_left - 0.008, x_right - 0.004].each do |sx|
add_box(se, sx, 2.15, sx + 0.012, 4.78, 1.09, 1.62, M_SUV_GLASS)
add_box(se, sx - 0.004, 2.10, sx + 0.016, 4.82, 1.07, 1.09, M_CHROME)
add_box(se, sx - 0.004, 2.45, sx + 0.016, 4.80, 1.62, 1.64, M_CHROME)
end
fw_grp = se.add_group
fw_face = fw_grp.entities.add_face([Geom::Point3d.new((x_left + 0.08).m, 1.94.m, 1.12.m), Geom::Point3d.new((x_left + 0.08).m, 2.67.m, 1.70.m), Geom::Point3d.new((x_left + 0.08).m, 2.65.m, 1.72.m), Geom::Point3d.new((x_left + 0.08).m, 1.92.m, 1.14.m)])
fw_face.reverse! if fw_face.normal.x < 0; fw_face.pushpull((width - 0.16).m); fw_grp.material = M_SUV_GLASS
[[0.63, 1.50, true], [2.59, 1.50, false], [0.63, 4.42, true], [2.59, 4.42, false]].each_with_index do |(wx, wy, is_west), idx|
w_grp = se.add_group; w_grp.name = "BMW_Wheel_#{idx + 1}"; we = w_grp.entities
x_in = is_west ? (wx + 0.27) : (wx - 0.27)
x_xmin, _ = [wx, x_in].minmax
f_t = we.add_face((0...24).map { |i| a = i * 2.0 * Math::PI / 24; Geom::Point3d.new(x_xmin.m, (wy + 0.39 * Math.cos(a)).m, (0.39 + 0.39 * Math.sin(a)).m) })
if f_t; f_t.reverse! if f_t.normal.x < 0; f_t.pushpull(0.27.m); end
w_grp.material = M_SUV_TIRE
end
end
build_front_facing_bmw_x7_suv(ents, L_SUV)
opts = model.rendering_options
{
'EdgeDisplayMode' => 0, 'DrawSilhouettes' => false, 'DrawProfilesOnly' => false,
'DisplaySectionPlanes' => false, 'DisplaySectionCuts' => false,
'RenderMode' => 3, 'Texture' => true, 'AmbientOcclusion' => false,
'BackgroundColor' => Sketchup::Color.new(246, 244, 240),
'FaceFrontColor' => Sketchup::Color.new(250, 249, 246),
'FaceBackColor' => Sketchup::Color.new(242, 240, 235)
}.each { |k, v| opts[k] = v if opts.keys.include?(k) }
model.styles.update_selected_style if model.styles.respond_to?(:update_selected_style)
sh_global = model.shadow_info
sh_global['DisplayShadows'] = false
sh_global['UseSunForAllShading'] = false if sh_global.keys.include?('UseSunForAllShading')
sh_global['Light'] = 88
sh_global['Dark'] = 84
sh_global['EdgesCastShadows'] = false if sh_global.keys.include?('EdgesCastShadows')
pages = model.pages
pages.to_a.each { |p| pages.erase(p) }
all_layers = [L_SUV, L_SITE, L_FENCE, L_PERIM, L_GF_EXT, L_GF_WALLS, L_GF_FURN, L_2F_SLAB, L_2F_EXT, L_2F_WALLS, L_2F_FURN, L_ROOF]
def create_scene_tab(model, name, eye_pt, target_pt, fov_deg, all_layers, hidden_layers = [])
page = model.pages.add(name)
cam = page.camera
up_vec = (eye_pt.x == target_pt.x && eye_pt.y == target_pt.y) ? Y_AXIS : Z_AXIS
cam.set(eye_pt, target_pt, up_vec)
cam.perspective = true
cam.fov = fov_deg
all_layers.each { |l| page.set_visibility(l, !hidden_layers.include?(l)) }
page.use_camera = true
page.use_hidden_layers = true
page.use_style = true
page.use_rendering_options = true
page.use_shadow_info = true
sh = page.shadow_info
sh['DisplayShadows'] = false
sh['UseSunForAllShading'] = false if sh.keys.include?('UseSunForAllShading')
sh['Light'] = 88
sh['Dark'] = 84
page
end
create_scene_tab(model, '1_Full_Exterior', Geom::Point3d.new(3.2.m, -9.5.m, 4.2.m), Geom::Point3d.new(5.2.m, 4.0.m, 3.0.m), 50.0, all_layers, [])
create_scene_tab(model, '2_Exterior_No_SUV', Geom::Point3d.new(3.2.m, -9.5.m, 4.2.m), Geom::Point3d.new(5.2.m, 4.0.m, 3.0.m), 50.0, all_layers, [L_SUV])
create_scene_tab(model, '3_Dollhouse_2nd_Floor', Geom::Point3d.new(5.0.m, -3.5.m, 12.5.m),Geom::Point3d.new(5.0.m, 5.2.m, 3.2.m), 50.0, all_layers, [L_ROOF])
create_scene_tab(model, '4_Dollhouse_Ground_Floor', Geom::Point3d.new(5.0.m, -3.0.m, 11.5.m),Geom::Point3d.new(5.0.m, 5.2.m, 0.8.m), 50.0, all_layers, [L_ROOF, L_2F_SLAB, L_2F_EXT, L_2F_WALLS, L_2F_FURN])
create_scene_tab(model, '5_Front_Cutaway_Section', Geom::Point3d.new(5.0.m, -6.5.m, 3.6.m), Geom::Point3d.new(5.0.m, 5.5.m, 2.4.m), 50.0, all_layers, [L_FENCE, L_GF_EXT, L_2F_EXT])
create_scene_tab(model, '6_Rear_Exterior', Geom::Point3d.new(3.5.m, 18.5.m, 5.8.m), Geom::Point3d.new(5.0.m, 5.5.m, 2.8.m), 50.0, all_layers, [])
[
['01_Living', [6.65, 4.12, 1.52], [5.35, 3.05, 0.85]],
['02_Kitchen', [5.10, 6.40, 1.52], [5.05, 7.60, 1.22]],
['03_Dining', [4.18, 4.85, 1.52], [5.12, 5.28, 1.10]],
['04_Bedroom1', [7.48, 3.28, 1.52], [9.10, 3.10, 1.05]],
['05_Bedroom2', [7.52, 2.45, 4.52], [9.18, 3.10, 3.85]],
['06_MasterBedroom', [0.72, 6.95, 4.52], [1.95, 5.95, 3.80]],
['07_Bathroom1', [7.20, 6.72, 1.48], [8.70, 7.58, 1.05]],
['08_Bathroom2', [7.20, 6.72, 4.48], [8.70, 7.58, 4.05]],
['09_Porch', [3.85, 0.55, 1.48], [3.95, 1.85, 1.12]],
['10_Balcony', [1.62, 2.02, 4.38], [1.62, 3.45, 3.65]],
['11_StairLanding', [8.72, 5.12, 3.21], [7.50, 5.72, 2.25]],
['12_FamilyHall', [4.12, 6.08, 4.52], [5.20, 7.20, 3.70]]
].each do |(sname, eye, tgt)|
create_scene_tab(model, sname, Geom::Point3d.new(eye[0].m, eye[1].m, eye[2].m), Geom::Point3d.new(tgt[0].m, tgt[1].m, tgt[2].m), 65.0, all_layers, [L_SUV, L_ROOF])
end
model.pages.selected_page = model.pages['11_StairLanding'] if model.pages['11_StairLanding']
model.active_view.refresh if model.active_view
# #region agent log
begin
  def agent_cls(n)
    s = n.to_s
    return 'rail' if s =~ /Rail|Guard|Handrail|Balustrade|Newel/i
    return 'wall' if s =~ /Wall_Solid_|Wall_|Facade|Spandrel/i || s.start_with?('Wall_')
    return 'slab' if s =~ /Slab|Tiles|Tiled|Floor|Landing_Tiles|Carriage|Concrete/i
    return 'ceil' if s =~ /Canopy|Soffit|Ceiling|Roof_/i
    return 'stair' if s =~ /Stair|Winder|U_Turn/i
    'other'
  end
  overlaps = []
  boxes = $agent_arch_boxes
  n = boxes.length
  (0...n).each do |i|
    a = boxes[i]
    ((i + 1)...n).each do |j|
      b = boxes[j]
      next if a['name'] == b['name'] && a['src'] == b['src'] && (a['xmin'] - b['xmin']).abs < 1e-6 && (a['ymin'] - b['ymin']).abs < 1e-6 && (a['zmin'] - b['zmin']).abs < 1e-6
      ox = [[a['xmax'], b['xmax']].min - [a['xmin'], b['xmin']].max, 0.0].max
      oy = [[a['ymax'], b['ymax']].min - [a['ymin'], b['ymin']].max, 0.0].max
      oz = [[a['zmax'], b['zmax']].min - [a['zmin'], b['zmin']].max, 0.0].max
      ov = ox * oy * oz
      next if ov < 0.002
      next if ox < 0.012 || oy < 0.012 || oz < 0.012
      ca = agent_cls(a['name']); cb = agent_cls(b['name'])
      pair = [ca, cb].sort
      hyp = if pair == ['slab', 'wall'] then 'A'
            elsif pair == ['rail', 'rail'] || pair == ['rail', 'wall'] then 'B'
            elsif a['name'] =~ /unnamed_/ && b['name'] =~ /unnamed_/ then 'C'
            elsif pair.include?('stair') then 'D'
            elsif pair == ['slab', 'slab'] || pair.include?('ceil') then 'E'
            else 'C'
            end
      overlaps << { 'hyp' => hyp, 'vol' => ov.round(4), 'ox' => ox.round(3), 'oy' => oy.round(3), 'oz' => oz.round(3), 'a' => a['name'], 'b' => b['name'], 'az' => [a['zmin'].round(3), a['zmax'].round(3)], 'bz' => [b['zmin'].round(3), b['zmax'].round(3)] }
    end
  end
  overlaps.sort_by! { |o| -o['vol'] }
  counts = { 'A' => 0, 'B' => 0, 'C' => 0, 'D' => 0, 'E' => 0 }
  overlaps.each { |o| counts[o['hyp']] += 1 }
  agent_dbg('A', 'sketchupBambanin.rb:overlap_audit', 'overlap_summary', { 'box_count' => n, 'overlap_count' => overlaps.length, 'counts' => counts, 'top' => overlaps.first(25) })
rescue StandardError => audit_err
  agent_dbg('A', 'sketchupBambanin.rb:overlap_audit', 'audit_failed', { 'error' => audit_err.message })
end
# #endregion
model.commit_operation
puts '===================================================================='
puts 'COMBINED MINIMAL ELEGANT EXTERIOR + UPGRADED INTERIOR COMPLETE!'
puts '- Exterior: Minimal Elegant V6 Architecture, Gardens, Charcoal Roof & Black SUV.'
puts '- Floors: Pietrasanta 35x35 in Bath 1, Aston Nature 47x47 in Bath 2,'
puts '  SPC light-oak planks in all bedrooms, Porcelanato 60x60 on GF and 2F hall.'
puts '  No checkerboard placeholder tiles. All windows are operable (slide/awning).'
puts '- Kitchen: fridge | >600mm | sink | >600mm | hob | >200mm, 600mm-deep counters.'
puts '- Interior: bathroom render scenes, fluted vanity, rain shower, dining pendant.'
puts '===================================================================='
rescue StandardError => err
model.abort_operation
puts "BUILD FAILED: #{err.class}: #{err.message}"
puts err.backtrace.join("\n") if err.backtrace
raise
end
require 'tmpdir'
model = Sketchup.active_model
raise 'No active SketchUp model.' unless model
house = model.entities.grep(Sketchup::Group).find { |g| g.name == 'House_10x10_Model' }
raise 'House_10x10_Model was not found. Please run this on your open house model.' unless house
module CaneBedroomSurgicalPatch
extend self
def m(v); v.to_f.m; end
def mm(v); v.to_f.mm; end
def write_bmp(filename, width, height, &pixel_block)
path = File.join(Dir.tmpdir, filename)
row_bytes = width * 3
padding = (4 - (row_bytes % 4)) % 4
data_size = (row_bytes + padding) * height
file_size = 54 + data_size
File.open(path, 'wb') do |f|
f.write(['BM', file_size, 0, 0, 54, 40, width, height, 1, 24, 0, data_size, 2835, 2835, 0, 0].pack('A2Vv2V2l2v2V6'))
pad = "\x00" * padding
(0...height).each do |y|
row = String.new('', encoding: 'ASCII-8BIT')
(0...width).each do |x|
r, g, b = pixel_block.call(x, y, width, height)
row << [[[b.round, 0].max, 255].min, [[g.round, 0].max, 255].min, [[r.round, 0].max, 255].min].pack('C3')
end
row << pad if padding > 0
f.write(row)
end
end
path
rescue StandardError
nil
end
def generate_cane_webbing_bmp
write_bmp('Bedroom_Cane_Webbing_Mesh.bmp', 128, 128) do |x, y, _w, _h|
cell = 16
cx = (x % cell) - (cell / 2.0)
cy = (y % cell) - (cell / 2.0)
dist = Math.sqrt(cx * cx + cy * cy)
diag1 = ((x + y) % cell - (cell / 2.0)).abs
diag2 = ((x - y) % cell - (cell / 2.0)).abs
if dist < 3.6
[118, 102, 84]
elsif cx.abs < 1.8 || cy.abs < 1.8 || diag1 < 1.6 || diag2 < 1.6
shade = Math.sin((x + y) * 0.4) * 6.0
[208 + shade, 188 + shade, 158 + shade]
else
[186, 166, 138]
end
end
end
def generate_weathered_oak_bmp
write_bmp('Bedroom_Weathered_Light_Oak.bmp', 128, 128) do |x, y, _w, _h|
grain = Math.sin(y * 0.18 + Math.sin(x * 0.08) * 2.5) * 6.5
fine = Math.cos(x * 0.9 + y * 0.05) * 2.5
[196 + grain + fine, 176 + grain + fine, 152 + grain + fine]
end
end
def generate_boho_medallion_rug_bmp
write_bmp('Bedroom_Boho_Medallion_Rug.bmp', 256, 256) do |x, y, w, h|
u = x.to_f / w
v = y.to_f / h
noise = Math.sin(x * 0.7) * Math.cos(y * 0.7) * 4.0
centers = [
[0.0, 0.28, [142, 68, 42], [168, 128, 72]],
[0.0, 0.74, [58, 62, 66], [142, 134, 120]],
[1.0, 0.28, [138, 72, 46], [172, 134, 78]],
[1.0, 0.74, [152, 118, 68], [92, 84, 76]]
]
color = [218 + noise, 210 + noise, 196 + noise]
centers.each do |(cu, cv, c_outer, c_inner)|
dx = (u - cu) * 1.15
dy = v - cv
r = Math.sqrt(dx * dx + dy * dy)
ang = Math.atan2(dy, dx).abs
spoke_gap = ((ang * 18.0 / Math::PI) % 1.0) < 0.18
if r < 0.09
color = [212 + noise, 204 + noise, 190 + noise]
elsif r >= 0.095 && r <= 0.145 && !spoke_gap
color = [c_inner[0] + noise, c_inner[1] + noise, c_inner[2] + noise]
elsif r >= 0.155 && r <= 0.215 && !spoke_gap
color = [c_outer[0] + noise, c_outer[1] + noise, c_outer[2] + noise]
elsif (r - 0.09).abs < 0.006 || (r - 0.15).abs < 0.006 || (r - 0.22).abs < 0.006
color = [72, 64, 56]
end
end
color
end
end
def setup_materials(model)
mats = model.materials
get_mat = lambda do |name, r, g, b, bmp = nil, sx = 600.0, sy = 600.0|
m = mats[name] || mats.add(name)
if bmp && File.file?(bmp)
m.color = Sketchup::Color.new(255, 255, 255)
m.texture = bmp
m.texture.size = [sx / 25.4, sy / 25.4]
else
m.texture = nil
m.color = Sketchup::Color.new(r, g, b)
end
m
end
{
:oak_frame => get_mat.call('MAT_CaneBed_Weathered_Oak', 196, 176, 152, generate_weathered_oak_bmp, 500.0, 500.0),
:cane_mesh => get_mat.call('MAT_CaneBed_Rattan_Webbing', 202, 182, 152, generate_cane_webbing_bmp, 180.0, 180.0),
:boho_rug => get_mat.call('MAT_CaneBed_Boho_Rug', 218, 210, 196, generate_boho_medallion_rug_bmp, 2200.0, 1800.0),
:rug_fringe => get_mat.call('MAT_CaneBed_Rug_Black_Fringe', 28, 28, 30),
:duvet_taupe => get_mat.call('MAT_CaneBed_Duvet_Greige', 162, 152, 142),
:sheet_cream => get_mat.call('MAT_CaneBed_Sheet_Cream', 238, 234, 226),
:mattress_gry => get_mat.call('MAT_CaneBed_Mattress_Taupe', 146, 138, 130),
:pillow_taupe => get_mat.call('MAT_CaneBed_Pillow_Taupe', 124, 112, 102),
:pillow_band => get_mat.call('MAT_CaneBed_Pillow_GreyBand', 164, 158, 150)
}
end
def face_mat(f, mat)
return unless f && mat
f.material = mat
f.back_material = mat
end
def add_local_box(ents, x1, y1, z1, x2, y2, z2, mat, name = nil)
xmin, xmax = [x1, x2].minmax
ymin, ymax = [y1, y2].minmax
zmin, zmax = [z1, z2].minmax
return nil if (xmax - xmin) < 1e-4 || (ymax - ymin) < 1e-4 || (zmax - zmin) < 1e-4
grp = ents.add_group
grp.name = name if name
pts = [
Geom::Point3d.new(m(xmin), m(ymin), m(zmin)),
Geom::Point3d.new(m(xmax), m(ymin), m(zmin)),
Geom::Point3d.new(m(xmax), m(ymax), m(zmin)),
Geom::Point3d.new(m(xmin), m(ymax), m(zmin))
]
face = grp.entities.add_face(pts)
if face
face.reverse! if face.normal.z < 0
face_mat(face, mat)
face.pushpull(m(zmax - zmin))
end
grp.entities.grep(Sketchup::Face).each { |f| face_mat(f, mat) }
grp.material = mat if mat
grp
end
def arch_top_pts_yz(x_plane, y_min, y_max, z_min, z_max, r_corner, segs = 10)
r = [[r_corner.to_f, (y_max - y_min) * 0.45, (z_max - z_min) * 0.85].min, 0.01].max
pts = [
Geom::Point3d.new(m(x_plane), m(y_min), m(z_min)),
Geom::Point3d.new(m(x_plane), m(y_max), m(z_min))
]
(0..segs).each do |i|
ang = (i.to_f / segs) * (Math::PI / 2.0)
py = (y_max - r) + r * Math.cos(ang)
pz = (z_max - r) + r * Math.sin(ang)
pts << Geom::Point3d.new(m(x_plane), m(py), m(pz))
end
(0..segs).each do |i|
ang = (Math::PI / 2.0) + (i.to_f / segs) * (Math::PI / 2.0)
py = (y_min + r) + r * Math.cos(ang)
pz = (z_max - r) + r * Math.sin(ang)
pts << Geom::Point3d.new(m(x_plane), m(py), m(pz))
end
pts
end
def add_curved_cane_board(ents, name, x_start, thick_x, half_w, z_bot_leg, z_panel_bot, z_top, r_top, mat_oak, mat_cane)
grp = ents.add_group
grp.name = name
ge = grp.entities
frame_w = 0.052
frame_grp = ge.add_group
fe = frame_grp.entities
outer_pts = arch_top_pts_yz(x_start, -half_w, half_w, z_panel_bot, z_top, r_top, 10)
inner_pts = arch_top_pts_yz(x_start, -half_w + frame_w, half_w - frame_w, z_panel_bot + frame_w, z_top - frame_w, [r_top - frame_w, 0.02].max, 10)
f_out = fe.add_face(outer_pts)
f_in = fe.add_face(inner_pts)
f_in.erase! if f_in
if f_out
f_out.reverse! if f_out.normal.x < 0
face_mat(f_out, mat_oak)
f_out.pushpull(m(thick_x))
end
fe.grep(Sketchup::Face).each { |f| face_mat(f, mat_oak) }
fe.grep(Sketchup::Edge).each { |e| (e.soft = true; e.smooth = true) if (e.start.position.x - e.end.position.x).abs > mm(1.0) }
frame_grp.material = mat_oak
if z_panel_bot > z_bot_leg + 0.005
add_local_box(ge, x_start, -half_w, z_bot_leg, x_start + thick_x, -half_w + frame_w, z_panel_bot, mat_oak, "#{name}_Leg_L")
add_local_box(ge, x_start, half_w - frame_w, z_bot_leg, x_start + thick_x, half_w, z_panel_bot, mat_oak, "#{name}_Leg_R")
end
cane_grp = ge.add_group
ce = cane_grp.entities
cane_x = x_start + (thick_x - 0.014) * 0.5
c_pts = arch_top_pts_yz(cane_x, -half_w + frame_w * 0.85, half_w - frame_w * 0.85, z_panel_bot + frame_w * 0.85, z_top - frame_w * 0.85, [r_top - frame_w * 0.85, 0.02].max, 10)
f_cane = ce.add_face(c_pts)
if f_cane
f_cane.reverse! if f_cane.normal.x < 0
face_mat(f_cane, mat_cane)
f_cane.pushpull(m(0.014))
end
ce.grep(Sketchup::Face).each { |f| face_mat(f, mat_cane) }
cane_grp.material = mat_cane
[-half_w / 3.0, half_w / 3.0].each_with_index do |ym, idx|
[-0.020, 0.020].each_with_index do |offset_y, sub_i|
add_local_box(
ge,
x_start + 0.004, ym + offset_y - 0.014, z_panel_bot + frame_w,
x_start + thick_x - 0.004, ym + offset_y + 0.014, z_top - frame_w,
mat_oak, "#{name}_Divider_#{idx + 1}_#{sub_i + 1}"
)
end
end
grp
end
def add_cane_bed_pillow(ents, name, cx, cy, cz, depth_x, width_y, thick_z,
tilt_y_deg, yaw_z_deg, mat_main, mat_stripe = nil,
mat_cream = nil, cream_on_right = true)
grp = ents.add_group
grp.name = name
ge = grp.entities
nx = 26
ny = 34
hx = depth_x * 0.5
hy = width_y * 0.5
corner_r = [0.055, depth_x * 0.14, width_y * 0.12].min
rounded_rectangle = lambda do |u, v|
x = hx * u
y = hy * v
ax = x.abs
ay = y.abs
if ax > hx - corner_r && ay > hy - corner_r
dx = ax - (hx - corner_r)
dy = ay - (hy - corner_r)
dist = Math.sqrt(dx * dx + dy * dy)
if dist > corner_r
scale = corner_r / dist
x = (x < 0.0 ? -1.0 : 1.0) * (hx - corner_r + dx * scale)
y = (y < 0.0 ? -1.0 : 1.0) * (hy - corner_r + dy * scale)
end
end
[x, y]
end
upper = []
lower = []
(0..nx).each do |i|
u = -1.0 + 2.0 * i / nx.to_f
ru = []
rl = []
(0..ny).each do |j|
v = -1.0 + 2.0 * j / ny.to_f
x, y = rounded_rectangle.call(u, v)
sx = [1.0 - u.abs**3.7, 0.0].max
sy = [1.0 - v.abs**3.5, 0.0].max
fill = (sx * sy)**0.48
folds = 0.0035 * fill * (Math.sin(6.4 * u + 1.1 * v) +
0.40 * Math.cos(7.5 * v - 2.2 * u))
soft_shoulder = 0.0030 * fill * Math.cos(2.6 * u - 1.8 * v)
top_z = thick_z * (-0.14 + 0.72 * fill) + folds + soft_shoulder
bottom_z = -thick_z * (0.28 + 0.20 * fill) + folds * 0.15
ru << Geom::Point3d.new(m(x), m(y), m(top_z))
rl << Geom::Point3d.new(m(x), m(y), m(bottom_z))
end
upper << ru
lower << rl
end
nx.times do |i|
ny.times do |j|
v_mid = (j + 0.5) / ny.to_f
cloth = if mat_cream && mat_stripe
if cream_on_right
v_mid > 0.64 ? mat_cream : (v_mid > 0.55 ? mat_stripe : mat_main)
else
v_mid < 0.36 ? mat_cream : (v_mid < 0.45 ? mat_stripe : mat_main)
end
else
mat_main
end
[
[upper[i][j], upper[i + 1][j], upper[i + 1][j + 1]],
[upper[i][j], upper[i + 1][j + 1], upper[i][j + 1]],
[lower[i][j], lower[i + 1][j + 1], lower[i + 1][j]],
[lower[i][j], lower[i][j + 1], lower[i + 1][j + 1]]
].each do |triangle|
face = ge.add_face(triangle)
face_mat(face, cloth) if face
end
end
end
nx.times do |i|
[[upper[i][0], upper[i + 1][0], lower[i + 1][0], lower[i][0]],
[upper[i][ny], upper[i + 1][ny], lower[i + 1][ny], lower[i][ny]]].each do |quad|
a = ge.add_face(quad[0], quad[1], quad[2])
b = ge.add_face(quad[0], quad[2], quad[3])
face_mat(a, mat_main) if a
face_mat(b, mat_main) if b
end
end
ny.times do |j|
[[upper[0][j], upper[0][j + 1], lower[0][j + 1], lower[0][j]],
[upper[nx][j], upper[nx][j + 1], lower[nx][j + 1], lower[nx][j]]].each do |quad|
a = ge.add_face(quad[0], quad[1], quad[2])
b = ge.add_face(quad[0], quad[2], quad[3])
face_mat(a, mat_main) if a
face_mat(b, mat_main) if b
end
end
ge.grep(Sketchup::Edge).each do |edge|
next unless edge.faces.size == 2
if edge.faces[0].normal.angle_between(edge.faces[1].normal) < 62.degrees
edge.soft = true
edge.smooth = true
end
end
transform = Geom::Transformation.translation(
Geom::Vector3d.new(m(cx), m(cy), m(cz))) *
Geom::Transformation.rotation(ORIGIN, Z_AXIS, yaw_z_deg.degrees) *
Geom::Transformation.rotation(ORIGIN, Y_AXIS, tilt_y_deg.degrees)
grp.transform!(transform)
grp
end
def add_cane_nightstand(ents, name, x1, x2, y_center, w_y, mats)
grp = ents.add_group
grp.name = name
ge = grp.entities
y1 = y_center - w_y * 0.5
y2 = y_center + w_y * 0.5
oak = mats[:oak_frame]
cane = mats[:cane_mesh]
add_local_box(ge, x1, y1, 0.0, x2, y1 + 0.024, 0.55, oak)
add_local_box(ge, x1, y2 - 0.024, 0.0, x2, y2, 0.55, oak)
add_local_box(ge, x1 - 0.008, y1 - 0.008, 0.55, x2 + 0.012, y2 + 0.008, 0.575, oak)
add_local_box(ge, x1 + 0.01, y1 + 0.024, 0.08, x2 - 0.01, y2 - 0.024, 0.105, oak)
add_local_box(ge, x1 + 0.01, y1 + 0.024, 0.30, x2 - 0.01, y2 - 0.024, 0.325, oak)
add_local_box(ge, x2 - 0.022, y1 + 0.024, 0.325, x2, y1 + 0.052, 0.55, oak)
add_local_box(ge, x2 - 0.022, y2 - 0.052, 0.325, x2, y2 - 0.024, 0.55, oak)
add_local_box(ge, x2 - 0.022, y1 + 0.052, 0.522, x2, y2 - 0.052, 0.55, oak)
add_local_box(ge, x2 - 0.022, y1 + 0.052, 0.325, x2, y2 - 0.052, 0.352, oak)
add_local_box(ge, x1 + 0.012, y1 + 0.030, 0.330, x1 + 0.026, y2 - 0.030, 0.545, cane)
add_local_box(ge, x1 + 0.026, y1 + 0.025, 0.330, x2 - 0.022, y1 + 0.036, 0.545, cane)
add_local_box(ge, x1 + 0.026, y2 - 0.036, 0.330, x2 - 0.022, y2 - 0.025, 0.545, cane)
grp
end
def build_cane_bed_set_in_room(room_ents, bed_wall, bx, by1, by2, z_fl, bed_len, mats)
ymid = (by1 + by2) * 0.5
half_w = (by2 - by1) * 0.5
set_grp = room_ents.add_group
set_grp.name = 'Cane_And_Weathered_Oak_Bed_Set'
se = set_grp.entities
oak = mats[:oak_frame]
cane = mats[:cane_mesh]
duvet = mats[:duvet_taupe]
cream = mats[:sheet_cream]
matt = mats[:mattress_gry]
ptau = mats[:pillow_taupe]
pband = mats[:pillow_band]
rug_x1 = 0.08; rug_x2 = bed_len + 0.28
rug_y1 = -half_w - 0.36; rug_y2 = half_w + 0.36
add_local_box(se, rug_x1, rug_y1, 0.002, rug_x2, rug_y2, 0.010, mats[:boho_rug], 'Boho_Medallion_Rug')
add_local_box(se, rug_x1, rug_y1 - 0.035, 0.002, rug_x2, rug_y1, 0.008, mats[:rug_fringe], 'Rug_Fringe_Left')
add_local_box(se, rug_x1, rug_y2, 0.002, rug_x2, rug_y2 + 0.035, 0.008, mats[:rug_fringe], 'Rug_Fringe_Right')
add_local_box(se, rug_x2, rug_y1 - 0.035, 0.002, rug_x2 + 0.035, rug_y2 + 0.035, 0.008, mats[:rug_fringe], 'Rug_Fringe_Foot')
add_curved_cane_board(se, 'Cane_Headboard', 0.0, 0.062, half_w, 0.0, 0.28, 1.24, 0.16, oak, cane)
fb_x = bed_len - 0.058
add_local_box(se, fb_x, -half_w, 0.0, bed_len, half_w, 0.24, oak, 'Footboard_Base_Plinth')
add_curved_cane_board(se, 'Cane_Footboard', fb_x, 0.058, half_w, 0.24, 0.24, 0.68, 0.13, oak, cane)
add_local_box(se, 0.062, -half_w, 0.035, fb_x, -half_w + 0.045, 0.24, oak, 'Bed_Side_Rail_Left')
add_local_box(se, 0.062, half_w - 0.045, 0.035, fb_x, half_w, 0.24, oak, 'Bed_Side_Rail_Right')
add_local_box(se, 0.062, -half_w + 0.045, 0.18, fb_x, half_w - 0.045, 0.23, oak, 'Bed_Platform_Deck')
m_x1 = 0.065; m_x2 = fb_x - 0.005; m_w = half_w - 0.035
add_local_box(se, m_x1, -m_w, 0.23, m_x2, m_w, 0.45, matt, 'Mattress_Fitted_Sheet')
d_x1 = 0.48; d_x2 = fb_x - 0.01
add_local_box(se, d_x1, -m_w - 0.015, 0.30, d_x2, m_w + 0.015, 0.515, duvet, 'Main_Taupe_Duvet')
add_local_box(se, 0.40, -m_w - 0.018, 0.516, 0.64, m_w + 0.018, 0.525, cream, 'Folded_Cream_Top_Sheet')
add_local_box(se, 0.52, m_w - 0.02, 0.16, 0.86, m_w + 0.035, 0.525, cream, 'Draped_Sheet_Side_Fold')
add_cane_bed_pillow(se, 'Back_Pillow_Left', 0.29, -0.35, 0.545, 0.42, 0.70, 0.23, 13, 1, ptau)
add_cane_bed_pillow(se, 'Back_Pillow_Right', 0.29, 0.35, 0.545, 0.42, 0.70, 0.23, 13, -1, ptau)
add_cane_bed_pillow(se, 'Front_Pillow_Left', 0.60, -0.32, 0.610, 0.37, 0.62, 0.19, 5, 2, ptau, pband, cream, true)
add_cane_bed_pillow(se, 'Front_Pillow_Right', 0.60, 0.32, 0.610, 0.37, 0.62, 0.19, 5, -2, ptau, pband, cream, false)
add_cane_nightstand(se, 'Cane_Nightstand_Left', 0.02, 0.44, -half_w - 0.24, 0.40, mats)
add_cane_nightstand(se, 'Cane_Nightstand_Right', 0.02, 0.44, half_w + 0.24, 0.40, mats)
rot_deg = (bed_wall == :east) ? 180.0 : 0.0
tr = Geom::Transformation.translation(Geom::Vector3d.new(m(bx), m(ymid), m(z_fl))) *
Geom::Transformation.rotation(ORIGIN, Z_AXIS, rot_deg.degrees)
set_grp.transform!(tr)
set_grp
end
def find_group_recursive(entities, target_name)
entities.to_a.each do |ent|
next if ent.deleted? || !ent.is_a?(Sketchup::Group)
return ent if ent.name == target_name
found = find_group_recursive(ent.entities, target_name)
return found if found
end
nil
end
def erase_named_groups_recursive(entities, target_names)
entities.to_a.each do |ent|
next if ent.deleted? || !ent.is_a?(Sketchup::Group)
if target_names.include?(ent.name)
ent.erase!
else
erase_named_groups_recursive(ent.entities, target_names)
end
end
end
def clean_bed_only_inside_bedroom_group(room_grp, bed_wall, bx, by1, by2, z_fl)
original_bed_names = [
'Headboard', 'Bed_Frame', 'Mattress', 'Bed_Duvet', 'Bed_Runner',
'Sleep_Pillow_L', 'Sleep_Pillow_R', 'Accent_Pillow_L',
'Accent_Pillow_R', 'Table_Lamp', 'Cane_And_Weathered_Oak_Bed_Set'
]
x_min, x_max = bed_wall == :east ? [bx - 0.52, bx + 0.02] : [bx - 0.02, bx + 0.52]
side_y = [[by1 - 0.45, by1 - 0.01], [by2 + 0.01, by2 + 0.45]]
room_grp.entities.to_a.each do |ent|
next if ent.deleted?
next unless ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
name = ent.name.to_s
next if name =~ /\A(?:Wardrobe|Split_AC)/i
remove = original_bed_names.include?(name)
if !remove && name.empty?
center = ent.bounds.center
remove = center.x >= x_min.m && center.x <= x_max.m &&
side_y.any? { |lo, hi| center.y >= lo.m && center.y <= hi.m } &&
center.z >= z_fl.m && center.z <= (z_fl + 0.65).m
end
ent.erase! if remove
end
end
def run!(model, house)
model.start_operation('Replace Bedroom Beds with Cane & Oak Bed Set', true)
begin
mats = setup_materials(model)
furn = model.entities.grep(Sketchup::Group).find { |g| g.name == 'FURNISHING' && !g.deleted? }
if furn
erase_named_groups_recursive(furn.entities, [
'04_GF_Bedroom1_Detail', '07_2F_Master_Bedroom_Detail', '08_2F_Bedroom2_Detail',
'Bedroom_Headboard_and_Bedding_Detail', 'Upper_Bedroom_Headboard_Detail',
'RR_GF_Bedroom1_Pillow_Set', 'RR_Upper_Bedroom2_Pillow_Set', 'RR_Master_Bedroom_Pillow_Set'
])
end
bedrooms = [
['Room_GF_Bedroom_1', :east, 9.85, 2.05, 3.55, 0.02, 1.80],
['Room_2F_Bedroom_2', :east, 9.85, 2.05, 3.55, 3.02, 1.80],
['Room_2F_Bedroom_3', :west, 0.15, 5.15, 6.65, 3.02, 1.62]
]
replaced_count = 0
bedrooms.each do |(rname, wall_dir, bx, by1, by2, z_fl, b_len)|
r_grp = find_group_recursive(house.entities, rname)
next unless r_grp
clean_bed_only_inside_bedroom_group(r_grp, wall_dir, bx, by1, by2, z_fl)
build_cane_bed_set_in_room(r_grp.entities, wall_dir, bx, by1, by2, z_fl, b_len, mats)
replaced_count += 1
end
model.active_view.refresh if model.active_view
model.commit_operation
puts "BEDROOM PATCH COMPLETE: Replaced beds in #{replaced_count} bedrooms with the Cane & Weathered Oak Bed Set. No other house features were changed."
rescue StandardError => err
model.abort_operation
puts "BEDROOM PATCH FAILED: #{err.class}: #{err.message}"
puts err.backtrace.join("\n") if err.backtrace
raise
end
end
end
CaneBedroomSurgicalPatch.run!(model, house)

begin
  victoria_model = Sketchup.active_model
  victoria_house = victoria_model.entities.grep(Sketchup::Group).find { |g| g.name == 'House_10x10_Model' && !g.deleted? }
  if victoria_house
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'review_status', 'PENDING LOCAL ZONING AND BUILDING OFFICIAL CONFIRMATION')
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'lot_dimensions', '10 m x 10 m as modeled; not a verified geodetic boundary survey')
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'side_firewall_count', 2)
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'classification', 'UNVERIFIED; do not assume R-3 or BP 220 applies')
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'rule_source', 'PD 1096 2004 Revised IRR, Rule VIII, Section 704(4)(c); subject to official local zoning, Fire Code, setbacks, and building permit review')
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'conditions', 'R-1: no building firewalls; R-2: one side up to 80%; R-3: two sides conditionally up to 85% each, total firewall length up to 65% of lot perimeter for maximum two-storey component; R-4: townhouse-specific conditions. Determine which is approved.')
    victoria_house.set_attribute('Victoria_Oriental_Mindoro_Firewall_Review', 'action_required', 'Obtain lot survey, zoning certification/locational clearance, confirmed occupancy classification, firewall/fire-rated construction details, and Office of the Building Official review before altering structural geometry.')
    puts 'VICTORIA FIREWALL REVIEW: UNVERIFIED. Two side boundaries are labeled as firewalls in this conceptual model. This is not a permit certification. Confirm zoning, lot survey, classification, firewall length, fire rating, setbacks and BFP requirements before construction.'
  end
rescue StandardError => victoria_review_error
  puts "Victoria firewall audit metadata could not be recorded: #{victoria_review_error.message}"
end
