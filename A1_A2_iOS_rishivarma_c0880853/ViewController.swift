//
//  ViewController.swift
//  A1_A2_iOS_rishivarma_c0880853
//
//  Created by RISHI VARMA on 2023-01-20.
//

import UIKit
import MapKit
import CoreLocation
import Foundation

class ViewController : UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var btnDirection : UIButton!
    @IBOutlet weak var txtSearch : UITextField!
    @IBOutlet weak var btnSearch : UIButton!
    @IBOutlet weak var btnZoomIn : UIButton!
    @IBOutlet weak var btnZoomOut : UIButton!
    
    var locationManager = CLLocationManager()
    var distanceLabels : [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.delegate = self
        mapView.isZoomEnabled = false
        doubleTap()
    }
    
    @IBAction func mapZoomIn(_ sender : UIButton) {
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(center: currentRegion.center, span: MKCoordinateSpan(latitudeDelta: currentRegion.span.latitudeDelta/2, longitudeDelta: currentRegion.span.longitudeDelta/2))
        mapView.setRegion(newRegion, animated: true)
    }

    @IBAction func mapZoomOut(_ sender : UIButton) {
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(center: currentRegion.center, span: MKCoordinateSpan(latitudeDelta: currentRegion.span.latitudeDelta*2, longitudeDelta: currentRegion.span.longitudeDelta*2))
        mapView.setRegion(newRegion, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        displayLocation(latitude: latitude, longitude: longitude)
    }
    
    func displayLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees){
        let latitudedelta: CLLocationDegrees = 0.05
        let longitudedelta: CLLocationDegrees = 0.05
        let span = MKCoordinateSpan(latitudeDelta: latitudedelta, longitudeDelta: longitudedelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func doubleTap(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        tapGesture.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer){
        if sender.state == .ended {
            let touchPoint = sender.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            if mapView.annotations.count == 4 && sender.numberOfTapsRequired == 2 {
                mapView.removeAnnotations(mapView.annotations)
                mapView.removeOverlays(mapView.overlays)
                remoteDistanceLabel()
                let annotationPlace = Place(coordinate: coordinate, title: "A")
                mapView.addAnnotation(annotationPlace)
            } else if sender.numberOfTapsRequired == 2 {
                var title : String = ""
                switch mapView.annotations.count {
                case 1:
                    title = "A"
                case 2:
                    title = "B"
                case 3:
                    title = "C"
                default:
                    break
                }
                let annotationPlace = Place(coordinate: coordinate, title: title)
                mapView.addAnnotation(annotationPlace)
            }
        }
        addPolygon()
    }

    func addPolygon() {
        var myAnnotations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for place in mapView.annotations{
            if place.title == "My Location" {
                continue
            }
            myAnnotations.append(place.coordinate)
        }
        let polygon = MKPolygon(coordinates: myAnnotations, count: myAnnotations.count)
        mapView.addOverlay(polygon)
    }

    func addPolyline() {
        btnDirection.isHidden = false
        var myAnnotations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for mapAnnotation in mapView.annotations {
            myAnnotations.append(mapAnnotation.coordinate)
        }
        myAnnotations.append(myAnnotations[0])
        let polyline = MKPolyline(coordinates: myAnnotations, count: myAnnotations.count)
        mapView.addOverlay(polyline, level: .aboveRoads)
    }

    @IBAction func btnSearchOnClick(_ sender : UIButton) {
        let address = txtSearch.text!
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = address
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start { [self] (response, error) in
            if error == nil {
                let coordinates = response?.boundingRegion.center
                let lat = coordinates?.latitude
                let lon = coordinates?.longitude
                let location = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
                self.displayLocation(latitude: lat!, longitude: lon!)
                let annotationPlace = Place(coordinate: location, title: "")
                if mapView.annotations.count == 4 {
                    mapView.removeAnnotations(mapView.annotations)
                    mapView.removeOverlays(mapView.overlays)
                    annotationPlace.title = "A"
                    mapView.addAnnotation(annotationPlace)
                }
                switch self.mapView.annotations.count {
                case 1:
                    annotationPlace.title = "A"
                case 2:
                    annotationPlace.title = "B"
                case 3:
                    annotationPlace.title = "C"
                default:
                    break
                }
                self.mapView.addAnnotation(annotationPlace)
                addPolygon()
            } else {
                print(error?.localizedDescription ?? "Error")
            }
        }
    }
    
    @IBAction func btnDirectionOnClick(_ sender : UIButton) {
        mapView.removeOverlays(mapView.overlays)
        remoteDistanceLabel()
        var nextIndex = 0
        for index in 0 ... 2 {
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }
            let source = MKPlacemark(coordinate: mapView.annotations[index].coordinate)
            let destination = MKPlacemark(coordinate: mapView.annotations[nextIndex].coordinate)
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: source)
            directionRequest.destination = MKMapItem(placemark: destination)
            directionRequest.transportType = .automobile
            let directions = MKDirections(request: directionRequest)
            directions.calculate(completionHandler: { (response, error) in
                guard let directionResponse = response else {
                    return
                }
                
                let route = directionResponse.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                
                let rect = route.polyline.boundingMapRect
                self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            })
        }
        showDistanceBetweenTwoPoint()
    }

    func removeOverlays() {
        btnDirection.isHidden = true
        remoteDistanceLabel()
        for polygon in mapView.overlays {
            mapView.removeOverlay(polygon)
        }
    }
    
    private func remoteDistanceLabel() {
        for label in distanceLabels {
            label.removeFromSuperview()
        }
        distanceLabels = []
    }
    private func showDistanceBetweenTwoPoint() {
        var nextIndex = 0
        for index in 0...2{
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }
            let distance: Double = getDistance(from: mapView.annotations[index].coordinate, to:  mapView.annotations[nextIndex].coordinate)
            let pointA: CGPoint = mapView.convert(mapView.annotations[index].coordinate, toPointTo: mapView)
            let pointB: CGPoint = mapView.convert(mapView.annotations[nextIndex].coordinate, toPointTo: mapView)
            let labelDistance = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 18))
            labelDistance.textAlignment = NSTextAlignment.center
            labelDistance.text = "\(String.init(format: "%2.f",  round(distance * 0.001))) km"
            labelDistance.center = CGPoint(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
            labelDistance.textColor = UIColor.blue
            distanceLabels.append(labelDistance)
        }
        for label in distanceLabels {
            mapView.addSubview(label)
        }
    }
    
    func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 2.0
            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = .red.withAlphaComponent(0.5)
            renderer.strokeColor = .green
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Place else { return nil }
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
          as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        if let currentLocation = locationManager.location {
            let distance = currentLocation.distance(from: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))
            let distanceinkms = round(distance * 0.001)
            view.detailCalloutAccessoryView = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            (view.detailCalloutAccessoryView as! UILabel).text = "\(distanceinkms) kms away from your location"
        }
        return view
    }
}

class Place : NSObject, MKAnnotation {
    
    var title: String?
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }
    
}

