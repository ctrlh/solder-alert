// solder-alert.scad
//
// Designed to be printed using transparent or white filament, so the lighting
// shines through with some diffusion.
//
// Screws are M3 x 8mm flat head self-tappers (Philips). The threads on machine
// screws are too fine and will just spin in the guide holes unless their
// diameters are adjusted.
//

tolerance             =  0.15;

display_width         = 24.55 + tolerance * 2;
display_depth         = 44.50 + tolerance * 2;
mcu_lcd_height        =  5.40;
mcu_lcd_proud         =  0.60; // exposed rounding on the front face
mcu_lcd_internal      = (mcu_lcd_height - mcu_lcd_proud);
mcu_pcb_thickness     =  1.20;
mcu_standoff_height   =  4.00;
display_height        = (mcu_lcd_internal + mcu_pcb_thickness + mcu_standoff_height);
display_radius        =  5.75 + tolerance;
retainer_thickness    =  1.00;

rear_pillar_width     =  5.00;
rear_pillar_depth     = 40.00;
rear_pillar_height    =  3.90;

pcb_thickness         =  1.60;

wall_thickness        =  2.00;
wall_chamfer          =  0.60;

front_pillar_width    =  2.00;
front_pillar_depth    = 12.00;
front_pillar_height   = (display_height - wall_thickness);

// Internal dimensions
internal_box_width    = 70.00;
internal_box_depth    = 54.00;
internal_box_height   = (front_pillar_height + pcb_thickness + rear_pillar_height);

screw_diameter        =  3.00; // M3
screw_radius          = (screw_diameter / 2);
screw_pilot_diameter  = (screw_diameter * 0.95);
screw_head_diameter   =  5.60; // M3 => dk.max = 5.6
screw_shoulder        =  0.25;
screw_post_diameter   = (screw_diameter * 2.5);
screw_post_split      =  2.00;

box_radius            = (screw_post_diameter / 2 + wall_thickness); // M3 flat head

usb_block_depth       = (internal_box_depth - display_depth) / 2 + retainer_thickness;

usb_c_width           = 10.00;
usb_c_diameter        =  3.30;
usb_c_depth           = 10.00;

usb_cavity_width      = 16.00;
usb_cavity_height     =  8.50;
usb_cavity_v_center   = (mcu_lcd_internal + mcu_pcb_thickness + usb_c_diameter / 2);

ziptie_slot_width     = 1.5;
ziptie_slot_depth     = 7.0;
ziptie_mount_height   = (internal_box_height - mcu_standoff_height) - usb_c_diameter / 2 - wall_thickness / 2;
ziptie_mount_width    = 8.0;
ziptie_mount_depth    = (ziptie_slot_depth * 1.5);

epsilon               =  0.01;
$fn                   = 60;

// 2D rounded rectangle in XY.
module rounded_rect(size, radius, center = true) {
  offset(r = radius) {
    offset(delta = -radius) {
      square([size[0], size[1]], center = center);
    }
  }
}

// --- 2D rounded rectangle, centered ---
module _rounded_rect_2d(size, radius, center = true) {
  // Caveat: requires radius < min(width, length) / 2 to avoid
  // degenerate geometry from offset on a zero or negative square.
  assert(radius < min(size[0], size[1]) / 2, "Degenerate geometry from zero/negative square");

  offset(r = radius) {
    square([size[0] - 2 * radius, size[1] - 2 * radius], center = center);
  }
}

// 3D rounded box (rounded in XY, flat in Z).
module rounded_box(size, radius, center = true) {
  linear_extrude(height = size[2], center = center) {
    rounded_rect([size[0], size[1]], radius, center);
  }
}

// --- Chamfered extrusion via Minkowski with a 45 degree bicone ---
// The bicone kernel adds edge_chamfer to all XY dimensions and
// 2 * edge_chamfer to Z height, so the base shape is reduced to
// compensate.  The result is a body with the same nominal outer
// dimensions but 45 degree chamfers on every horizontal edge,
// blending smoothly into the rounded corners.
// Caveat: Minkowski is computationally expensive in preview mode.
// Reduce circle_fragments if preview is slow.
module _chamfered_extrude(width, length, height, radius, chamfer) {
  circle_fragments = 36;     // $fn for cylinders and arcs
  minkowski() {
    linear_extrude(height = height - 1 * chamfer) {
      _rounded_rect_2d(
        [width  - 1 * chamfer, length - 1 * chamfer],
        max(0, radius - chamfer)
      );
    }
    // Bicone: two cones base-to-base, total height = 2 * chamfer
    hull() {
      cylinder(r1 = 0, r2 = chamfer, h = chamfer, $fn = circle_fragments);
//      translate([0, 0, chamfer]) {
//        cylinder(r1 = chamfer, r2 = 0, h = chamfer, $fn = circle_fragments);
//      }
    }
  }
}

module _box_frame() {
  translate([0, 0, (internal_box_height + wall_thickness) / 2]) {
    difference() {
      // Outer box
      color("white")
//      rounded_box(
//        size = [
//          internal_box_width + wall_thickness * 2,
//          internal_box_depth + wall_thickness * 2,
//          internal_box_height + wall_thickness
//        ],
//        radius = box_radius,
//        center = true
//      );
        translate([
          0,
          0,
          -(internal_box_height + wall_thickness) / 2
        ]) {
          _chamfered_extrude(
            internal_box_width + wall_thickness * 2,
            internal_box_depth + wall_thickness * 2,
            internal_box_height + wall_thickness,
            box_radius,
            wall_chamfer);
        }

      // Remove inner box
      translate([0, 0, wall_thickness / 2]) {
        color("gray")
        rounded_box(
          size = [
            internal_box_width,
            internal_box_depth,
            internal_box_height + epsilon
          ],
          radius = box_radius - wall_thickness,
          center = true
        );
      }
    }
  }
}

module _display_retaining_wall() {
  _internal_box_height = mcu_lcd_internal + mcu_pcb_thickness + epsilon * 2;
  // Retaining walls for display
  translate([
    0,
    0,
    _internal_box_height / 2 + epsilon
   ]) {
    color("blue")
    rounded_box(
      size = [
        display_width + retainer_thickness * 2,
        display_depth + retainer_thickness * 2,
        _internal_box_height
      ],
      radius = display_radius + retainer_thickness,
      center = true
    );
  }
}

module _display_cutout() {
  usb_gap = mcu_standoff_height - usb_c_diameter;

  translate([
    0,
    0,
    display_height / 2 - usb_gap / 2 // - epsilon
   ]) {
    rounded_box(
      size = [display_width, display_depth, display_height - usb_gap + epsilon * 2],
      radius = display_radius,
      center = true
    );
  }
}

module _front_pillars() {
  front_pillar_x_ofs = display_width / 2 + retainer_thickness + front_pillar_width / 2;
  for(x_ofs = [-front_pillar_x_ofs, +front_pillar_x_ofs]) {
    translate([
      x_ofs,
      0,
      front_pillar_height / 2 + wall_thickness - epsilon
    ]) {
      color("red")
      cube([
        front_pillar_width,
        front_pillar_depth,
        front_pillar_height + epsilon
      ], center = true);
    }
  }
}

module _screw_posts() {
  x_ofs = internal_box_width / 2 + wall_thickness - box_radius;
  y_ofs = internal_box_depth / 2 + wall_thickness - box_radius;
  z_ofs = (internal_box_height / 2 + wall_thickness / 2) - epsilon;

  color("green")
  for(x = [-x_ofs, +x_ofs]) {
    for(y = [-y_ofs, +y_ofs]) {
      translate([x, y, z_ofs]) {
        difference() {
          cylinder(
            h = internal_box_height - screw_post_split + epsilon,
            d = screw_diameter * 2.5,
            center = true
          );
          translate([0, 0, epsilon]) {
            cylinder(
              h = internal_box_height - screw_post_split + epsilon * 2,
              d = screw_pilot_diameter,
              center = true
            );
          }
        }
      }
    }
  }
}

module _usb_block() {
  color("brown")
  translate([
    0,
    -display_depth / 2 - usb_block_depth / 2 + retainer_thickness - epsilon,
    (internal_box_height / 2) + wall_thickness
  ]) {
    cube(
      [
        display_width,
        usb_block_depth + epsilon,
        internal_box_height + epsilon
      ],
      center = true);
  }
}

module _usb_c_outline() {
  color("yellow")
  translate([
    0,
    -display_depth / 2,
    usb_cavity_v_center
  ])
  rotate([90, 0, 0])
  hull() {
    translate([-usb_c_width / 2 + usb_c_diameter / 2, 0, 0]) {
      cylinder(h = usb_c_depth, d = usb_c_diameter, center = true);
    }
    translate([usb_c_width / 2 - usb_c_diameter / 2, 0, 0]) {
      cylinder(h = usb_c_depth, d = usb_c_diameter, center = true);
    }
  }
}

module _usb_cavity() {
  _depth = usb_block_depth + wall_thickness;
  color("purple")
  translate([
    0, // (internal_box_width + (wall_thickness) * 2) / 2,
    -display_depth / 2 - retainer_thickness - _depth / 2 - epsilon,
    usb_cavity_v_center
  ]) {
    rotate([90, 0, 0]) {
      hull() {
        translate([-usb_cavity_width / 2 + usb_cavity_height / 4, 0, 0]) {
          cylinder(h = _depth, d = usb_cavity_height, center = true);
        }
        translate([+usb_cavity_width / 2 - usb_cavity_height / 4, 0, 0]) {
          cylinder(h = _depth, d = usb_cavity_height, center = true);
        }
      }
    }
  }
}

// Front face down
module box_front() {
  difference() {
    union() {
      difference() {
        union() {
          _box_frame();
          _display_retaining_wall();
          _usb_block();
        }
        _display_cutout();
      }

      _front_pillars();
      _screw_posts();
    }
    _usb_cavity();
    _usb_c_outline();
  }
}

module _ziptie_mount() {
  _height = ziptie_mount_height + wall_thickness / 2;
  translate([0, 0, _height / 2 + wall_thickness / 2]) {
    difference() {
      intersection() {
        rotate([90, 0, 0]) {
          color("pink")
          rounded_box(
            size = [ziptie_mount_width, _height, ziptie_slot_depth * 2],
            radius = wall_thickness,
            center = true
          );
        }
        rotate([0, 90, 0]) {
          color("blue")
          rounded_box(
            size = [_height + 2 * epsilon, ziptie_slot_depth * 2 + 2 * epsilon, ziptie_mount_width + 2 * epsilon],
            radius = wall_thickness,
            center = true
          );
        }
      }

      translate([0, 0, _height / 2]) {
        rotate([90, 0, 0]) {
          cylinder(h = ziptie_slot_depth * 2 + 1, d = usb_c_diameter, center = true);
        }
      }
    }
  }
}

module _ziptie_slot() {
  translate([
    internal_box_width / 2 + wall_thickness,
    -internal_box_depth / 2,
    wall_thickness * 0.75 - epsilon
  ]) {
    rotate([90, 0, 0]) {
      rounded_box(
        size = [
          ziptie_mount_width + ziptie_slot_width * 2,
          wall_thickness * 2 + epsilon,
          ziptie_slot_depth
        ],
        radius = wall_thickness,
        center = true
      );
    }
  }
}

module _box_rear_base_minimal() {
//  rounded_box(
//    size = [
//      internal_box_width + wall_thickness * 2,
//      internal_box_depth + wall_thickness * 2,
//      wall_thickness
//    ],
//    radius = box_radius,
//    center = false
//  );

  translate([
    internal_box_width / 2 + wall_thickness,
    internal_box_depth / 2 + wall_thickness,
    0
  ]) {
    _chamfered_extrude(
      internal_box_width + wall_thickness * 2,
      internal_box_depth + wall_thickness * 2,
      wall_thickness,
      box_radius,
      wall_chamfer);
  }
}

module _box_rear_base_extended() {
  hull() {
    _box_rear_base_minimal();
    translate([
      internal_box_width /2 + wall_thickness,
      -internal_box_depth /2 + box_radius,
      0
    ]) {
      cylinder(h = wall_thickness, r = box_radius * 4, center = false);
    }
  }
}

module _box_rear_alignment_posts() {
  for(x_ofs = [box_radius, internal_box_width + wall_thickness * 2 - box_radius]) {
    for(y_ofs = [box_radius, internal_box_depth + 2 * wall_thickness - box_radius]) {
      translate([x_ofs, y_ofs, wall_thickness - epsilon]) {
        color("green")
        cylinder(h = screw_post_split - epsilon, d = screw_post_diameter);
      }
    }
  }
}

module _box_rear_screw_heads() {
  for(x_ofs = [box_radius, internal_box_width + wall_thickness * 2 - box_radius]) {
    for(y_ofs = [box_radius, internal_box_depth + 2 * wall_thickness - box_radius]) {
      translate([x_ofs, y_ofs, -epsilon]) {
        color("magenta")
        cylinder(h = screw_shoulder, d = screw_head_diameter);
        color("cyan")
        translate([0, 0, screw_shoulder - epsilon]) {
          cylinder(
            h = screw_head_diameter / 2 - screw_radius,
            d1 = screw_head_diameter,
            d2 = screw_diameter - epsilon
          );
        }
        color("orange")
        cylinder(
          h = internal_box_height + epsilon * 2,
          d = screw_diameter
        );
      }
    }
  }
}

module _rear_pillars() {
  translate([
    internal_box_width / 2 + wall_thickness - rear_pillar_width / 2,
    internal_box_depth / 2 + wall_thickness - rear_pillar_depth / 2,
    wall_thickness - epsilon
  ]) {
    cube([
      rear_pillar_width,
      rear_pillar_depth,
      rear_pillar_height
    ]);
  }
}

// Rear face down
module box_rear(extended = false) {
  union() {
    difference() {
      union() {
        if (extended) {
          _box_rear_base_extended();
        } else {
          _box_rear_base_minimal();
        }

        _box_rear_alignment_posts();
      }

      if (extended) {
        _ziptie_slot();
      }

      _box_rear_screw_heads();
    }

    if (extended) {
      translate([
        internal_box_width / 2 + wall_thickness,
        -internal_box_depth / 2,
        0
      ]) {
        _ziptie_mount();
      }
    }

    _rear_pillars();
  }
}

module solder_alert() {
  translate([200, internal_box_depth / 2 + wall_thickness, 0]) {
    box_front();
  }
  translate([50, 0, 0]) {
    box_rear(false);
  }
}

solder_alert();
