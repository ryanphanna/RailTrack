import SwiftUI
import MapKit
import CoreLocation

struct LiveExploreMapView: View {
    let amtrakTrains: [AmtrakLiveDataService.AmtrakTrain]
    let viaTrains: [String: VIALiveDataService.VIALiveTrain]
    let goTrains: [String: GOLiveDataService.GOLiveTrain]
    
    @Binding var selectedPrepopulatedTrip: PrepopulatedTrip?
    @Binding var position: MapCameraPosition
    @Binding var selectedTrain: SelectedTrainInfo?
    
    var body: some View {
        Map(position: $position) {
            ForEach(amtrakTrains, id: \.trainID) { train in
                if let lat = train.lat, let lon = train.lon {
                    Annotation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        Button {
                            selectAmtrakTrain(train)
                        } label: {
                            TrainPositionMarker(operatorColor: ColorTheme.amtrak, trainNumber: train.trainNum)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            ForEach(Array(viaTrains.keys), id: \.self) { key in
                if let train = viaTrains[key], let lat = train.lat, let lon = train.lng {
                    let trainNum = key.split(separator: " ").first.map(String.init) ?? key
                    Annotation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        Button {
                            selectViaTrain(number: trainNum, train: train)
                        } label: {
                            TrainPositionMarker(operatorColor: ColorTheme.via, trainNumber: trainNum)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            ForEach(Array(goTrains.keys), id: \.self) { key in
                if let train = goTrains[key], let lat = train.lat, let lon = train.lng {
                    let trainNum = key.split(separator: " ").first.map(String.init) ?? key
                    Annotation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        Button {
                            selectGoTrain(number: trainNum, train: train)
                        } label: {
                            TrainPositionMarker(operatorColor: ColorTheme.go, trainNumber: trainNum)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
    
    private func selectAmtrakTrain(_ train: AmtrakLiveDataService.AmtrakTrain) {
        let first = train.stations.first
        let last = train.stations.last
        let originCode = first?.code ?? ""
        let destCode = last?.code ?? ""
        
        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.name ?? "Origin"
        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.name ?? "Destination"
        
        var delay = 0
        if let lastStop = train.stations.last(where: { $0.status == "Departed" || $0.status == "Station" }),
           let arrStr = lastStop.arr, let schArrStr = lastStop.schArr,
           let arrDate = AmtrakLiveDataService.shared.parseISO8601Date(arrStr),
           let schArrDate = AmtrakLiveDataService.shared.parseISO8601Date(schArrStr) {
            delay = max(0, Int(arrDate.timeIntervalSince(schArrDate) / 60))
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTrain = SelectedTrainInfo(
                trainNumber: train.trainNum,
                operatorName: "Amtrak",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.velocity.map(Int.init),
                delayMinutes: delay,
                lat: train.lat ?? 0,
                lon: train.lon ?? 0
            )
            
            if let lat = train.lat, let lon = train.lon {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 100_000,
                    longitudinalMeters: 100_000
                ))
            }
        }
    }
    
    private func selectViaTrain(number: String, train: VIALiveDataService.VIALiveTrain) {
        let first = train.times.first
        let last = train.times.last
        let originCode = first?.code ?? ""
        let destCode = last?.code ?? ""
        
        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.station ?? "Origin"
        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.station ?? "Destination"
        
        var delay = 0
        if let lastStopWithDiff = train.times.last(where: { $0.diffMin != nil }) {
            delay = max(0, lastStopWithDiff.diffMin ?? 0)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTrain = SelectedTrainInfo(
                trainNumber: number,
                operatorName: "VIA",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.speed,
                delayMinutes: delay,
                lat: train.lat ?? 0,
                lon: train.lng ?? 0
            )
            
            if let lat = train.lat, let lon = train.lng {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 100_000,
                    longitudinalMeters: 100_000
                ))
            }
        }
    }
    
    private func selectGoTrain(number: String, train: GOLiveDataService.GOLiveTrain) {
        let first = train.times.first
        let last = train.times.last
        let originCode = first?.code ?? ""
        let destCode = last?.code ?? ""
        
        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.station ?? "Origin"
        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.station ?? "Destination"
        
        var delay = 0
        if let lastStopWithDiff = train.times.last(where: { $0.diffMin != nil }) {
            delay = max(0, lastStopWithDiff.diffMin ?? 0)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTrain = SelectedTrainInfo(
                trainNumber: number,
                operatorName: "GO",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.speed,
                delayMinutes: delay,
                lat: train.lat ?? 0,
                lon: train.lng ?? 0
            )
            
            if let lat = train.lat, let lon = train.lng {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 100_000,
                    longitudinalMeters: 100_000
                ))
            }
        }
    }
}
