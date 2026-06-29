import SwiftUI

func chartPlotDimension(_ value: CGFloat) -> CGFloat {
    guard value.isFinite, value > 1, value < 10_000 else { return 1 }
    return value
}

func chartPlotCoordinate(_ value: CGFloat) -> CGFloat {
    guard value.isFinite, abs(value) < 10_000 else { return 0 }
    return value
}
