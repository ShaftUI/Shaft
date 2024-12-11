// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

struct _Vector {
    init(size: Int) {
        _offset = 0
        _length = size
        _elements = [Double](repeating: 0, count: size)
    }

    init(values: [Double], offset: Int, length: Int) {
        _offset = offset
        _length = length
        _elements = values
    }

    let _offset: Int
    let _length: Int
    var _elements: [Double]

    subscript(i: Int) -> Double {
        get {
            return _elements[i + _offset]
        }
        set(value) {
            _elements[i + _offset] = value
        }
    }

    static func * (lhs: _Vector, rhs: _Vector) -> Double {
        var result = 0.0
        for i in 0..<lhs._length {
            result += lhs[i] * rhs[i]
        }
        return result
    }

    func norm() -> Double {
        return (self * self).squareRoot()
    }
}
struct _Matrix {
    init(rows: Int, cols: Int) {
        _columns = cols
        _elements = [Double](repeating: 0, count: rows * cols)
    }

    let _columns: Int
    var _elements: [Double]

    func get(row: Int, col: Int) -> Double {
        return _elements[row * _columns + col]
    }

    mutating func set(row: Int, col: Int, value: Double) {
        _elements[row * _columns + col] = value
    }

    func getRow(_ row: Int) -> _Vector {
        return _Vector(
            values: _elements,
            offset: row * _columns,
            length: _columns
        )
    }
}

/// An nth degree polynomial fit to a dataset.
struct PolynomialFit {
    /// Creates a polynomial fit of the given degree.
    ///
    /// There are n + 1 coefficients in a fit of degree n.
    init(degree: Int) {
        coefficients = [Double](repeating: 0, count: degree + 1)
    }

    /// The polynomial coefficients of the fit.
    ///
    /// For each `i`, the element `coefficients[i]` is the coefficient of
    /// the `i`-th power of the variable.
    var coefficients: [Double]

    /// An indicator of the quality of the fit.
    ///
    /// Larger values indicate greater quality.  The value ranges from 0.0 to 1.0.
    ///
    /// The confidence is defined as the fraction of the dataset's variance
    /// that is captured by variance in the fit polynomial.  In statistics
    /// textbooks this is often called "r-squared".
    var confidence: Double!
}

extension PolynomialFit: CustomStringConvertible {
    var description: String {
        let coefficientString = coefficients.map { String(format: "%.3f", $0) }.description
        return
            "\(type(of: self))(\(coefficientString), confidence: \(String(format: "%.3f", confidence)))"
    }
}

/// Uses the least-squares algorithm to fit a polynomial to a set of data.
struct LeastSquaresSolver {
    /// Creates a least-squares solver.
    init(x: [Double], y: [Double], w: [Double]) {
        assert(x.count == y.count)
        assert(y.count == w.count)
        self.x = x
        self.y = y
        self.w = w
    }

    /// The x-coordinates of each data point.
    let x: [Double]

    /// The y-coordinates of each data point.
    let y: [Double]

    /// The weight to use for each data point.
    let w: [Double]

    /// Fits a polynomial of the given degree to the data points.
    ///
    /// When there is not enough data to fit a curve nil is returned.
    func solve(degree: Int) -> PolynomialFit? {
        if degree > x.count {
            // Not enough data to fit a curve.
            return nil
        }

        var result = PolynomialFit(degree: degree)

        // Shorthands for the purpose of notation equivalence to original C++ code.
        let m = x.count
        let n = degree + 1

        // Expand the X vector to a matrix A, pre-multiplied by the weights.
        var a = _Matrix(rows: n, cols: m)
        for h in 0..<m {
            a.set(row: 0, col: h, value: w[h])
            for i in 1..<n {
                a.set(row: i, col: h, value: a.get(row: i - 1, col: h) * x[h])
            }
        }

        // Apply the Gram-Schmidt process to A to obtain its QR decomposition.

        // Orthonormal basis, column-major ordVectorer.
        var q = _Matrix(rows: n, cols: m)
        // Upper triangular matrix, row-major order.
        var r = _Matrix(rows: n, cols: n)
        for j in 0..<n {
            for h in 0..<m {
                q.set(row: j, col: h, value: a.get(row: j, col: h))
            }
            for i in 0..<j {
                let dot = q.getRow(j) * q.getRow(i)
                for h in 0..<m {
                    q.set(
                        row: j,
                        col: h,
                        value: q.get(row: j, col: h) - dot * q.get(row: i, col: h)
                    )
                }
            }

            let norm = q.getRow(j).norm()
            if norm < Double(precisionErrorTolerance) {
                // Vectors are linearly dependent or zero so no solution.
                return nil
            }

            let inverseNorm = 1.0 / norm
            for h in 0..<m {
                q.set(row: j, col: h, value: q.get(row: j, col: h) * inverseNorm)
            }
            for i in 0..<n {
                r.set(row: j, col: i, value: i < j ? 0.0 : q.getRow(j) * a.getRow(i))
            }
        }

        // Solve R B = Qt W Y to find B. This is easy because R is upper triangular.
        // We just work from bottom-right to top-left calculating B's coefficients.
        var wy = _Vector(size: m)
        for h in 0..<m {
            wy[h] = y[h] * w[h]
        }
        for i in (0..<n).reversed() {
            result.coefficients[i] = q.getRow(i) * wy
            for j in (i + 1..<n).reversed() {
                result.coefficients[i] -= r.get(row: i, col: j) * result.coefficients[j]
            }
            result.coefficients[i] /= r.get(row: i, col: i)
        }

        // Calculate the coefficient of determination (confidence) as:
        //   1 - (sumSquaredError / sumSquaredTotal)
        // ...where sumSquaredError is the residual sum of squares (variance of the
        // error), and sumSquaredTotal is the total sum of squares (variance of the
        // data) where each has been weighted.
        var yMean = 0.0
        for h in 0..<m {
            yMean += y[h]
        }
        yMean /= Double(m)

        var sumSquaredError = 0.0
        var sumSquaredTotal = 0.0
        for h in 0..<m {
            var term = 1.0
            var err = y[h] - result.coefficients[0]
            for i in 1..<n {
                term *= x[h]
                err -= term * result.coefficients[i]
            }
            sumSquaredError += w[h] * w[h] * err * err
            let v = y[h] - yMean
            sumSquaredTotal += w[h] * w[h] * v * v
        }

        result.confidence =
            sumSquaredTotal <= Double(precisionErrorTolerance)
            ? 1.0 : 1.0 - (sumSquaredError / sumSquaredTotal)

        return result
    }
}
