// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

struct MatrixUtils {
    /// Returns the given [transform] matrix as an [Offset], if the matrix is
    /// nothing but a 2D translation.
    ///
    /// Otherwise, returns null.
    static func getAsTranslation(_ transform: Matrix4x4f) -> Offset? {
        // Values are stored in column-major order.
        if transform[0, 0] == 1.0  // col 1
            && transform[0, 1] == 0.0
            && transform[0, 2] == 0.0
            && transform[0, 3] == 0.0
            && transform[1, 0] == 0.0  // col 2
            && transform[1, 1] == 1.0
            && transform[1, 2] == 0.0
            && transform[1, 3] == 0.0
            && transform[2, 0] == 0.0  // col 3
            && transform[2, 1] == 0.0
            && transform[2, 2] == 1.0
            && transform[2, 3] == 0.0
            && transform[3, 2] == 0.0  // bottom of col 4 (transform 12 and 13 are the x and y offsets)
            && transform[3, 3] == 1.0
        {
            return Offset(transform[3, 0], transform[3, 1])
        }
        return nil
    }

    /// Returns the given [transform] matrix as a [double] describing a uniform
    /// scale, if the matrix is nothing but a symmetric 2D scale transform.
    ///
    /// Otherwise, returns null.
    static func getAsScale(_ transform: Matrix4x4f) -> Float? {
        // Values are stored in column-major order.
        if transform[0, 1] == 0.0  // col 1 (value 0 is the scale)
            && transform[0, 2] == 0.0
            && transform[0, 3] == 0.0
            && transform[1, 0] == 0.0  // col 2 (value 5 is the scale)
            && transform[1, 2] == 0.0
            && transform[1, 3] == 0.0
            && transform[2, 0] == 0.0  // col 3
            && transform[2, 1] == 0.0
            && transform[2, 2] == 1.0
            && transform[2, 3] == 0.0
            && transform[3, 0] == 0.0  // col 4
            && transform[3, 1] == 0.0
            && transform[3, 2] == 0.0
            && transform[3, 3] == 1.0
            && transform[0, 0] == transform[1, 1]
        {  // uniform scale
            return transform[0, 0]
        }
        return nil
    }

    /// Returns true if the given matrices are exactly equal, and false
    /// otherwise. Null values are assumed to be the identity matrix.
    static func matrixEquals(_ a: Matrix4x4f?, _ b: Matrix4x4f?) -> Bool {
        if a == b {
            return true
        }
        assert(a != nil || b != nil)
        if a == nil {
            return isIdentity(b!)
        }
        if b == nil {
            return isIdentity(a!)
        }
        return a![0, 0] == b![0, 0]
            && a![0, 1] == b![0, 1]
            && a![0, 2] == b![0, 2]
            && a![0, 3] == b![0, 3]
            && a![1, 0] == b![1, 0]
            && a![1, 1] == b![1, 1]
            && a![1, 2] == b![1, 2]
            && a![1, 3] == b![1, 3]
            && a![2, 0] == b![2, 0]
            && a![2, 1] == b![2, 1]
            && a![2, 2] == b![2, 2]
            && a![2, 3] == b![2, 3]
            && a![3, 0] == b![3, 0]
            && a![3, 1] == b![3, 1]
            && a![3, 2] == b![3, 2]
            && a![3, 3] == b![3, 3]
    }

    /// Whether the given matrix is the identity matrix.
    static func isIdentity(_ a: Matrix4x4f) -> Bool {
        return a[0, 0] == 1.0  // col 1
            && a[0, 1] == 0.0
            && a[0, 2] == 0.0
            && a[0, 3] == 0.0
            && a[1, 0] == 0.0  // col 2
            && a[1, 1] == 1.0
            && a[1, 2] == 0.0
            && a[1, 3] == 0.0
            && a[2, 0] == 0.0  // col 3
            && a[2, 1] == 0.0
            && a[2, 2] == 1.0
            && a[2, 3] == 0.0
            && a[3, 0] == 0.0  // col 4
            && a[3, 1] == 0.0
            && a[3, 2] == 0.0
            && a[3, 3] == 1.0
    }

    /// Applies the given matrix as a perspective transform to the given point.
    ///
    /// This function assumes the given point has a z-coordinate of 0.0. The
    /// z-coordinate of the result is ignored.
    ///
    /// While not common, this method may return (NaN, NaN), iff the given `point`
    /// results in a "point at infinity" in homogeneous coordinates after applying
    /// the `transform`. For example, a [RenderObject] may set its transform to
    /// the zero matrix to indicate its content is currently not visible. Trying
    /// to convert an `Offset` to its coordinate space always results in
    /// (NaN, NaN).
    static func transformPoint(_ transform: Matrix4x4f, _ point: Offset) -> Offset {
        let x = point.dx
        let y = point.dy

        // Directly simulate the transform of the vector (x, y, 0, 1),
        // dropping the resulting Z coordinate, and normalizing only
        // if needed.

        let rx = transform[0, 0] * x + transform[1, 0] * y + transform[3, 0]
        let ry = transform[0, 1] * x + transform[1, 1] * y + transform[3, 1]
        let rw = transform[0, 3] * x + transform[1, 3] * y + transform[3, 3]
        if rw == 1.0 {
            return Offset(rx, ry)
        } else {
            return Offset(rx / rw, ry / rw)
        }
    }

    /// Returns a rect that bounds the result of applying the given matrix as a
    /// perspective transform to the given rect.
    ///
    /// This version of the operation is slower than the regular transformRect
    /// method, but it avoids creating infinite values from large finite values
    /// if it can.
    static func _safeTransformRect(_ transform: Matrix4x4f, _ rect: Rect) -> Rect {
        let isAffine = transform[0, 3] == 0.0 && transform[1, 3] == 0.0 && transform[3, 3] == 1.0

        _accumulate(transform, rect.left, rect.top, true, isAffine)
        _accumulate(transform, rect.right, rect.top, false, isAffine)
        _accumulate(transform, rect.left, rect.bottom, false, isAffine)
        _accumulate(transform, rect.right, rect.bottom, false, isAffine)

        return Rect(left: _minMax[0], top: _minMax[1], right: _minMax[2], bottom: _minMax[3])
    }

    static var _minMax = [Float](repeating: 0, count: 4)
    static func _accumulate(
        _ m: Matrix4x4f,
        _ x: Float,
        _ y: Float,
        _ first: Bool,
        _ isAffine: Bool
    ) {
        let w = isAffine ? 1.0 : 1.0 / (m[0, 3] * x + m[1, 3] * y + m[3, 3])
        let tx = (m[0, 0] * x + m[1, 0] * y + m[3, 0]) * w
        let ty = (m[0, 1] * x + m[1, 1] * y + m[3, 1]) * w
        if first {
            _minMax[0] = tx
            _minMax[2] = tx
            _minMax[1] = ty
            _minMax[3] = ty
        } else {
            if tx < _minMax[0] {
                _minMax[0] = tx
            }
            if ty < _minMax[1] {
                _minMax[1] = ty
            }
            if tx > _minMax[2] {
                _minMax[2] = tx
            }
            if ty > _minMax[3] {
                _minMax[3] = ty
            }
        }
    }

    /// Returns a rect that bounds the result of applying the given matrix as a
    /// perspective transform to the given rect.
    ///
    /// This function assumes the given rect is in the plane with z equals 0.0.
    /// The transformed rect is then projected back into the plane with z equals
    /// 0.0 before computing its bounding rect.
    static func transformRect(_ transform: Matrix4x4f, _ rect: Rect) -> Rect {
        let x = rect.left
        let y = rect.top
        let w = rect.right - x
        let h = rect.bottom - y

        // We want to avoid turning a finite rect into an infinite one if we can.
        if !w.isFinite || !h.isFinite {
            return _safeTransformRect(transform, rect)
        }

        // Transforming the 4 corners of a rectangle the straightforward way
        // incurs the cost of transforming 4 points using vector math which
        // involves 48 multiplications and 48 adds and then normalizing
        // the points using 4 inversions of the homogeneous weight factor
        // and then 12 multiplies. Once we have transformed all of the points
        // we then need to turn them into a bounding box using 4 min/max
        // operations each on 4 values yielding 12 total comparisons.
        //
        // On top of all of those operations, using the vector_math package to
        // do the work for us involves allocating several objects in order to
        // communicate the values back and forth - 4 allocating getters to extract
        // the [Offset] objects for the corners of the [Rect], 4 conversions to
        // a [Vector3] to use [Matrix4.perspectiveTransform()], and then 4 new
        // [Offset] objects allocated to hold those results, yielding 8 [Offset]
        // and 4 [Vector3] object allocations per rectangle transformed.
        //
        // But the math we really need to get our answer is actually much less
        // than that.
        //
        // First, consider that a full point transform using the vector math
        // package involves expanding it out into a vector3 with a Z coordinate
        // of 0.0 and then performing 3 multiplies and 3 adds per coordinate:
        //
        //     xt = x*m00 + y*m10 + z*m20 + m30;
        //     yt = x*m01 + y*m11 + z*m21 + m31;
        //     zt = x*m02 + y*m12 + z*m22 + m32;
        //     wt = x*m03 + y*m13 + z*m23 + m33;
        //
        // Immediately we see that we can get rid of the 3rd column of multiplies
        // since we know that Z=0.0. We can also get rid of the 3rd row because
        // we ignore the resulting Z coordinate. Finally we can get rid of the
        // last row if we don't have a perspective transform since we can verify
        // that the results are 1.0 for all points. This gets us down to 16
        // multiplies and 16 adds in the non-perspective case and 24 of each for
        // the perspective case. (Plus the 12 comparisons to turn them back into
        // a bounding box.)
        //
        // But we can do even better than that.
        //
        // Under optimal conditions of no perspective transformation,
        // which is actually a very common condition, we can transform
        // a rectangle in as little as 3 operations:
        //
        // (rx,ry) = transform of upper left corner of rectangle
        // (wx,wy) = delta transform of the (w, 0) width relative vector
        // (hx,hy) = delta transform of the (0, h) height relative vector
        //
        // A delta transform is a transform of all elements of the matrix except
        // for the translation components. The translation components are added
        // in at the end of each transform computation so they represent a
        // constant offset for each point transformed. A delta transform of
        // a horizontal or vertical vector involves a single multiplication due
        // to the fact that it only has one non-zero coordinate and no addition
        // of the translation component.
        //
        // In the absence of a perspective transform, the transformed
        // rectangle will be mapped into a parallelogram with corners at:
        // corner1 = (rx, ry)
        // corner2 = corner1 + dTransformed width vector = (rx+wx, ry+wy)
        // corner3 = corner1 + dTransformed height vector = (rx+hx, ry+hy)
        // corner4 = corner1 + both dTransformed vectors = (rx+wx+hx, ry+wy+hy)
        // In all, this method of transforming the rectangle requires only
        // 8 multiplies and 12 additions (which we can reduce to 8 additions if
        // we only need a bounding box, see below).
        //
        // In the presence of a perspective transform, the above conditions
        // continue to hold with respect to the non-normalized coordinates so
        // we can still save a lot of multiplications by computing the 4
        // non-normalized coordinates using relative additions before we normalize
        // them and they lose their "pseudo-parallelogram" relationships. We still
        // have to do the normalization divisions and min/max all 4 points to
        // get the resulting transformed bounding box, but we save a lot of
        // calculations over blindly transforming all 4 coordinates independently.
        // In all, we need 12 multiplies and 22 additions to construct the
        // non-normalized vectors and then 8 divisions (or 4 inversions and 8
        // multiplies) for normalization (plus the standard set of 12 comparisons
        // for the min/max bounds operations).
        //
        // Back to the non-perspective case, the optimization that lets us get
        // away with fewer additions if we only need a bounding box comes from
        // analyzing the impact of the relative vectors on expanding the
        // bounding box of the parallelogram. First, the bounding box always
        // contains the transformed upper-left corner of the rectangle. Next,
        // each relative vector either pushes on the left or right side of the
        // bounding box and also either the top or bottom side, depending on
        // whether it is positive or negative. Finally, you can consider the
        // impact of each vector on the bounding box independently. If, say,
        // wx and hx have the same sign, then the limiting point in the bounding
        // box will be the one that involves adding both of them to the origin
        // point. If they have opposite signs, then one will push one wall one
        // way and the other will push the opposite wall the other way and when
        // you combine both of them, the resulting "opposite corner" will
        // actually be between the limits they established by pushing the walls
        // away from each other, as below:
        //
        //             +---------(originx,originy)--------------+
        //             |            -----^----                  |
        //             |       -----          ----              |
        //             |  -----                   ----          |
        //     (+hx,+hy)<                             ----      |
        //             |  ----                            ----  |
        //             |      ----                             >(+wx,+wy)
        //             |          ----                   -----  |
        //             |              ----          -----       |
        //             |                  ---- -----            |
        //             |                      v                 |
        //             +---------------(+wx+hx,+wy+hy)----------+
        //
        // In this diagram, consider that:
        //
        //  * wx would be a positive number
        //  * hx would be a negative number
        //  * wy and hy would both be positive numbers
        //
        // As a result, wx pushes out the right wall, hx pushes out the left wall,
        // and both wy and hy push down the bottom wall of the bounding box. The
        // wx,hx pair (of opposite signs) worked on opposite walls and the final
        // opposite corner had an X coordinate between the limits they established.
        // The wy,hy pair (of the same sign) both worked together to push the
        // bottom wall down by their sum.
        //
        // This relationship allows us to simply start with the point computed by
        // transforming the upper left corner of the rectangle, and then
        // conditionally adding wx, wy, hx, and hy to either the left or top
        // or right or bottom of the bounding box independently depending on sign.
        // In that case we only need 4 comparisons and 4 additions total to
        // compute the bounding box, combined with the 8 multiplications and
        // 4 additions to compute the transformed point and relative vectors
        // for a total of 8 multiplies, 8 adds, and 4 comparisons.
        //
        // An astute observer will note that we do need to do 2 subtractions at
        // the top of the method to compute the width and height. Add those to
        // all of the relative solutions listed above. The test for perspective
        // also adds 3 compares to the affine case and up to 3 compares to the
        // perspective case (depending on which test fails, the rest are omitted).
        //
        // The final tally:
        // basic method          = 60 mul + 48 add + 12 compare
        // optimized perspective = 12 mul + 22 add + 15 compare + 2 sub
        // optimized affine      =  8 mul +  8 add +  7 compare + 2 sub
        //
        // Since compares are essentially subtractions and subtractions are
        // the same cost as adds, we end up with:
        // basic method          = 60 mul + 60 add/sub/compare
        // optimized perspective = 12 mul + 39 add/sub/compare
        // optimized affine      =  8 mul + 17 add/sub/compare
        let wx = transform[0, 0] * w
        let hx = transform[1, 0] * h
        let rx = transform[0, 0] * x + transform[1, 0] * y + transform[3, 0]

        let wy = transform[0, 1] * w
        let hy = transform[1, 1] * h
        let ry = transform[0, 1] * x + transform[1, 1] * y + transform[3, 1]

        if transform[0, 3] == 0.0 && transform[1, 3] == 0.0 && transform[3, 3] == 1.0 {
            var left = rx
            var right = rx
            if wx < 0 {
                left += wx
            } else {
                right += wx
            }
            if hx < 0 {
                left += hx
            } else {
                right += hx
            }

            var top = ry
            var bottom = ry
            if wy < 0 {
                top += wy
            } else {
                bottom += wy
            }
            if hy < 0 {
                top += hy
            } else {
                bottom += hy
            }

            return Rect(left: left, top: top, right: right, bottom: bottom)
        } else {
            let ww = transform[0, 3] * w
            let hw = transform[1, 3] * h
            let rw = transform[0, 3] * x + transform[1, 3] * y + transform[3, 3]

            let ulx = rx / rw
            let uly = ry / rw
            let urx = (rx + wx) / (rw + ww)
            let ury = (ry + wy) / (rw + ww)
            let llx = (rx + hx) / (rw + hw)
            let lly = (ry + hy) / (rw + hw)
            let lrx = (rx + wx + hx) / (rw + ww + hw)
            let lry = (ry + wy + hy) / (rw + ww + hw)

            return Rect(
                left: _min4(ulx, urx, llx, lrx),
                top: _min4(uly, ury, lly, lry),
                right: _max4(ulx, urx, llx, lrx),
                bottom: _max4(uly, ury, lly, lry)
            )
        }
    }

    static func _min4(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        let e = (a < b) ? a : b
        let f = (c < d) ? c : d
        return (e < f) ? e : f
    }

    static func _max4(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        let e = (a > b) ? a : b
        let f = (c > d) ? c : d
        return (e > f) ? e : f
    }

    /// Returns a rect that bounds the result of applying the inverse of the given
    /// matrix as a perspective transform to the given rect.
    ///
    /// This function assumes the given rect is in the plane with z equals 0.0.
    /// The transformed rect is then projected back into the plane with z equals
    /// 0.0 before computing its bounding rect.
    static func inverseTransformRect(_ transform: Matrix4x4f, _ rect: Rect) -> Rect {
        // As exposed by `unrelated_type_equality_checks`, this assert was a no-op.
        // Fixing it introduces a bunch of runtime failures; for more context see:
        // https://github.com/flutter/flutter/pull/31568
        // assert(transform.determinant != 0.0);
        if isIdentity(transform) {
            return rect
        }
        return transformRect(transform.inversed, rect)
    }

    // /// Create a transformation matrix which mimics the effects of tangentially
    // /// wrapping the plane on which this transform is applied around a cylinder
    // /// and then looking at the cylinder from a point outside the cylinder.
    // ///
    // /// The `radius` simulates the radius of the cylinder the plane is being
    // /// wrapped onto. If the transformation is applied to a 0-dimensional dot
    // /// instead of a plane, the dot would translate by ± `radius` pixels
    // /// along the `orientation` [Axis] when rotating from 0 to ±90 degrees.
    // ///
    // /// A positive radius means the object is closest at 0 `angle` and a negative
    // /// radius means the object is closest at π `angle` or 180 degrees.
    // ///
    // /// The `angle` argument is the difference in angle in radians between the
    // /// object and the viewing point. A positive `angle` on a positive `radius`
    // /// moves the object up when `orientation` is vertical and right when
    // /// horizontal.
    // ///
    // /// The transformation is always done such that a 0 `angle` keeps the
    // /// transformed object at exactly the same size as before regardless of
    // /// `radius` and `perspective` when `radius` is positive.
    // ///
    // /// The `perspective` argument is a number between 0 and 1 where 0 means
    // /// looking at the object from infinitely far with an infinitely narrow field
    // /// of view and 1 means looking at the object from infinitely close with an
    // /// infinitely wide field of view. Defaults to a sane but arbitrary 0.001.
    // ///
    // /// The `orientation` is the direction of the rotation axis.
    // ///
    // /// Because the viewing position is a point, it's never possible to see the
    // /// outer side of the cylinder at or past ±π/2 or 90 degrees and it's
    // /// almost always possible to end up seeing the inner side of the cylinder
    // /// or the back side of the transformed plane before π / 2 when perspective > 0.
    // static Matrix4 createCylindricalProjectionTransform({
    //   required double radius,
    //   required double angle,
    //   double perspective = 0.001,
    //   Axis orientation = Axis.vertical,
    // }) {
    //   assert(perspective >= 0 && perspective <= 1.0);

    //   // Pre-multiplied matrix of a projection matrix and a view matrix.
    //   //
    //   // Projection matrix is a simplified perspective matrix
    //   // http://web.iitd.ac.in/~hegde/cad/lecture/L9_persproj.pdf
    //   // in the form of
    //   // [[1.0, 0.0, 0.0, 0.0],
    //   //  [0.0, 1.0, 0.0, 0.0],
    //   //  [0.0, 0.0, 1.0, 0.0],
    //   //  [0.0, 0.0, -perspective, 1.0]]
    //   //
    //   // View matrix is a simplified camera view matrix.
    //   // Basically re-scales to keep object at original size at angle = 0 at
    //   // any radius in the form of
    //   // [[1.0, 0.0, 0.0, 0.0],
    //   //  [0.0, 1.0, 0.0, 0.0],
    //   //  [0.0, 0.0, 1.0, -radius],
    //   //  [0.0, 0.0, 0.0, 1.0]]
    //   Matrix4 result = Matrix4.identity()
    //       ..setEntry(3, 2, -perspective)
    //       ..setEntry(2, 3, -radius)
    //       ..setEntry(3, 3, perspective * radius + 1.0);

    //   // Model matrix by first translating the object from the origin of the world
    //   // by radius in the z axis and then rotating against the world.
    //   result = result * (switch (orientation) {
    //       Axis.horizontal => Matrix4.rotationY(angle),
    //       Axis.vertical   => Matrix4.rotationX(angle),
    //     } * Matrix4.translationValues(0.0, 0.0, radius)) as Matrix4;

    //   // Essentially perspective * view * model.
    //   return result;
    // }

    // /// Returns a matrix that transforms every point to [offset].
    // static Matrix4 forceToPoint(Offset offset) {
    //   return Matrix4.identity()
    //     ..setRow(0, Vector4(0, 0, 0, offset.dx))
    //     ..setRow(1, Vector4(0, 0, 0, offset.dy));
    // }
}

extension Matrix4x4f {

    /// Zeros this.
    public mutating func setZero() {
        self[0, 0] = 0.0
        self[0, 1] = 0.0
        self[0, 2] = 0.0
        self[0, 3] = 0.0
        self[1, 0] = 0.0
        self[1, 1] = 0.0
        self[1, 2] = 0.0
        self[1, 3] = 0.0
        self[2, 0] = 0.0
        self[2, 1] = 0.0
        self[2, 2] = 0.0
        self[2, 3] = 0.0
        self[3, 0] = 0.0
        self[3, 1] = 0.0
        self[3, 2] = 0.0
        self[3, 3] = 0.0
    }

    /// Rotate this [angle] radians around X
    public mutating func rotateX(_ angle: Angle) {
        let (sin:sinAngle, cos:cosAngle) = sincos(angle)

        let t1 = self[1, 0] * cosAngle + self[2, 0] * sinAngle
        let t2 = self[1, 1] * cosAngle + self[2, 1] * sinAngle
        let t3 = self[1, 2] * cosAngle + self[2, 2] * sinAngle
        let t4 = self[1, 3] * cosAngle + self[2, 3] * sinAngle
        let t5 = self[1, 0] * -sinAngle + self[2, 0] * cosAngle
        let t6 = self[1, 1] * -sinAngle + self[2, 1] * cosAngle
        let t7 = self[1, 2] * -sinAngle + self[2, 2] * cosAngle
        let t8 = self[1, 3] * -sinAngle + self[2, 3] * cosAngle
        self[1, 0] = t1
        self[1, 1] = t2
        self[1, 2] = t3
        self[1, 3] = t4
        self[2, 0] = t5
        self[2, 1] = t6
        self[2, 2] = t7
        self[2, 3] = t8
    }

    /// Rotate this matrix [angle] radians around Y
    public mutating func rotateY(_ angle: Angle) {
        let (sin:sinAngle, cos:cosAngle) = sincos(angle)

        let t1 = self[0, 0] * cosAngle + self[2, 0] * -sinAngle
        let t2 = self[0, 1] * cosAngle + self[2, 1] * -sinAngle
        let t3 = self[0, 2] * cosAngle + self[2, 2] * -sinAngle
        let t4 = self[0, 3] * cosAngle + self[2, 3] * -sinAngle
        let t5 = self[0, 0] * sinAngle + self[2, 0] * cosAngle
        let t6 = self[0, 1] * sinAngle + self[2, 1] * cosAngle
        let t7 = self[0, 2] * sinAngle + self[2, 2] * cosAngle
        let t8 = self[0, 3] * sinAngle + self[2, 3] * cosAngle
        self[0, 0] = t1
        self[0, 1] = t2
        self[0, 2] = t3
        self[0, 3] = t4
        self[2, 0] = t5
        self[2, 1] = t6
        self[2, 2] = t7
        self[2, 3] = t8
    }

    /// Rotate this matrix [angle] radians around Z
    public mutating func rotateZ(_ angle: Angle) {
        let (sin:sinAngle, cos:cosAngle) = sincos(angle)

        let t1 = self[0, 0] * cosAngle + self[1, 0] * sinAngle
        let t2 = self[0, 1] * cosAngle + self[1, 1] * sinAngle
        let t3 = self[0, 2] * cosAngle + self[1, 2] * sinAngle
        let t4 = self[0, 3] * cosAngle + self[1, 3] * sinAngle
        let t5 = self[0, 0] * -sinAngle + self[1, 0] * cosAngle
        let t6 = self[0, 1] * -sinAngle + self[1, 1] * cosAngle
        let t7 = self[0, 2] * -sinAngle + self[1, 2] * cosAngle
        let t8 = self[0, 3] * -sinAngle + self[1, 3] * cosAngle
        self[0, 0] = t1
        self[0, 1] = t2
        self[0, 2] = t3
        self[0, 3] = t4
        self[1, 0] = t5
        self[1, 1] = t6
        self[1, 2] = t7
        self[1, 3] = t8
    }

    /// Scale this matrix by x,y,z
    public mutating func scale(_ x: Float, _ y: Float? = nil, _ z: Float? = nil, _ w: Float? = nil)
    {
        let sx: Float = x
        let sy: Float = y ?? x
        let sz: Float = z ?? x
        let sw: Float = w ?? 1.0

        self[0, 0] *= sx
        self[0, 1] *= sx
        self[0, 2] *= sx
        self[0, 3] *= sx
        self[1, 0] *= sy
        self[1, 1] *= sy
        self[1, 2] *= sy
        self[1, 3] *= sy
        self[2, 0] *= sz
        self[2, 1] *= sz
        self[2, 2] *= sz
        self[2, 3] *= sz
        self[3, 0] *= sw
        self[3, 1] *= sw
        self[3, 2] *= sw
        self[3, 3] *= sw
    }

    /// Scale this matrix by a [Vector3]
    public mutating func scale(_ vector: Vector3f) {
        scale(vector.x, vector.y, vector.z)
    }

    /// Scale this matrix by a [Vector4]
    public mutating func scale(_ vector: Vector4f) {
        scale(vector.x, vector.y, vector.z, vector.w)
    }

    /// Rotate this [angle] radians around [axis]
    public mutating func rotate(_ axis: Vector3f, _ angle: Angle) {
        let len = axis.length
        let x = axis.x / len
        let y = axis.y / len
        let z = axis.z / len
        let c = cos(angle)
        let s = sin(angle)
        let C = 1.0 - c
        let m11 = x * x * C + c
        let m12 = x * y * C - z * s
        let m13 = x * z * C + y * s
        let m21 = y * x * C + z * s
        let m22 = y * y * C + c
        let m23 = y * z * C - x * s
        let m31 = z * x * C - y * s
        let m32 = z * y * C + x * s
        let m33 = z * z * C + c
        let t1 = self[0, 0] * m11 + self[1, 0] * m21 + self[2, 0] * m31
        let t2 = self[0, 1] * m11 + self[1, 1] * m21 + self[2, 1] * m31
        let t3 = self[0, 2] * m11 + self[1, 2] * m21 + self[2, 2] * m31
        let t4 = self[0, 3] * m11 + self[1, 3] * m21 + self[2, 3] * m31
        let t5 = self[0, 0] * m12 + self[1, 0] * m22 + self[2, 0] * m32
        let t6 = self[0, 1] * m12 + self[1, 1] * m22 + self[2, 1] * m32
        let t7 = self[0, 2] * m12 + self[1, 2] * m22 + self[2, 2] * m32
        let t8 = self[0, 3] * m12 + self[1, 3] * m22 + self[2, 3] * m32
        let t9 = self[0, 0] * m13 + self[1, 0] * m23 + self[2, 0] * m33
        let t10 = self[0, 1] * m13 + self[1, 1] * m23 + self[2, 1] * m33
        let t11 = self[0, 2] * m13 + self[1, 2] * m23 + self[2, 2] * m33
        let t12 = self[0, 3] * m13 + self[1, 3] * m23 + self[2, 3] * m33
        self[0, 0] = t1
        self[0, 1] = t2
        self[0, 2] = t3
        self[0, 3] = t4
        self[1, 0] = t5
        self[1, 1] = t6
        self[1, 2] = t7
        self[1, 3] = t8
        self[2, 0] = t9
        self[2, 1] = t10
        self[2, 2] = t11
        self[2, 3] = t12
    }

    /// Translate this matrix by x,y,z
    public mutating func translate(_ x: Float, _ y: Float = 0.0, _ z: Float = 0.0, _ w: Float = 1.0)
    {
        let tx = x
        let ty = y
        let tz = z
        let tw = w

        let t1 = self[0, 0] * tx + self[1, 0] * ty + self[2, 0] * tz + self[3, 0] * tw
        let t2 = self[0, 1] * tx + self[1, 1] * ty + self[2, 1] * tz + self[3, 1] * tw
        let t3 = self[0, 2] * tx + self[1, 2] * ty + self[2, 2] * tz + self[3, 2] * tw
        let t4 = self[0, 3] * tx + self[1, 3] * ty + self[2, 3] * tz + self[3, 3] * tw
        self[3, 0] = t1
        self[3, 1] = t2
        self[3, 2] = t3
        self[3, 3] = t4
    }

    /// Translate this matrix by a [Vector3]
    public mutating func translate(_ vector: Vector3f) {
        translate(vector.x, vector.y, vector.z)
    }

    /// Translate this matrix by a [Vector4]
    public mutating func translate(_ vector: Vector4f) {
        translate(vector.x, vector.y, vector.z, vector.w)
    }

    /// Removes the "perspective" component from `transform`.
    ///
    /// When applying the resulting transform matrix to a point with a
    /// z-coordinate of zero (which is generally assumed for all points
    /// represented by an [Offset]), the other coordinates will get transformed as
    /// before, but the new z-coordinate is going to be zero again. This is
    /// achieved by setting the third column and third row of the matrix to
    /// "0, 0, 1, 0".
    /// Removes the "perspective" component from `transform`.
    ///
    /// When applying the resulting transform matrix to a point with a
    /// z-coordinate of zero (which is generally assumed for all points
    /// represented by an [Offset]), the other coordinates will get transformed as
    /// before, but the new z-coordinate is going to be zero again. This is
    /// achieved by setting the third column and third row of the matrix to
    /// "0, 0, 1, 0".
    public func removePerspectiveTransform() -> Matrix4x4f {
        var result = self

        result[0, 2] = 0.0
        result[1, 2] = 0.0
        result[3, 2] = 0.0

        result[2, 0] = 0.0
        result[2, 1] = 0.0
        result[2, 3] = 0.0

        result[2, 2] = 1.0

        return result
    }

    public func multiplied(by other: Matrix4x4f) -> Matrix4x4f {
        return self * other
    }
}
