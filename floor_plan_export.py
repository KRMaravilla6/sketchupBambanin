#!/usr/bin/env python3
"""Generate a full-size, LibreCAD-compatible DXF floor-plan sheet."""

from pathlib import Path
import ast
import re


OUT = Path(__file__).with_name("Bambanin_House_Floor_Plans.dxf")
BACKUP = OUT.with_name(f"#{OUT.name}")
MODEL_SOURCE = Path(__file__).with_name("sketchupBambanin.rb")

LAYERS = {
    "SHEET": 8,
    "SITE": 9,
    "WALL-EXT": 7,
    "WALL-INT": 7,
    "DOOR": 3,
    "WINDOW": 4,
    "STAIR": 6,
    "FIXTURE": 5,
    "FURNITURE": 8,
    "ROOF": 8,
    "SECTION": 1,
    "DIM": 2,
    "TEXT": 7,
}


class DXF:
    def __init__(self):
        self.entities = []

    @staticmethod
    def pair(code, value):
        return f"{code}\n{value}\n"

    def entity(self, kind, layer, fields):
        data = self.pair(0, kind) + self.pair(8, layer)
        for code, value in fields:
            data += self.pair(code, value)
        self.entities.append(data)

    def line(self, x1, y1, x2, y2, layer="WALL-INT", linetype=None):
        fields = [(10, f"{x1:.3f}"), (20, f"{y1:.3f}"), (30, "0"),
                  (11, f"{x2:.3f}"), (21, f"{y2:.3f}"), (31, "0")]
        if linetype:
            fields.append((6, linetype))
        self.entity("LINE", layer, fields)

    def rect(self, x1, y1, x2, y2, layer="WALL-INT"):
        self.line(x1, y1, x2, y1, layer)
        self.line(x2, y1, x2, y2, layer)
        self.line(x2, y2, x1, y2, layer)
        self.line(x1, y2, x1, y1, layer)

    def circle(self, x, y, radius, layer="FIXTURE"):
        self.entity("CIRCLE", layer, [(10, f"{x:.3f}"), (20, f"{y:.3f}"),
                                      (30, "0"), (40, f"{radius:.3f}")])

    def arc(self, x, y, radius, start, end, layer="DOOR"):
        self.entity("ARC", layer, [(10, f"{x:.3f}"), (20, f"{y:.3f}"),
                                   (30, "0"), (40, f"{radius:.3f}"),
                                   (50, f"{start:.3f}"), (51, f"{end:.3f}")])

    def text(self, value, x, y, height=150, layer="TEXT", align="left",
             rotation=0):
        fields = [(10, f"{x:.3f}"), (20, f"{y:.3f}"), (30, "0"),
                  (40, f"{height:.3f}"), (1, value), (50, f"{rotation:.3f}")]
        if align == "center":
            fields += [(72, "1"), (73, "2"), (11, f"{x:.3f}"),
                       (21, f"{y:.3f}"), (31, "0")]
        self.entity("TEXT", layer, fields)

    def wall_h(self, x1, x2, y, thickness, openings=(), layer="WALL-INT"):
        openings = sorted(openings, key=lambda item: item[0])
        cursor = x1
        for start, end, kind, label, swing in openings:
            start = max(start, x1)
            end = min(end, x2)
            if end <= start:
                continue
            if start > cursor:
                self.rect(cursor, y - thickness / 2, start, y + thickness / 2,
                          layer)
            self.line(start, y - thickness / 2, start, y + thickness / 2, layer)
            self.line(end, y - thickness / 2, end, y + thickness / 2, layer)
            if kind == "window":
                self.line(start, y - 25, end, y - 25, "WINDOW")
                self.line(start, y + 25, end, y + 25, "WINDOW")
                self.text(label, (start + end) / 2, y + thickness / 2 + 55,
                          95, "WINDOW", "center")
            elif kind == "door":
                width = end - start
                sign = 1 if swing >= 0 else -1
                self.line(start, y, start, y + sign * width, "DOOR")
                if sign > 0:
                    self.arc(start, y, width, 0, 90)
                else:
                    self.arc(start, y, width, 270, 360)
                self.text(label, (start + end) / 2, y - thickness / 2 - 150,
                          100, "DOOR", "center")
            cursor = max(cursor, end)
        if cursor < x2:
            self.rect(cursor, y - thickness / 2, x2, y + thickness / 2, layer)

    def wall_v(self, x, y1, y2, thickness, openings=(), layer="WALL-INT"):
        openings = sorted(openings, key=lambda item: item[0])
        cursor = y1
        for start, end, kind, label, swing in openings:
            start = max(start, y1)
            end = min(end, y2)
            if end <= start:
                continue
            if start > cursor:
                self.rect(x - thickness / 2, cursor, x + thickness / 2, start,
                          layer)
            self.line(x - thickness / 2, start, x + thickness / 2, start, layer)
            self.line(x - thickness / 2, end, x + thickness / 2, end, layer)
            if kind == "window":
                self.line(x - 25, start, x - 25, end, "WINDOW")
                self.line(x + 25, start, x + 25, end, "WINDOW")
                self.text(label, x + thickness / 2 + 55, (start + end) / 2,
                          95, "WINDOW", "center", 90)
            elif kind == "door":
                width = end - start
                sign = 1 if swing >= 0 else -1
                self.line(x, start, x + sign * width, start, "DOOR")
                if sign > 0:
                    self.arc(x, start, width, 0, 90)
                else:
                    self.arc(x, start, width, 90, 180)
                self.text(label, x + thickness / 2 + 150,
                          (start + end) / 2, 100, "DOOR", "center", 90)
            cursor = max(cursor, end)
        if cursor < y2:
            self.rect(x - thickness / 2, cursor, x + thickness / 2, y2,
                      layer)

    def hdim(self, x1, x2, y, ref_y, label):
        self.line(x1, ref_y, x1, y - 120, "DIM")
        self.line(x2, ref_y, x2, y - 120, "DIM")
        self.line(x1, y, x2, y, "DIM")
        self.line(x1 - 90, y - 90, x1 + 90, y + 90, "DIM")
        self.line(x2 - 90, y - 90, x2 + 90, y + 90, "DIM")
        self.text(label, (x1 + x2) / 2, y + 60, 150, "DIM", "center")

    def vdim(self, y1, y2, x, ref_x, label):
        self.line(ref_x, y1, x + 120, y1, "DIM")
        self.line(ref_x, y2, x + 120, y2, "DIM")
        self.line(x, y1, x, y2, "DIM")
        self.line(x - 90, y1 - 90, x + 90, y1 + 90, "DIM")
        self.line(x - 90, y2 - 90, x + 90, y2 + 90, "DIM")
        self.text(label, x - 100, (y1 + y2) / 2, 150, "DIM", "center", 90)

    def label(self, title, detail, x, y):
        self.text(title, x, y, 250, "TEXT")
        self.text(detail, x, y - 310, 145, "TEXT")
        self.line(x, y - 400, x + 11600, y - 400, "SHEET")

    def titleblock(self):
        self.rect(0, -1500, 40000, 28000, "SHEET")
        self.line(0, -500, 40000, -500, "SHEET")
        self.line(25500, -1500, 25500, -500, "SHEET")
        self.line(33000, -1500, 33000, -500, "SHEET")
        self.text("BAMBANIN | RESIDENTIAL HOUSE", 600, 27500, 300, "TEXT")
        self.text("ARCHITECTURAL PLANS AND SECTION", 600, 27100, 180, "TEXT")
        self.text("CONCEPT DRAWING - VERIFY ON SITE BEFORE CONSTRUCTION",
                  600, -1250, 130, "TEXT")
        self.text("DRAWING", 25800, -780, 105, "TEXT")
        self.text("GROUND + SECOND FLOOR / SECTION A-A", 25800, -1180, 130, "TEXT")
        self.text("SHEET", 33300, -780, 105, "TEXT")
        self.text("A-101", 33300, -1350, 260, "TEXT")
        self.text("UNITS: mm   |   PLOT: A1 LANDSCAPE AT 1:50",
                  25800, -1400, 115, "TEXT")
        self.line(0, -1500, 40000, -1500, "SHEET")
        self.line(0, 28000, 40000, 28000, "SHEET")
        self.line(0, -1500, 0, 28000, "SHEET")
        self.line(40000, -1500, 40000, 28000, "SHEET")


def m(value):
    return value * 1000.0


def room(dxf, x, y, name, size=None):
    dxf.text(name, x, y, 165, "TEXT", "center")
    if size:
        dxf.text(size, x, y - 205, 115, "TEXT", "center")


def north_arrow(dxf, x, y):
    dxf.line(x, y, x, y + 550, "DIM")
    dxf.line(x, y + 550, x - 100, y + 350, "DIM")
    dxf.line(x, y + 550, x + 100, y + 350, "DIM")
    dxf.text("N", x, y + 680, 180, "TEXT", "center")


def door_h(start, end, label, swing=1):
    return (m(start), m(end), "door", label, swing)


def window_h(start, end, label):
    return (m(start), m(end), "window", label, 0)


def door_v(start, end, label, swing=1):
    return (m(start), m(end), "door", label, swing)


def shifted(openings, offset):
    return [(start + offset, end + offset, kind, label, swing)
            for start, end, kind, label, swing in openings]


def window_v(start, end, label):
    return (m(start), m(end), "window", label, 0)


def furniture(dxf, x1, y1, x2, y2, label=None, layer="FURNITURE"):
    dxf.rect(x1, y1, x2, y2, layer)
    if label:
        dxf.text(label, (x1 + x2) / 2, (y1 + y2) / 2, 95,
                 layer, "center")


def kitchen_geometry():
    source = MODEL_SOURCE.read_text(encoding="utf-8")
    group_marker = "kitchen_grp = de.add_group; kitchen_grp.name = 'Kitchen_Optimized_Layout'"
    start = source.find(group_marker)
    if start < 0:
        raise ValueError(f"Kitchen geometry not found in {MODEL_SOURCE}")
    end = source.find("ref_grp = ke.add_group", start)
    if end < 0:
        raise ValueError(f"Refrigerator group not found in {MODEL_SOURCE}")

    block = source[start:end]
    names = (
        "k_back", "k_depth", "fx2", "ex2", "sx1", "sx2", "hx1", "hx2",
        "fridge_back_x", "fridge_front_x", "fridge_y1", "fridge_y2",
        "fridge_swing", "return_x1",
    )
    values = {}
    for name, value in re.findall(
        r"\b(" + "|".join(names) + r")\s*=\s*([-+]?\d+(?:\.\d+)?)",
        block,
    ):
        values[name] = float(value)
    missing = set(names) - values.keys()
    if missing:
        raise ValueError(
            f"Missing kitchen geometry values in {MODEL_SOURCE}: "
            f"{', '.join(sorted(missing))}"
        )

    values["k_front"] = values["k_back"] - values["k_depth"]
    values["return_x2"] = values["fx2"] - 0.015
    values["return_y1"] = values["fridge_y2"] + 0.075
    return values


def ruby_number(expression, values):
    def evaluate(node):
        if isinstance(node, ast.Constant) and type(node.value) in (int, float):
            return float(node.value)
        if isinstance(node, ast.Name) and node.id in values:
            return values[node.id]
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
            value = evaluate(node.operand)
            return value if isinstance(node.op, ast.UAdd) else -value
        if isinstance(node, ast.BinOp):
            left = evaluate(node.left)
            right = evaluate(node.right)
            if isinstance(node.op, ast.Add):
                return left + right
            if isinstance(node.op, ast.Sub):
                return left - right
            if isinstance(node.op, ast.Mult):
                return left * right
            if isinstance(node.op, ast.Div):
                return left / right
        raise ValueError(
            f"Unsupported numeric expression in Ruby source: {expression}"
        )

    return evaluate(ast.parse(expression, mode="eval").body)


def tv_wall_geometry():
    source = MODEL_SOURCE.read_text(encoding="utf-8")
    config_match = re.search(
        r"TV_WALL_CONFIG\s*=\s*\{(.*?)\}\.freeze", source, re.DOTALL
    )
    if not config_match:
        raise ValueError(f"TV wall configuration not found in {MODEL_SOURCE}")

    required = ("WALL_W", "TV_W", "TV_H", "TV_D", "TV_DIAGONAL_IN",
                "STONE_BORDER", "MARGIN", "SHELF_DEPTH")
    config = {
        name: float(value)
        for name, value in re.findall(
            r"\b(" + "|".join(required) + r")\s*:\s*([-+]?\d+(?:\.\d+)?)",
            config_match.group(1),
        )
    }
    if set(required) - config.keys():
        raise ValueError(f"Incomplete TV wall configuration in {MODEL_SOURCE}")
    if config["TV_W"] <= 0.0:
        raise ValueError("TV_W must be positive in the Ruby model.")
    if config["TV_D"] <= 0.0 or config["TV_DIAGONAL_IN"] <= 0.0:
        raise ValueError("TV depth and diagonal must be positive in the Ruby model.")
    model_match = re.search(
        r"^\s*TV_MODEL\s*=\s*['\"]([^'\"]+)['\"]\s*$",
        source, re.MULTILINE,
    )
    if not model_match:
        raise ValueError(f"TV model name not found in {MODEL_SOURCE}")

    values = {}
    assignments = (
        "window_w3_y1", "window_w3_y2", "window_furniture_clearance",
        "entry_swing_end_y", "brown_tv_panel_y1", "brown_tv_panel_y2",
    )
    for name in assignments:
        match = re.search(
            r"^\s*" + re.escape(name) + r"\s*=\s*(.*?)\s*$",
            source, re.MULTILINE,
        )
        if not match:
            raise ValueError(f"Missing {name} assignment in {MODEL_SOURCE}")
        values[name] = ruby_number(match.group(1), values)

    wall_width_mm = (values["brown_tv_panel_y2"]
                     - values["brown_tv_panel_y1"]) * 1000.0
    if abs(config["WALL_W"] - wall_width_mm) > 1.0:
        raise ValueError("TV wall width in Ruby source does not match the panel.")
    if config["WALL_W"] - 2.0 * (config["MARGIN"] + config["STONE_BORDER"]) <= 0:
        raise ValueError("TV and stone frame do not fit the clear wall zone.")
    scale = min(
        1.0,
        max(wall_width_mm - 2.0 * (config["MARGIN"] + config["STONE_BORDER"]),
            0.0) / config["TV_W"],
    )
    if scale < 1.0:
        raise ValueError("Selected TV model does not fit the clear wall zone.")
    margin = config["MARGIN"] * scale / 1000.0
    border = config["STONE_BORDER"] * scale / 1000.0
    body_width = config["TV_W"] * scale / 1000.0
    frame_width = body_width + 2.0 * border
    gap = 0.005 * scale
    side_width = (
        wall_width_mm / 1000.0 - 2.0 * margin - frame_width - 2.0 * gap
    ) / 2.0
    frame_y1 = values["brown_tv_panel_y1"] + margin + side_width + gap
    frame_y2 = frame_y1 + frame_width
    center_y = (values["brown_tv_panel_y1"] + values["brown_tv_panel_y2"]) / 2.0
    screen_diagonal = config["TV_DIAGONAL_IN"] * 25.4 * scale
    aspect_diagonal = (16.0**2 + 9.0**2) ** 0.5
    return {
        "model": model_match.group(1),
        "diagonal_in": config["TV_DIAGONAL_IN"] * scale,
        "window_y1": values["window_w3_y1"],
        "window_y2": values["window_w3_y2"],
        "shelf_x1": 3.285,
        "shelf_x2": 3.285 + config["SHELF_DEPTH"] / 1000.0,
        "shelf_y1": frame_y1,
        "shelf_y2": frame_y2,
        "body_x1": 3.285,
        "body_x2": 3.285 + config["TV_D"] * scale / 1000.0,
        "body_y1": center_y - body_width / 2.0,
        "body_y2": center_y + body_width / 2.0,
        "body_width_mm": body_width * 1000.0,
        "body_height_mm": config["TV_H"] * scale,
        "body_depth_mm": config["TV_D"] * scale,
        "screen_width_mm": screen_diagonal * 16.0 / aspect_diagonal,
        "screen_height_mm": screen_diagonal * 9.0 / aspect_diagonal,
        "shelf_width_mm": frame_width * 1000.0,
        "shelf_depth_mm": config["SHELF_DEPTH"],
        "door_clearance_mm": (frame_y1 - values["entry_swing_end_y"]) * 1000.0,
        "window_clearance_mm": (values["window_w3_y1"] - frame_y2) * 1000.0,
    }


def bed(dxf, x1, y1, x2, y2):
    dxf.rect(m(x1), m(y1), m(x2), m(y2), "FURNITURE")
    dxf.text("BED", m((x1 + x2) / 2), m((y1 + y2) / 2), 95,
             "FURNITURE", "center")
    width = x2 - x1
    dxf.line(m(x1), m(y1 + width * 0.27), m(x2), m(y1 + width * 0.27))
    dxf.line(m(x1 + width * 0.50), m(y1), m(x1 + width * 0.50),
             m(y1 + width * 0.27))
    dxf.line(m(x1), m(y1), m(x2), m(y1))


def draw_ground(dxf, ox, oy):
    tv = tv_wall_geometry()
    # Site envelope and principal ground-floor walls.
    dxf.rect(ox, oy, ox + 10000, oy + 10000, "SITE")
    dxf.rect(ox + 150, oy + 150, ox + 9850, oy + 9850, "SITE")
    dxf.wall_h(m(3.075) + ox, m(7.05) + ox, m(2.0) + oy, 150,
               shifted([door_h(3.35, 4.30, "D3", 1),
                        window_h(4.90, 6.30, "W5")], ox), "WALL-EXT")
    dxf.wall_h(m(6.95) + ox, m(9.85) + ox, m(1.5) + oy, 150,
               shifted([window_h(7.70, 9.10, "W4")], ox), "WALL-EXT")
    dxf.wall_h(m(3.075) + ox, m(9.85) + ox, m(8.0) + oy, 150,
               shifted([window_h(3.90, 5.40, "W1"),
                        door_h(6.20, 6.95, "D5", -1),
                        window_h(8.075, 8.625, "W2")], ox), "WALL-EXT")
    dxf.wall_v(m(3.15) + ox, m(2.075) + oy, m(8.075) + oy, 150,
               shifted([window_v(tv["window_y1"], tv["window_y2"], "W3")],
                       oy), "WALL-EXT")
    dxf.wall_v(m(9.85) + ox, m(1.5) + oy, m(8.0) + oy, 150, [],
               "WALL-EXT")
    # Interior bedroom, stair, and bathroom partitions.
    dxf.wall_v(m(7.0) + ox, m(2.075) + oy, m(4.95) + oy, 100, [])
    dxf.wall_h(m(6.95) + ox, m(9.85) + ox, m(4.9) + oy, 100,
               shifted([door_h(7.05, 7.85, "D6", 1)], ox))
    dxf.wall_h(m(6.95) + ox, m(9.85) + ox, m(6.5) + oy, 100, [])
    dxf.wall_v(m(7.0) + ox, m(6.45) + oy, m(7.925) + oy, 100,
               shifted([door_v(6.70, 7.40, "D4", -1)], oy))
    # Garage gate, front porch edge, and service-area equipment.
    dxf.line(ox + 150, oy + 150, ox + m(3.075), oy + 150, "DOOR",
             "DASHED")
    dxf.text("D1 - GARAGE GATE", ox + m(1.60), oy + 330, 105,
             "DOOR", "center")
    kitchen = kitchen_geometry()
    furniture(dxf, ox + m(kitchen["return_x1"]),
              oy + m(kitchen["return_y1"]), ox + m(kitchen["return_x2"]),
              oy + m(kitchen["k_back"]), "SINK RETURN")
    furniture(dxf, ox + m(kitchen["fx2"]), oy + m(kitchen["k_front"]),
              ox + m(kitchen["ex2"]), oy + m(kitchen["k_back"]), "KITCHEN")
    furniture(dxf, ox + m(kitchen["sx1"] + 0.04),
              oy + m(kitchen["k_front"] + 0.055),
              ox + m(kitchen["sx2"] - 0.04),
              oy + m(kitchen["k_back"] - 0.13), "SINK")
    furniture(dxf, ox + m(kitchen["hx1"] + 0.02),
              oy + m(kitchen["k_front"] + 0.04),
              ox + m(kitchen["hx2"] - 0.02),
              oy + m(kitchen["k_front"] + 0.53), "HOB")
    furniture(dxf, ox + m(kitchen["fridge_back_x"]),
              oy + m(kitchen["fridge_y1"]),
              ox + m(kitchen["fridge_front_x"]),
              oy + m(kitchen["fridge_y2"]), "REF")
    hinge_x = ox + m(kitchen["fridge_front_x"])
    hinge_y = oy + m(kitchen["fridge_y2"])
    swing = m(kitchen["fridge_swing"])
    dxf.arc(hinge_x, hinge_y, swing, 270, 360, "DOOR")
    dxf.line(hinge_x, hinge_y, hinge_x, hinge_y - swing, "DOOR")
    dxf.line(hinge_x, hinge_y, hinge_x + swing, hinge_y, "DOOR")
    furniture(dxf, ox + m(4.56), oy + m(4.74), ox + m(5.70),
              oy + m(5.86), "DINING")
    for cx, cy in [(4.35, 5.30), (5.95, 5.30), (5.13, 4.38),
                   (5.13, 6.10)]:
        dxf.rect(ox + m(cx - 0.22), oy + m(cy - 0.22),
                 ox + m(cx + 0.22), oy + m(cy + 0.22), "FURNITURE")
    furniture(dxf, ox + m(4.60), oy + m(2.10), ox + m(6.80),
              oy + m(4.05), "LIVING")
    furniture(dxf, ox + m(4.91), oy + m(3.17), ox + m(5.76),
              oy + m(3.83), "COFFEE TABLE")
    dxf.rect(ox + m(tv["shelf_x1"]), oy + m(tv["shelf_y1"]),
             ox + m(tv["shelf_x2"]), oy + m(tv["shelf_y2"]), "FURNITURE")
    dxf.rect(ox + m(tv["body_x1"]), oy + m(tv["body_y1"]),
             ox + m(tv["body_x2"]), oy + m(tv["body_y2"]), "FURNITURE")
    dxf.text(
        f'{tv["diagonal_in"]:.0f}IN {tv["model"]}',
        ox + m((tv["body_x1"] + tv["body_x2"]) / 2.0),
        oy + m((tv["body_y1"] + tv["body_y2"]) / 2.0),
        40, "FURNITURE", "center", 90,
    )
    dxf.text(
        f'DIVIDER SHELF {tv["shelf_width_mm"]:.0f}x{tv["shelf_depth_mm"]:.0f}',
        ox + m((tv["shelf_x1"] + tv["shelf_x2"]) / 2.0),
        oy + m((tv["shelf_y1"] + tv["shelf_y2"]) / 2.0),
        65, "FURNITURE", "center", 90,
    )
    bed(dxf, 7.25 + ox / 1000, 2.00 + oy / 1000,
        9.55 + ox / 1000, 3.75 + oy / 1000)
    furniture(dxf, ox + m(7.05), oy + m(6.55), ox + m(7.95),
              oy + m(7.70), "VANITY")
    dxf.circle(ox + m(8.55), oy + m(7.18), 180)
    dxf.text("WC", ox + m(8.55), oy + m(7.18), 100, "FIXTURE", "center")
    furniture(dxf, ox + m(3.30), oy + m(8.10), ox + m(6.00),
              oy + m(8.68), "SERVICE")
    furniture(dxf, ox + m(7.05), oy + m(8.10), ox + m(7.68),
              oy + m(8.68), "WM")
    # Stair: 275 mm going, 187.5 mm riser, 8 lower treads and 3 turning steps.
    for i in range(8):
        x1 = 6.775 + i * 0.275
        dxf.line(ox + m(x1), oy + m(5.73),
                 ox + m(x1), oy + m(6.45), "STAIR")
    dxf.line(ox + m(6.775), oy + m(5.73),
             ox + m(8.975), oy + m(5.73), "STAIR")
    dxf.line(ox + m(6.775), oy + m(6.45),
             ox + m(8.975), oy + m(6.45), "STAIR")
    dxf.line(ox + m(8.975), oy + m(6.01),
             ox + m(9.795), oy + m(6.01), "STAIR")
    dxf.line(ox + m(8.975), oy + m(5.57),
             ox + m(8.975), oy + m(6.45), "STAIR")
    dxf.line(ox + m(9.795), oy + m(5.57),
             ox + m(9.795), oy + m(6.45), "STAIR")
    dxf.text("UP", ox + m(7.75), oy + m(6.10), 125, "STAIR", "center")
    dxf.label("01  GROUND FLOOR PLAN", "Scale 1:50 | FFL +/-0.000",
              ox, oy + 11500)
    dxf.hdim(ox, ox + 10000, oy - 900, oy, "10 000")
    dxf.vdim(oy, oy + 10000, ox - 900, ox, "10 000")
    dxf.text("LIVING / DINING / KITCHEN", ox + m(5.05), oy + m(4.55),
             145, "TEXT", "center")
    room(dxf, ox + m(8.40), oy + m(4.15), "BEDROOM 1", "2 800 x 3 275")
    room(dxf, ox + m(8.40), oy + m(7.20), "BATH 1", "2 800 x 1 375")
    room(dxf, ox + m(1.60), oy + m(3.00), "GARAGE", "2 925 x 5 850")
    room(dxf, ox + m(5.00), oy + m(1.10), "ENTRY / PORCH")
    room(dxf, ox + m(4.85), oy + m(8.95), "REAR SERVICE AREA")
    north_arrow(dxf, ox + 10600, oy + 8500)


def draw_second(dxf, ox, oy):
    dxf.rect(ox, oy, ox + 10000, oy + 10000, "SITE")
    # Second-floor exterior walls and terrace opening.
    dxf.wall_h(m(0.15) + ox, m(3.225) + ox, m(4.0) + oy, 150,
               shifted([door_h(0.40, 2.85, "D-TERRACE", 1)], ox),
               "WALL-EXT")
    dxf.wall_h(m(3.075) + ox, m(7.05) + ox, m(2.0) + oy, 150,
               shifted([window_h(3.35, 6.75, "W-2F-C")], ox), "WALL-EXT")
    dxf.wall_h(m(6.95) + ox, m(9.85) + ox, m(1.5) + oy, 150,
               shifted([window_h(7.72, 9.12, "W-2F-B2")], ox), "WALL-EXT")
    dxf.wall_h(m(0.15) + ox, m(3.075) + ox, m(8.0) + oy, 150,
               shifted([window_h(0.95, 2.35, "W-B3-R")], ox), "WALL-EXT")
    dxf.wall_h(m(3.225) + ox, m(9.85) + ox, m(8.0) + oy, 150,
               shifted([window_h(4.30, 5.90, "W-FAM"),
                        window_h(8.05, 8.60, "W-TB2")], ox), "WALL-EXT")
    dxf.wall_v(m(3.15) + ox, m(2.075) + oy, m(8.075) + oy, 150,
               shifted([door_v(7.05, 7.85, "D-B3", 1)], oy), "WALL-EXT")
    dxf.wall_v(m(9.85) + ox, m(1.5) + oy, m(8.0) + oy, 150, [],
               "WALL-EXT")
    # Bedroom, stair-landing, and bathroom walls.
    dxf.wall_v(m(7.0) + ox, m(2.075) + oy, m(4.95) + oy, 100, [])
    dxf.wall_h(m(7.05) + ox, m(9.85) + ox, m(4.9) + oy, 100,
               shifted([door_h(7.05, 7.80, "D-B2", 1)], ox))
    dxf.wall_h(m(7.05) + ox, m(9.85) + ox, m(6.5) + oy, 100, [])
    dxf.wall_v(m(7.0) + ox, m(6.45) + oy, m(7.925) + oy, 100,
               shifted([door_v(6.70, 7.40, "D-TB2", -1)], oy))
    # Stair opening and treads.
    for i in range(7):
        x = 8.975 - (i + 1) * 0.280
        dxf.line(ox + m(x), oy + m(4.975),
                 ox + m(x), oy + m(5.695), "STAIR")
    dxf.line(ox + m(7.015), oy + m(4.975),
             ox + m(8.975), oy + m(4.975), "STAIR")
    dxf.line(ox + m(7.015), oy + m(5.695),
             ox + m(8.975), oy + m(5.695), "STAIR")
    dxf.text("DN", ox + m(8.10), oy + m(5.30), 125, "STAIR", "center")
    # Beds, storage, family seating, bath fittings, and terrace furniture.
    bed(dxf, 0.35 + ox / 1000, 5.00 + oy / 1000,
        2.85 + ox / 1000, 6.85 + oy / 1000)
    furniture(dxf, ox + m(2.60), oy + m(4.65), ox + m(3.05),
              oy + m(6.75), "WARDROBE")
    bed(dxf, 7.20 + ox / 1000, 2.00 + oy / 1000,
        9.55 + ox / 1000, 3.75 + oy / 1000)
    furniture(dxf, ox + m(3.65), oy + m(6.90), ox + m(5.90),
              oy + m(7.70), "FAMILY")
    furniture(dxf, ox + m(7.05), oy + m(6.55), ox + m(7.95),
              oy + m(7.70), "VANITY")
    dxf.circle(ox + m(8.55), oy + m(7.18), 180)
    dxf.text("WC", ox + m(8.55), oy + m(7.18), 100, "FIXTURE", "center")
    dxf.circle(ox + m(8.55), oy + m(6.75), 280)
    furniture(dxf, ox + m(0.55), oy + m(2.55), ox + m(2.70),
              oy + m(3.55), "TERRACE")
    dxf.circle(ox + m(1.62), oy + m(2.95), 140)
    dxf.label("02  SECOND FLOOR PLAN", "Scale 1:50 | FFL +3.000",
              ox, oy + 11500)
    dxf.hdim(ox, ox + 10000, oy - 900, oy, "10 000")
    dxf.vdim(oy, oy + 10000, ox - 900, ox, "10 000")
    room(dxf, ox + m(1.60), oy + m(7.45), "BEDROOM 3", "2 925 x 3 850")
    room(dxf, ox + m(5.05), oy + m(6.35), "FAMILY HALL")
    room(dxf, ox + m(8.40), oy + m(4.15), "BEDROOM 2", "2 800 x 3 275")
    room(dxf, ox + m(8.40), oy + m(6.25), "BATH 2", "2 800 x 1 375")
    north_arrow(dxf, ox + 10600, oy + 8500)


def draw_section(dxf, ox, oy):
    # Section A-A lies at y=6.00 m and looks north; x is horizontal.
    base = oy
    scale = 1000.0
    z_ground = lambda z: base + z * scale
    xcoord = lambda x: ox + m(x)
    dxf.line(xcoord(0), z_ground(-0.15), xcoord(10), z_ground(-0.15),
             "SECTION")
    # Ground slab and second-floor slab cross the section at y=6.00 m.
    dxf.rect(xcoord(0.15), z_ground(0.0), xcoord(9.85), z_ground(0.15),
             "WALL-EXT")
    dxf.rect(xcoord(0.15), z_ground(2.85), xcoord(7.05), z_ground(3.0),
             "WALL-EXT")
    # Ground-floor partitions and exterior wall cut edges.
    for x, top in [(0.15, 3.0), (3.15, 3.0), (9.85, 3.0)]:
        dxf.rect(xcoord(x - 0.075), z_ground(0.15),
                 xcoord(x + 0.075), z_ground(top), "WALL-EXT")
    # Upper-storey walls under the sloped roofs.
    lower_soffit = 5.82 + (6.0 - 3.40) * (-0.34 / 4.80) - 0.08
    upper_soffit = 6.32 + (6.0 - 0.85) * (-0.52 / 7.35) - 0.08
    dxf.rect(xcoord(0.15), z_ground(3.0),
             xcoord(0.225), z_ground(lower_soffit), "WALL-EXT")
    dxf.rect(xcoord(3.075), z_ground(3.0),
             xcoord(3.225), z_ground(upper_soffit), "WALL-EXT")
    dxf.rect(xcoord(9.775), z_ground(3.0),
             xcoord(9.925), z_ground(upper_soffit), "WALL-EXT")
    dxf.rect(xcoord(3.225), z_ground(3.0),
             xcoord(6.95), z_ground(upper_soffit), "WALL-INT")
    # Sloped roof tiers are viewed in cross-section as level edges at y=6 m.
    lower_roof = 5.82 + (6.0 - 3.40) * (-0.34 / 4.80)
    upper_roof = 6.32 + (6.0 - 0.85) * (-0.52 / 7.35)
    dxf.line(xcoord(0.15), z_ground(lower_roof),
             xcoord(3.075), z_ground(lower_roof), "ROOF")
    dxf.line(xcoord(0.15), z_ground(lower_roof + 0.10),
             xcoord(3.075), z_ground(lower_roof + 0.10), "ROOF")
    dxf.line(xcoord(3.075), z_ground(upper_roof),
             xcoord(9.85), z_ground(upper_roof), "ROOF")
    dxf.line(xcoord(3.075), z_ground(upper_roof + 0.10),
             xcoord(9.85), z_ground(upper_roof + 0.10), "ROOF")
    # The source stair has eight 275 mm lower goings and a 3-step turn.
    x0 = 6.775
    going = 0.275
    riser = 3.0 / 16.0
    for i in range(8):
        xa = x0 + i * going
        za = i * riser
        dxf.line(xcoord(xa), z_ground(za),
                 xcoord(xa), z_ground(za + riser), "STAIR")
        dxf.line(xcoord(xa), z_ground(za + riser),
                 xcoord(xa + going), z_ground(za + riser), "STAIR")
    x_land = x0 + 8 * going
    carriage_profile = [
        (x0, 0.02),
        (x_land, 0.02),
        (x_land, 8 * riser - 0.04),
    ]
    for i in range(8, 0, -1):
        x_end = x0 + i * going
        step_bottom = i * riser - 0.04
        carriage_profile.append((x_end, step_bottom))
        if i == 1:
            carriage_profile.extend([(x0, step_bottom), (x0, 0.02)])
        else:
            carriage_profile.append((x_end, (i - 1) * riser - 0.04))
    for start, end in zip(carriage_profile, carriage_profile[1:]):
        dxf.line(xcoord(start[0]), z_ground(start[1]),
                 xcoord(end[0]), z_ground(end[1]), "WALL-EXT")
    dxf.line(xcoord(8.975), z_ground(1.895), xcoord(9.795),
             z_ground(1.895), "STAIR")
    dxf.line(xcoord(8.975), z_ground(0.0), xcoord(8.975),
             z_ground(1.855), "STAIR")
    dxf.line(xcoord(9.795), z_ground(0.0), xcoord(9.795),
             z_ground(1.855), "STAIR")
    # Cut line and section arrows on both plans.
    for plan_ox, plan_oy in [(1500, 2000), (15000, 15000)]:
        y = plan_oy + m(6.0)
        dxf.line(plan_ox - 250, y, plan_ox + 10250, y, "SECTION", "CENTER")
        for x in [plan_ox - 250, plan_ox + 10250]:
            dxf.line(x, y, x, y + 300, "SECTION")
            dxf.line(x, y + 300, x - 110, y + 150, "SECTION")
            dxf.line(x, y + 300, x + 110, y + 150, "SECTION")
            dxf.text("A", x, y + 470, 180, "SECTION", "center")
    dxf.label("03  SECTION A-A", "Cut at Y=6.00 m | Looking north",
              ox, base + 7600)
    dxf.vdim(z_ground(0), z_ground(3), ox + m(10.9), ox + m(9.85),
             "+3 000")
    dxf.vdim(z_ground(0), z_ground(upper_roof + 0.10),
             ox + m(11.9), ox + m(9.85), "+6 056")
    dxf.text("MAIN ROOF DECK +5.956", xcoord(4.1),
             z_ground(upper_roof + 0.10) + 230, 120, "ROOF")
    dxf.text("SECOND FLOOR FFL +3.000", xcoord(0.25),
             z_ground(3.0) + 220, 120, "TEXT")
    dxf.text("GROUND FLOOR FFL +/-0.000", xcoord(0.25),
             z_ground(0.0) + 210, 120, "TEXT")
    dxf.text("STAIR FLIGHT / SECTIONED", xcoord(7.0),
             z_ground(2.05), 115, "STAIR")


def add_dxf_tables():
    out = DXF.pair(0, "SECTION") + DXF.pair(2, "HEADER")
    out += DXF.pair(9, "$ACADVER") + DXF.pair(1, "AC1009")
    out += DXF.pair(9, "$INSUNITS") + DXF.pair(70, "4")
    out += DXF.pair(9, "$MEASUREMENT") + DXF.pair(70, "1")
    out += DXF.pair(9, "$LIMMIN") + DXF.pair(10, "0") + DXF.pair(20, "-1500")
    out += DXF.pair(9, "$LIMMAX") + DXF.pair(10, "40000") + DXF.pair(20, "28000")
    out += DXF.pair(0, "ENDSEC")
    out += DXF.pair(0, "SECTION") + DXF.pair(2, "TABLES")
    out += DXF.pair(0, "TABLE") + DXF.pair(2, "LTYPE") + DXF.pair(70, "3")
    for name, description, pattern in [
        ("CONTINUOUS", "Solid line", []),
        ("DASHED", "Dashed line", [180, -100]),
        ("CENTER", "Center line", [400, -100, 80, -100]),
    ]:
        out += DXF.pair(0, "LTYPE") + DXF.pair(2, name)
        out += DXF.pair(70, "0") + DXF.pair(3, description)
        out += DXF.pair(72, "65") + DXF.pair(73, str(len(pattern)))
        out += DXF.pair(40, f"{sum(abs(v) for v in pattern):.3f}")
        for item in pattern:
            out += DXF.pair(49, f"{item:.3f}")
    out += DXF.pair(0, "ENDTAB")
    out += DXF.pair(0, "TABLE") + DXF.pair(2, "LAYER")
    out += DXF.pair(70, str(len(LAYERS)))
    for name, color in LAYERS.items():
        ltype = "DASHED" if name == "SITE" else (
            "CENTER" if name == "SECTION" else "CONTINUOUS")
        out += DXF.pair(0, "LAYER") + DXF.pair(2, name)
        out += DXF.pair(70, "0") + DXF.pair(62, str(color))
        out += DXF.pair(6, ltype)
    out += DXF.pair(0, "ENDTAB")
    out += DXF.pair(0, "ENDSEC")
    return out


def main():
    dxf = DXF()
    dxf.titleblock()
    draw_ground(dxf, 1500, 2000)
    draw_second(dxf, 15000, 15000)
    draw_section(dxf, 27500, 1800)
    content = (add_dxf_tables() + DXF.pair(0, "SECTION") +
               DXF.pair(2, "ENTITIES") + "".join(dxf.entities) +
               DXF.pair(0, "ENDSEC") + DXF.pair(0, "EOF"))
    OUT.write_text(content, encoding="ascii", newline="\n")
    try:
        BACKUP.unlink()
    except FileNotFoundError:
        pass
    except OSError as exc:
        raise RuntimeError(
            f"Could not remove {BACKUP}; close the CAD application and retry."
        ) from exc
    print(f"Wrote {OUT} ({len(dxf.entities)} entities)")


if __name__ == "__main__":
    main()
