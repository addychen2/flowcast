import MapKit
import SwiftUI

extension MKMapView {
    func updateTrafficRenderer(for overlay: MKOverlay) -> MKOverlayRenderer {
        if let trafficOverlay = overlay as? TrafficOverlay {
            let renderer = MKPolylineRenderer(overlay: trafficOverlay)
            
            // Set color based on congestion level
            switch trafficOverlay.congestionLevel {
            case .low:
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.7)
            case .moderate:
                renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.7)
            case .heavy:
                renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.7)
            }
            
            renderer.lineWidth = 8
            renderer.lineCap = .round
            renderer.lineJoin = .round
            
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func updateVehicleAnnotationView(for annotation: MKAnnotation) -> MKAnnotationView? {
        guard let vehicleAnnotation = annotation as? VehicleAnnotation else { return nil }
        
        let identifier = "vehicle"
        var view = dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if view == nil {
            view = MKAnnotationView(annotation: vehicleAnnotation, reuseIdentifier: identifier)
            view?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        }
        
        // Create vehicle icon with updated design
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
        let vehicleImage = renderer.image { context in
            // Draw car shape with shadow
            let rect = CGRect(x: 2, y: 2, width: 20, height: 20)
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 1), blur: 2)
            
            // Background color based on congestion
            let backgroundColor: UIColor
            switch vehicleAnnotation.congestionLevel {
            case .low:
                backgroundColor = .systemGreen
            case .moderate:
                backgroundColor = .systemOrange
            case .heavy:
                backgroundColor = .systemRed
            }
            
            backgroundColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 5).fill()
            
            // Add white border
            context.cgContext.setShadow(offset: .zero, blur: 0)
            UIColor.white.setStroke()
            UIBezierPath(roundedRect: rect, cornerRadius: 5).stroke(with: .normal, alpha: 0.8)
            
            // Add direction indicator
            UIColor.white.setFill()
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: 12, y: 6))
            arrowPath.addLine(to: CGPoint(x: 18, y: 12))
            arrowPath.addLine(to: CGPoint(x: 12, y: 18))
            arrowPath.close()
            arrowPath.fill()
        }
        
        view?.image = vehicleImage
        view?.transform = CGAffineTransform(rotationAngle: CGFloat(vehicleAnnotation.direction) * .pi / 180)
        
        return view
    }
}
