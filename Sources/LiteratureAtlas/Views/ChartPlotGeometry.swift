import SwiftUI

func sanitizedGeometrySize(_ size: CGSize) -> CGSize {
    func dimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite, value > 0, value < 10_000 else { return 0 }
        return value
    }

    return CGSize(width: dimension(size.width), height: dimension(size.height))
}

func chartPlotDimension(_ value: CGFloat) -> CGFloat {
    guard value.isFinite, value > 1, value < 10_000 else { return 1 }
    return value
}

func chartPlotCoordinate(_ value: CGFloat) -> CGFloat {
    guard value.isFinite, abs(value) < 10_000 else { return 0 }
    return value
}

func graphLayoutRadius(size: CGSize, padding: CGFloat) -> CGFloat {
    guard size.width.isFinite, size.height.isFinite, padding.isFinite else { return 0 }
    return max(0, min(size.width, size.height) / 2 - max(0, padding))
}
