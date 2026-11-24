"""Build the articulated Murang asset with Blender 4.x in background mode."""
import math
from pathlib import Path

import bpy
from mathutils import Vector

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def color(name, hex_color, roughness=0.75):
    channels = [int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    shader = material.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*linear, 1)
    shader.inputs["Roughness"].default_value = roughness
    return material


fur = color("Vanilla fur", "f5c38e")
cream = color("Milk fur", "fff4df")
pink = color("Peach pink", "f48a97")
rose = color("Rosy heart", "fd6486", 0.45)
black = color("Dark cocoa", "271a23", 0.40)
gray = color("Graphite shell", "4b455a", 0.45)
key = color("Asphalt keys", "63596a", 0.55)
silver = color("Lavender faceplate", "c5c8d8", 0.55)
blue = color("Calculator LCD", "7ce3f2", 0.32)
blue.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (0.15, 0.64, 0.75, 1)
blue.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.23


def pivot(name, location, parent=None):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    node.location = location
    return node


def finish(node, name, parent, material, location, smooth=True):
    node.name = name
    node.parent = parent
    node.location = location
    node.data.materials.append(material)
    if smooth:
        for face in node.data.polygons:
            face.use_smooth = True
    return node


def blob(name, parent, material, location, radii):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20)
    node = finish(bpy.context.object, name, parent, material, location)
    node.scale = radii
    return node


def box(name, parent, material, location, dimensions, radius):
    bpy.ops.mesh.primitive_cube_add(size=1)
    node = bpy.context.object
    node.scale = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(node, name, parent, material, location)
    bevel = node.modifiers.new("Rounded edges", "BEVEL")
    bevel.width, bevel.segments = radius, 4
    node.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return node


def mesh(name, parent, material, vertices, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    node = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(node)
    return finish(node, name, parent, material, (0, 0, 0))


def recalculate_normals(node):
    bpy.context.view_layer.objects.active = node
    bpy.ops.object.select_all(action="DESELECT")
    node.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")


def tube(name, parent, material, sections, end_material=None):
    # Each section is a center and two ellipse radii. Sweep perpendicular to the spine.
    sides = 24
    vertices, faces = [], []
    for i, (point, a, b) in enumerate(sections):
        center = Vector(point)
        tangent = Vector(sections[min(i + 1, len(sections) - 1)][0]) - Vector(sections[max(0, i - 1)][0])
        side = tangent.normalized().cross(Vector((0, 1, 0))).normalized()
        up = tangent.normalized().cross(side).normalized()
        for j in range(sides):
            angle = j * 2 * math.pi / sides
            vertices.append(center + side * (a * math.cos(angle)) + up * (b * math.sin(angle)))
    for i in range(len(sections) - 1):
        for j in range(sides):
            k = (j + 1) % sides
            faces.append((i*sides+j, i*sides+k, (i+1)*sides+k, (i+1)*sides+j))
    faces.extend((tuple(reversed(range(sides))), tuple(range(len(vertices)-sides, len(vertices)))))
    node = mesh(name, parent, material, vertices, faces)
    recalculate_normals(node)
    if end_material:
        node.data.materials.append(end_material)
        for face in node.data.polygons:
            if (len(face.vertices) == 4 and face.index // sides >= len(sections) - 4) or face.index == len(faces) - 1:
                face.material_index = 1
    sub = node.modifiers.new("Sculpted silhouette", "SUBSURF")
    sub.levels = sub.render_levels = 2
    return node


def stroke(name, parent, material, points, radius):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions, curve.bevel_depth, curve.bevel_resolution = "3D", radius, 3
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for control, point in zip(spline.bezier_points, points):
        control.co = point
        control.handle_left_type = control.handle_right_type = "AUTO"
    node = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    node.data.materials.append(material)


root = pivot("MurangRig", (0, 0, 0))
body = pivot("Body", (0, 0, 0.70), root)
blob("Round torso", body, fur, (0, 0, 0.035), (0.365, 0.292, 0.40))
bib = blob("White bib", body, cream, (0, 0.242, 0.093), (0.245, 0.07, 0.211))
bib.rotation_euler.x = 0.18
blob("Bib point", body, cream, (-0.026, 0.270, -0.085), (0.083, 0.037, 0.101))
for sign, side in [(-1, "L"), (1, "R")]:
    arm = pivot("Arm" + side, (sign*0.32, 0.008, 0.155), body)
    paw = blob("Forepaw" + side, arm, fur, (sign*0.10, 0.04, -0.121), (0.146, 0.147, 0.239))
    paw.rotation_euler.y = -sign * 0.38
    leg = pivot("Leg" + side, (sign*0.19, -0.024, -0.225), body)
    blob("Hindpaw" + side, leg, fur, (0, 0.018, -0.242), (0.155, 0.192, 0.20))
    blob("Paw sole" + side, leg, pink, (0, 0.043, -0.424), (0.095, 0.111, 0.017))

tail = pivot("Tail", (0.042, -0.255, -0.143), body)
tube("Vanilla-tipped tail", tail, fur, [
    ((0, 0, 0), 0.099, 0.10),
    ((0.08, -0.13, 0.012), 0.146, 0.139),
    ((0.18, -0.235, 0.072), 0.18, 0.16),
    ((0.29, -0.276, 0.16), 0.18, 0.155),
    ((0.40, -0.271, 0.245), 0.142, 0.12),
    ((0.467, -0.236, 0.34), 0.10, 0.075),
    ((0.500, -0.19, 0.43), 0.039, 0.029),
    ((0.497, -0.166, 0.46), 0.003, 0.003),
], cream)

head = pivot("Head", (0, 0.008, 0.578), body)
blob("Round head", head, fur, (0, 0, 0), (0.597, 0.446, 0.482))
for sign, side in [(-1, "L"), (1, "R")]:
    tube("Ear" + side, head, fur, [
        ((sign*0.343, 0, 0.222), 0.212, 0.144),
        ((sign*0.385, -0.012, 0.385), 0.178, 0.128),
        ((sign*0.467, -0.027, 0.554), 0.125, 0.091),
        ((sign*0.539, -0.031, 0.688), 0.060, 0.048),
        ((sign*0.564, -0.031, 0.735), 0.006, 0.006),
    ])
    tube("Pink ear inset " + side, head, pink, [
        ((sign*0.369, 0.102, 0.315), 0.134, 0.035),
        ((sign*0.408, 0.103, 0.411), 0.112, 0.036),
        ((sign*0.471, 0.068, 0.535), 0.071, 0.025),
        ((sign*0.525, 0.025, 0.647), 0.004, 0.004),
    ])
    blob("Soft cream cheek " + side, head, cream, (sign*0.205, 0.165, -0.120), (0.386, 0.306, 0.272))
    eye = blob("Dark eye " + side, head, black, (sign*0.158, 0.421, 0.099), (0.038, 0.026, 0.065))
    eye.rotation_euler.z = -sign * 0.27
    blush = blob("Pink cheek " + side, head, pink, (sign*0.261, 0.467, -0.101), (0.085, 0.020, 0.082))
    blush.rotation_euler.z = -sign * 0.22
    stroke("Smile " + side, head, black, [(0, 0.481, -0.107), (sign*0.052, 0.482, -0.143), (sign*0.10, 0.478, -0.119)], 0.012)
blob("Cream muzzle", head, cream, (0, 0.252, -0.112), (0.277, 0.225, 0.199))
blob("Tongue", head, pink, (0, 0.469, -0.155), (0.053, 0.027, 0.044))
blob("Nose", head, black, (0, 0.488, -0.055), (0.049, 0.032, 0.034))
stroke("Philtrum", head, black, [(0, 0.496, -0.063), (0, 0.492, -0.103), (0, 0.485, -0.121)], 0.012)

calculator = pivot("Calculator", (0, 0.267, 0.432), head)
calculator.rotation_euler.x = 0.49
box("Calculator case", calculator, gray, (0, 0, 0), (0.343, 0.138, 0.400), 0.055)
box("Faceplate", calculator, silver, (0, 0.074, 0), (0.303, 0.028, 0.359), 0.027)
box("Screen frame", calculator, gray, (0, 0.091, 0.103), (0.233, 0.014, 0.077), 0.02)
box("Blue screen", calculator, blue, (0, 0.101, 0.103), (0.207, 0.011, 0.055), 0.016)
for row in range(3):
    for col in range(4):
        box(f"Key {row+1}-{col+1}", calculator, key, ((col-1.5)*0.058, 0.098, 0.024-row*0.056), (0.044, 0.025, 0.042), 0.008)

heart = pivot("Heart", (0, 0.055, 0.828), head)
outline = [(-0.001,-0.107), (-0.064,-0.050), (-0.118,0.008), (-0.120,0.066),
           (-0.089,0.109), (-0.043,0.114), (0,0.083), (0.043,0.114),
           (0.089,0.109), (0.120,0.066), (0.118,0.008), (0.064,-0.050)]
vertices = [(x*scale, y, z*scale) for y, scale in [(-0.064,0.36),(-0.045,0.82),(0,1.10),(0.045,0.82),(0.064,0.36)] for x,z in outline]
n = len(outline)
faces = [(i*n+j, i*n+(j+1)%n, (i+1)*n+(j+1)%n, (i+1)*n+j) for i in range(4) for j in range(n)]
faces += [tuple(reversed(range(n))), tuple(range(n*4,n*5))]
heart_mesh = mesh("Heart charm", heart, rose, vertices, faces)
recalculate_normals(heart_mesh)
sub = heart_mesh.modifiers.new("Soft shape", "SUBSURF")
sub.levels = sub.render_levels = 2

output = Path(__file__).resolve().parents[1] / "assets/character/murang.glb"
bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", export_apply=True, export_animations=False)
