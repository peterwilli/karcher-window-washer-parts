use <Round-Anything/polyround.scad>
use <dotscad/path_extrude.scad>
use <dotscad/bezier_curve.scad>
use <dotscad/util/lerp.scad>
use <dotscad/sweep.scad>
use <dotscad/ptf/ptf_rotate.scad>
use <dotscad/angle_between.scad>
use <dotscad/util/sum.scad>
include <BOSL/constants.scad>
use <BOSL/debug.scad>

$fn = 10;
bottomWidth = 100;
topWidth = 50;
height = 30;
sideLift = 2;
sideWidth = 5;
bottomCurveRadius = 5;
circleHeight = 5;
circleRadius = 500;
insideThickness = 2;
topBottomBorderHeight = 5;
baseHeight = 2;
screwHoleInnerRadius = 2;
topBendDegrees = 10;
screwHoleOuterRadius = 4;
screwHoleOuterConeHeight = 2;
screwHoleInnerPadRadius = 1;
screwHoleInnerPadThickness = 0.5;
screwHoleInnerPadHeight = 2;
topForward = 1.5;
clipWidth = 20;
clipTopHeight = 2;
clipFrontWidth = 1.5;
clipInsideHeight = 4;
clipOutsideHeight = 6;
clipFrontThickness = 1;

function addZ(polys, z) = [for(poly = polys) [poly[0], poly[1], z]];

module shape() {
    toRemoveAtTop = (bottomWidth - topWidth) / 2;
    module base() {
        function basePoints(bottomAxis, sideWidth, sideLift, bottomCurveRadius, bottomWidth, toRemoveAtTop, height, toRemoveAtTop, circleHeight) =
        let(topExtraWidth = lerp(0, bottomWidth, bottomAxis / 112))
        [
            // Sidelift bottom left
            [0 - topExtraWidth, sideLift - bottomAxis, 0],
            // Bottom left
            [sideWidth - bottomAxis, 0 - bottomAxis, bottomCurveRadius],
            // Bottom Right
            [bottomWidth - sideWidth + topExtraWidth, 0 - bottomAxis, bottomCurveRadius],
            // Sidelift bottom right
            [bottomWidth + topExtraWidth, sideLift - bottomAxis, 0],
            // Top right
            [bottomWidth - toRemoveAtTop, height, 0],
            // Middle part
            [bottomWidth / 2, height - circleHeight, circleRadius],
            // Top Left
            [toRemoveAtTop, height, 0]
        ];
        points1 = polyRound(basePoints(0, sideWidth, sideLift, bottomCurveRadius, bottomWidth, toRemoveAtTop, height, toRemoveAtTop, circleHeight), $fn);
        topForward = lerp(0, topForward, baseHeight / topBottomBorderHeight);
        points2 = polyRound(basePoints(topForward, sideWidth, sideLift, bottomCurveRadius, bottomWidth, toRemoveAtTop, height, toRemoveAtTop, circleHeight), $fn);
        sweep([
            addZ(points2, baseHeight),
            addZ(points1, 0),
        ]);
    }
    base();
}

function angle(p1, p2) = let(y = p2.y - p1.y, x = p2.x - p1.x) atan2(y, x);
function centerPoints(pts) =
    let(offsetPts = sum(pts) / len(pts))
    [[for(pt = pts) pt - offsetPts], offsetPts];
        
function decenterPoints(pts, offsetPts) =
    [for(pt = pts) pt + offsetPts];

function getBoundingBoxOfPoints(pts) = 
    [for(i = [0 : len(pts[0]) - 1])
        max([for(pt = pts) pt[i]]) - min([for(pt = pts) pt[i]])
    ];
        
function getMinMaxPerPoint(pts) = 
    [for(i = [0 : len(pts[0]) - 1])
        [min([for(pt = pts) pt[i]]), max([for(pt = pts) pt[i]])]
    ];
        
module topBorder() {
    toRemoveAtTop = (bottomWidth - topWidth) / 2;
    topPartAngle = angle([0, sideLift], [toRemoveAtTop, height]);
    function borderPoints(bottomAxis, sideWidth, sideLift, bottomCurveRadius, bottomWidth, toRemoveAtTop, height, toRemoveAtTop, circleHeight) =
        let(topExtraWidth = lerp(0, bottomWidth, bottomAxis / 112))
        polyRound(beamChain([
             // Sidelift bottom left
            [0 - topExtraWidth, sideLift - bottomAxis, 0],
            // Bottom left
            [sideWidth - bottomAxis, 0 - bottomAxis, bottomCurveRadius],
            // Bottom Right
            [bottomWidth - sideWidth + topExtraWidth, 0 - bottomAxis, bottomCurveRadius],
            // Sidelift bottom right
            [bottomWidth + topExtraWidth, sideLift - bottomAxis, 0],
        ], offset1=insideThickness, offset2=0, mode=2, startAngle=topPartAngle, endAngle=topPartAngle * -1), $fn);
    topForwardShape = lerp(0, topForward, baseHeight / topBottomBorderHeight);
    shapePts = addZ(borderPoints(topForwardShape, sideWidth, sideLift, bottomCurveRadius, bottomWidth, toRemoveAtTop, height, toRemoveAtTop, circleHeight), 0);
    shapePts2 = addZ(borderPoints(topForwardShape + topForward, sideWidth, sideLift, bottomCurveRadius, bottomWidth, toRemoveAtTop, height, toRemoveAtTop, circleHeight), topBottomBorderHeight);
    boundingBox = getBoundingBoxOfPoints(shapePts2);
    minMax = getMinMaxPerPoint(shapePts2);
    difference() {
        translate([0, 0, baseHeight]) {
            sweep([
                shapePts2, shapePts
            ]);
        }
        translate([minMax[0][0], minMax[1][0] + boundingBox[1], topBottomBorderHeight + baseHeight]) rotate([topBendDegrees, 0, 0]) translate([0, boundingBox[1] * -1, 0]) cube([boundingBox[0], boundingBox[1], 10]);
    }
}

function bottomBorderPointsInner(bottomWidth, topWidth, sideLift, height, insideThickness) =
    let(toRemoveAtTop = (bottomWidth - topWidth) / 2)
    let(topPartAngle = angle([0, sideLift, 0], [toRemoveAtTop, height, 0]))
    [
         // Top right
        [bottomWidth - toRemoveAtTop, height, 0],
        // Middle part
        [bottomWidth / 2, height - circleHeight, circleRadius],
        // Top Left
        [toRemoveAtTop, height, 0]
    ];

function bottomBorderPoints(bottomWidth, topWidth, sideLift, height, insideThickness) =
    let(toRemoveAtTop = (bottomWidth - topWidth) / 2)
    let(topPartAngle = angle([0, sideLift, 0], [toRemoveAtTop, height, 0]))
    
    polyRound(beamChain(bottomBorderPointsInner(bottomWidth, topWidth, sideLift, height, insideThickness), offset2=0, offset1=insideThickness * -1, mode=2, startAngle=topPartAngle * -1, endAngle=topPartAngle), $fn);

module bottomBorder() {
    translate([0, 0, baseHeight]) linear_extrude(height=topBottomBorderHeight) polygon(points=bottomBorderPoints(bottomWidth, topWidth, sideLift, height, insideThickness));
}

module clip() {
    module clipInner() {
        points1 = bottomBorderPoints(bottomWidth, topWidth, sideLift, height, insideThickness);
        bb1 = getBoundingBoxOfPoints(points1);
            
        module clipInner1() {
            clipFullHeight = 5;
            function clipPolys(clipFrontThickness, clipTopHeight, clipFullHeight) = [
                [0, 0, 0],
                [5, 0, 2],
                [5 + clipFrontThickness, 1, 2],
                [5 + clipFrontThickness, 3, 0],
                [5.2, clipFullHeight, 0.5],
                [5, clipFullHeight, 0.5],
                [5, clipTopHeight, 0],
                [0, clipTopHeight, 0]
            ];
            * translate([-10, 0, 0]) {
                debug_vertices(vertices=clipPolys(clipFrontThickness, clipTopHeight, clipFullHeight));
                polygon(polyRound(clipPolys(clipFrontThickness, clipTopHeight, clipFullHeight), $fn));
            }
            fullClipPoints = polyRound(clipPolys(clipFrontThickness, clipTopHeight, clipFullHeight), $fn);
            clipPath = [
                [topWidth + (clipWidth / 2), 0, 0],
                [topWidth - (clipWidth / 2), 0, 0]
            ];
            translate([0, height - bb1[1], baseHeight + topBottomBorderHeight]) rotate([10, 0, 0]) translate([0, 0, clipTopHeight]) scale([1, 1, -1]) path_extrude(fullClipPoints, clipPath);
        }
        module clipInner2() {
            epsilon = 0;
            translate([(bottomWidth / 2) - ((clipWidth + epsilon) / 2), height - bb1[1], 0]) cube([clipWidth + epsilon, insideThickness, 10]);
        }
        
        clipInner1();
        intersection() {
            translate([0, 0, 2]) bottomBorder();
            color("yellow") clipInner2();
        }
    }
    
    module clipOuter() {
        function bottomBorderPointsThick(bottomWidth, topWidth, sideLift, height, insideThickness) =
        let(toRemoveAtTop = (bottomWidth - topWidth) / 2)
        let(topPartAngle = angle([0, sideLift, 0], [toRemoveAtTop, height, 0]))
        
        polyRound(beamChain(bottomBorderPointsInner(bottomWidth, topWidth, sideLift, height, insideThickness), offset2=10, offset1=insideThickness * -1, mode=2, startAngle=topPartAngle * -1, endAngle=topPartAngle), $fn);
        
        points = bottomBorderPointsThick(bottomWidth, topWidth, sideLift, height, insideThickness);
        color("green") translate([0,0, baseHeight + topBottomBorderHeight / 2]) linear_extrude(height=clipOutsideHeight) polygon(points=bottomBorderPointsThick(bottomWidth, topWidth, sideLift, height, insideThickness));
        
    }
    
   intersection() {
        clipInner();
        clipOuter();
    }
}

module screwHole() {
    module screwHoleInner() {
        translate([bottomWidth / 2, screwHoleInnerRadius + (screwHoleOuterRadius / 2), -0.01]) cylinder(15, r1=screwHoleInnerRadius, r2=screwHoleInnerRadius, $fn=100);
        
    }
    
    module screwPad() {
        translate([bottomWidth / 2, screwHoleInnerRadius + (screwHoleOuterRadius / 2), screwHoleInnerPadHeight]) difference() {
            cylinder(screwHoleInnerPadThickness, r=screwHoleInnerRadius, $fn=100);
        color("red") translate([0, 0, -0.05]) cylinder(screwHoleInnerPadThickness + 0.1, r=screwHoleInnerPadRadius, $fn=100);
        }
    }

    module screwHoleOuter() {
        translate([bottomWidth / 2, screwHoleOuterRadius, 0]) {
            difference() {
                cylinder(10, r1=screwHoleOuterRadius, r2=screwHoleOuterRadius, $fn=100);
                translate([0, 0, 10 - (screwHoleOuterConeHeight * 0.999)]) cylinder(screwHoleOuterConeHeight, r1=0.001, r2=screwHoleOuterRadius, $fn=100);
            }
        }
    }
    
    rotate([topBendDegrees, 0, 0]) screwPad();
    difference() {
        union() {            
            children($children - 1);
            color([0.2, 0.2, 1]) rotate([topBendDegrees, 0, 0]) screwHoleOuter();
        }
        color([1, 0, 1]) rotate([topBendDegrees, 0, 0]) translate([0, 0, -2]) screwHoleInner();
    }
}

screwHole() {
    shape();
}

clip();
topBorder();
bottomBorder();