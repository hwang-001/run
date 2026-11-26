"""Bake the arcade hourglass pickup as a compact glTF model."""
from math import cos, pi, sin
from pathlib import Path

import bpy

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, color, glow=0.0, roughness=0.34):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    node = result.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*color, 1)
    node.inputs["Roughness"].default_value = roughness
    node.inputs["Emission Color"].default_value = (*color, 1)
    node.inputs["Emission Strength"].default_value = glow
    return result


navy = material("Slate enamel", (0.075, 0.16, 0.31), 0.27)
rim = material("Cyan trim", (0.15, 0.75, 0.94), 0.38)
glass = material("Azure glass", (0.14, 0.55, 0.88), 0.22, 0.20)
ice = material("Ice facets", (0.48, 0.87, 0.97), 0.22)
sand = material("Hourglass sand", (0.68, 0.97, 1.0), 0.36)


def lathe(name, profile, materials, band_materials, sides=12):
    vertices = []
    for height, radius in profile:
        vertices.extend((cos(i * 2 * pi / sides) * radius, sin(i * 2 * pi / sides) * radius, height)
                        for i in range(sides))
    faces = [tuple(reversed(range(sides)))]
    for level in range(len(profile) - 1):
        for i in range(sides):
            base = level * sides
            nxt = (i + 1) % sides
            faces.append((base + i, base + nxt, base + sides + nxt, base + sides + i))
    faces.append(tuple(range(len(vertices) - sides, len(vertices))))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    result = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(result)
    for mat in materials:
        mesh.materials.append(mat)
    for i in range(1, len(faces) - 1):
        level = (i - 1) // sides
        mesh.polygons[i].material_index = band_materials[level % len(band_materials)]
    return result


for sign in (-1, 1):
    cap_steps = [(sign * .47, .338), (sign * .51, .390),
                 (sign * .59, .391), (sign * .632, .347)]
    lathe("Beveled cap", sorted(cap_steps), [navy, rim], [1, 0, 1])
lathe("Pinched blue crystal",
      [(-.49, .295), (-.40, .274), (-.16, .143), (-.051, .065),
       (.05, .065), (.17, .141), (.40, .274), (.49, .295)],
      [glass, ice], [0, 1, 0, 1, 0, 1, 0])
lathe("Sand in lower bulb", [(-.48, .297), (-.43, .255), (-.30, .105), (-.20, .018)], [sand], [0])
for i in range(4):
    angle = pi * (.25 + .5 * i)
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=.037, depth=1.03,
                                      location=(cos(angle) * .341, sin(angle) * .341, 0))
    bpy.context.object.name = "Cyan suspension rail"
    bpy.context.object.data.materials.append(rim)

output = Path(__file__).resolve().parents[1] / "assets/neon/slow-time.glb"
bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", export_animations=False)
