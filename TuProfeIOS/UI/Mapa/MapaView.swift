import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Location manager helper

class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? = nil

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        // Publish cached location immediately so the map loads at current position
        if let cached = manager.location {
            userLocation = cached.coordinate
        }
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { self.userLocation = locations.last?.coordinate }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
}

// MARK: - MapaView (matches Android MapaScreen)

struct MapaView: View {
    @StateObject private var viewModel = MapaViewModel()
    @StateObject private var locationManager = MapLocationManager()
    @EnvironmentObject var navState: NavigationState

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var hasSetInitialLocation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Map ──────────────────────────────────────────────────────────
            Map(coordinateRegion: $region, annotationItems: viewModel.clusters) { cluster in
                MapAnnotation(coordinate: cluster.coordinate) {
                    if cluster.isCluster {
                        ClusterBadge(cluster: cluster) {
                            viewModel.selectCluster(cluster)
                        }
                    } else if let marker = cluster.markers.first {
                        ReviewMapPin(marker: marker) {
                            viewModel.selectMarker(marker)
                            withAnimation(.easeInOut(duration: 0.5)) {
                                region.center = CLLocationCoordinate2D(
                                    latitude: marker.latitude,
                                    longitude: marker.longitude
                                )
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture { viewModel.selectedMarker = nil }
            .onChange(of: region.center.latitude)  { _ in viewModel.updateRegion(region) }
            .onChange(of: region.center.longitude) { _ in viewModel.updateRegion(region) }
            .onChange(of: region.span.latitudeDelta) { _ in viewModel.updateRegion(region) }

            // ── Overlay controls ─────────────────────────────────────────────
            VStack(spacing: 0) {
                TuProfeTopBarView()

                HStack(alignment: .top) {
                    // Top-left: review count chip + expandable list
                    VStack(alignment: .leading, spacing: 6) {
                        ReviewCountChip(viewModel: viewModel)

                        if viewModel.showReviewList && !viewModel.markers.isEmpty {
                            ReviewListDropdown(
                                markers: viewModel.markers,
                                userLocation: locationManager.userLocation,
                                onItemClick: { marker in
                                    viewModel.showReviewList = false
                                    viewModel.selectMarker(marker)
                                    withAnimation(.easeInOut(duration: 0.6)) {
                                        region.center = CLLocationCoordinate2D(
                                            latitude: marker.latitude,
                                            longitude: marker.longitude
                                        )
                                        region.span = MKCoordinateSpan(
                                            latitudeDelta: 0.01,
                                            longitudeDelta: 0.01
                                        )
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.showReviewList)

                    Spacer()

                    // Top-right: Refresh button
                    Button(action: {
                        viewModel.loadMarkers()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.pastel)
                                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            )
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }

                Spacer()

                // Bottom-right: Zoom + My location + Filter buttons
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // Zoom in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                region.span = MKCoordinateSpan(
                                    latitudeDelta: max(region.span.latitudeDelta / 2, 0.002),
                                    longitudeDelta: max(region.span.longitudeDelta / 2, 0.002)
                                )
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(Color.pastel)
                                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                                )
                        }

                        // Zoom out
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                region.span = MKCoordinateSpan(
                                    latitudeDelta: min(region.span.latitudeDelta * 2, 60),
                                    longitudeDelta: min(region.span.longitudeDelta * 2, 60)
                                )
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(Color.pastel)
                                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                                )
                        }

                        // My location button
                        Button(action: {
                            locationManager.requestLocation()
                            if let loc = locationManager.userLocation {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    region = MKCoordinateRegion(
                                        center: loc,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(Color.verdetp)
                                        .shadow(radius: 6)
                                )
                        }

                        // Filter button
                        Button(action: { viewModel.showFilterPanel.toggle() }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(viewModel.hasActiveFilters ? Color.verdetp2 : Color.verdetp)
                                        .shadow(radius: 6)
                                )
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }

            // ── Loading ──────────────────────────────────────────────────────
            if viewModel.isLoading {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }

            // ── Selected marker detail card ──────────────────────────────────
            if let marker = viewModel.selectedMarker {
                MapDetailCard(
                    marker: marker,
                    onDismiss: { viewModel.selectedMarker = nil },
                    onViewReview: {
                        navState.navigate(to: .detalle(reviewId: marker.reviewId))
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 40)
            }

            // ── Cluster detail card ───────────────────────────────────────────
            if let cluster = viewModel.selectedCluster {
                ClusterDetailCard(
                    cluster: cluster,
                    onDismiss: { viewModel.selectedCluster = nil },
                    onViewReview: { reviewId in
                        navState.navigate(to: .detalle(reviewId: reviewId))
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedMarker?.id)
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedCluster?.id)
        .onAppear {
            viewModel.loadMarkers()
            locationManager.requestLocation()
        }
        .onReceive(locationManager.$userLocation) { loc in
            guard let loc, !hasSetInitialLocation else { return }
            hasSetInitialLocation = true
            region = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
        .sheet(isPresented: $viewModel.showFilterPanel) {
            MapFilterPanel(viewModel: viewModel)
        }
    }
}

// MARK: - Review count chip (matches Android review count surface chip)

private struct ReviewCountChip: View {
    @ObservedObject var viewModel: MapaViewModel

    var body: some View {
        Button(action: { viewModel.toggleReviewList() }) {
            HStack(spacing: 4) {
                Group {
                    if viewModel.hasActiveFilters {
                        Text("\(viewModel.markers.count) de \(viewModel.allMarkers.count) reseñas")
                    } else {
                        Text("\(viewModel.markers.count) reseñas hoy")
                    }
                }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.showReviewList ? .white : .verdetp)
                Image(systemName: viewModel.showReviewList ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(viewModel.showReviewList ? .white : .verdetp)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(viewModel.showReviewList ? Color.verdetp : Color.pastel)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Expandable review list (matches Android ReviewListDropdown)

private struct ReviewListDropdown: View {
    let markers: [ReviewMapMarker]
    let userLocation: CLLocationCoordinate2D?
    let onItemClick: (ReviewMapMarker) -> Void

    private var sortedMarkers: [ReviewMapMarker] {
        guard let loc = userLocation else { return markers }
        return markers.sorted { a, b in
            let da = CLLocation(latitude: a.latitude, longitude: a.longitude)
                .distance(from: CLLocation(latitude: loc.latitude, longitude: loc.longitude))
            let db = CLLocation(latitude: b.latitude, longitude: b.longitude)
                .distance(from: CLLocation(latitude: loc.latitude, longitude: loc.longitude))
            return da < db
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(sortedMarkers.enumerated()), id: \.element.id) { i, marker in
                    Button(action: { onItemClick(marker) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(marker.profesorNombre)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                if !marker.materia.isEmpty {
                                    Text(marker.materia)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                if let loc = userLocation {
                                    let dist = CLLocation(latitude: marker.latitude, longitude: marker.longitude)
                                        .distance(from: CLLocation(latitude: loc.latitude, longitude: loc.longitude))
                                    Text(formatDistance(dist))
                                        .font(.system(size: 11))
                                        .foregroundColor(.verdetp)
                                }
                            }
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "FFB300"))
                                Text("\(marker.rating)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if i < sortedMarkers.count - 1 {
                        Divider().padding(.horizontal, 8)
                    }
                }
            }
        }
        .frame(width: 230, height: min(CGFloat(sortedMarkers.count) * 56, 260))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pastel)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}

// MARK: - Map pin annotation (matches Android marker colors)

struct ReviewMapPin: View {
    let marker: ReviewMapMarker
    let onTap: () -> Void

    var pinColor: Color {
        switch marker.rating {
        case 5: return Color(hex: "1AC06A")
        case 4: return Color(hex: "4BE086")
        case 3: return Color(hex: "FFC107")
        case 2: return Color(hex: "FF9800")
        default: return Color(hex: "F44336")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(pinColor)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 4)

                    if let url = marker.profesorFotoUrl, !url.isEmpty {
                        ProfileImageView(url: url, size: 34, borderWidth: 2, borderColor: .white)
                    } else {
                        Text("\(marker.rating)★")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Triangle()
                    .fill(pinColor)
                    .frame(width: 12, height: 6)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Map detail card (matches Android MarkerInfoCard)

struct MapDetailCard: View {
    let marker: ReviewMapMarker
    let onDismiss: () -> Void
    let onViewReview: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            HStack(spacing: 14) {
                ProfileImageView(url: marker.profesorFotoUrl, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(marker.profesorNombre)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)

                    if !marker.materia.isEmpty {
                        Text(marker.materia)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        StarRatingView(rating: Double(marker.rating), starSize: 14)
                        Text(String(format: "%.1f", Double(marker.rating)))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.secondary.opacity(0.12)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Button(action: onViewReview) {
                HStack(spacing: 6) {
                    Text("Ver reseña completa")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.verdetp)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: -4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Cluster detail card with horizontal scroll pager

struct ClusterDetailCard: View {
    let cluster: MapCluster
    let onDismiss: () -> Void
    let onViewReview: (String) -> Void

    @State private var currentPage = 0

    private var currentMarker: ReviewMapMarker? {
        guard currentPage < cluster.markers.count else { return nil }
        return cluster.markers[currentPage]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle + close
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 4)

                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.secondary.opacity(0.12)))
                    }
                    .padding(.trailing, 20)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Swipeable pages
            TabView(selection: $currentPage) {
                ForEach(Array(cluster.markers.enumerated()), id: \.element.id) { index, marker in
                    HStack(spacing: 14) {
                        ProfileImageView(url: marker.profesorFotoUrl, size: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(marker.profesorNombre)
                                .font(.system(size: 16, weight: .bold))
                                .lineLimit(1)

                            if !marker.materia.isEmpty {
                                Text(marker.materia)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            HStack(spacing: 4) {
                                StarRatingView(rating: Double(marker.rating), starSize: 14)
                                Text(String(format: "%.1f", Double(marker.rating)))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 72)

            // X/Y indicator
            Text("\(currentPage + 1)/\(cluster.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.vertical, 8)

            // Button for current page
            if let marker = currentMarker {
                Button(action: { onViewReview(marker.reviewId) }) {
                    HStack(spacing: 6) {
                        Text("Ver reseña completa")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.verdetp)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: 20)
        }
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: -4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Filter panel (matches Android FilterBottomSheet)

struct MapFilterPanel: View {
    @ObservedObject var viewModel: MapaViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Rating filter chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calificación")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                FilterChipView(
                                    label: "\(star) ★",
                                    isSelected: viewModel.filterStars.contains(star)
                                ) {
                                    viewModel.toggleStarFilter(star)
                                }
                            }
                        }
                    }

                    // Professor filter chips
                    if !viewModel.allProfesores.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profesor")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.allProfesores, id: \.self) { nombre in
                                    FilterChipView(
                                        label: nombre,
                                        isSelected: viewModel.filterProfesores.contains(nombre)
                                    ) {
                                        viewModel.toggleProfesorFilter(nombre)
                                    }
                                }
                            }
                        }
                    }

                    // Materia filter chips
                    if !viewModel.allMaterias.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Materia")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.allMaterias, id: \.self) { materia in
                                    FilterChipView(
                                        label: materia,
                                        isSelected: viewModel.filterMaterias.contains(materia)
                                    ) {
                                        viewModel.toggleMateriaFilter(materia)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Filtrar marcadores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") { viewModel.clearFilters() }
                        .foregroundColor(.red)
                        .opacity(viewModel.hasActiveFilters ? 1 : 0.4)
                        .disabled(!viewModel.hasActiveFilters)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") { dismiss() }
                        .foregroundColor(.verdetp)
                }
            }
        }
    }
}

// MARK: - Filter chip view

private struct FilterChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.verdetp : Color.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow layout for chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Cluster badge annotation

struct ClusterBadge: View {
    let cluster: MapCluster
    let onTap: () -> Void

    private var color: Color {
        let avg = cluster.averageRating
        if avg >= 4.5 { return Color(hex: "1AC06A") }
        if avg >= 3.5 { return Color(hex: "4BE086") }
        if avg >= 2.5 { return Color(hex: "FFC107") }
        if avg >= 1.5 { return Color(hex: "FF9800") }
        return Color(hex: "F44336")
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.28))
                    .frame(width: 52, height: 52)
                Circle()
                    .fill(color)
                    .frame(width: 38, height: 38)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                Text("\(cluster.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cluster model

struct MapCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let markers: [ReviewMapMarker]

    var isCluster: Bool { markers.count > 1 }
    var count: Int { markers.count }
    var averageRating: Double {
        guard !markers.isEmpty else { return 0 }
        return Double(markers.map { $0.rating }.reduce(0, +)) / Double(markers.count)
    }
}

// MARK: - MapaViewModel

@MainActor
class MapaViewModel: ObservableObject {
    @Published var markers: [ReviewMapMarker] = []
    @Published var allMarkers: [ReviewMapMarker] = []
    @Published var clusters: [MapCluster] = []
    @Published var selectedMarker: ReviewMapMarker? = nil
    @Published var selectedCluster: MapCluster? = nil
    @Published var isLoading = false
    @Published var showFilterPanel = false
    @Published var showReviewList = false
    @Published var filterStars: Set<Int> = []
    @Published var filterProfesores: Set<String> = []
    @Published var filterMaterias: Set<String> = []

    private var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    private var clusterTask: Task<Void, Never>?

    var allProfesores: [String] {
        Array(Set(allMarkers.map { $0.profesorNombre })).sorted()
    }

    var allMaterias: [String] {
        Array(Set(allMarkers.map { $0.materia }.filter { !$0.isEmpty })).sorted()
    }

    var hasActiveFilters: Bool {
        !filterStars.isEmpty || !filterProfesores.isEmpty || !filterMaterias.isEmpty
    }

    private let reviewRepo = ReviewRepository.shared
    private var moderationObserver: NSObjectProtocol?

    init() {
        moderationObserver = NotificationCenter.default.addObserver(
            forName: .moderationUpdated, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyFilters()
        }
    }

    func loadMarkers() {
        isLoading = true
        Task {
            do {
                let all = try await reviewRepo.getMapMarkers()
                allMarkers = all.applyModerationFilter()
                applyFilters()
            } catch {
                print("Error cargando marcadores: \(error)")
            }
            isLoading = false
        }
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        currentRegion = region
        clusterTask?.cancel()
        clusterTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled, let self else { return }
            self.buildClusters()
        }
    }

    private func buildClusters() {
        guard !markers.isEmpty else { clusters = []; return }
        let region = currentRegion
        let gridCols = 7.0
        let latCell = region.span.latitudeDelta / gridCols
        let lngCell = region.span.longitudeDelta / gridCols
        guard latCell > 0, lngCell > 0 else {
            clusters = markers.map {
                MapCluster(id: $0.id,
                           coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                           markers: [$0])
            }
            return
        }
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let minLng = region.center.longitude - region.span.longitudeDelta / 2

        var grid: [String: [ReviewMapMarker]] = [:]
        for marker in markers {
            let r = Int(floor((marker.latitude - minLat) / latCell))
            let c = Int(floor((marker.longitude - minLng) / lngCell))
            let key = "\(r)_\(c)"
            grid[key, default: []].append(marker)
        }

        clusters = grid.map { key, ms in
            let lat = ms.map { $0.latitude }.reduce(0, +) / Double(ms.count)
            let lng = ms.map { $0.longitude }.reduce(0, +) / Double(ms.count)
            return MapCluster(
                id: key,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                markers: ms
            )
        }
    }

    func selectMarker(_ marker: ReviewMapMarker) {
        selectedMarker = marker
        selectedCluster = nil
    }

    func selectCluster(_ cluster: MapCluster) {
        selectedCluster = cluster
        selectedMarker = nil
    }

    func toggleReviewList() {
        showReviewList.toggle()
    }

    func toggleStarFilter(_ star: Int) {
        if filterStars.contains(star) { filterStars.remove(star) }
        else { filterStars.insert(star) }
        applyFilters()
    }

    func toggleProfesorFilter(_ nombre: String) {
        if filterProfesores.contains(nombre) { filterProfesores.remove(nombre) }
        else { filterProfesores.insert(nombre) }
        applyFilters()
    }

    func toggleMateriaFilter(_ materia: String) {
        if filterMaterias.contains(materia) { filterMaterias.remove(materia) }
        else { filterMaterias.insert(materia) }
        applyFilters()
    }

    func clearFilters() {
        filterStars = []
        filterProfesores = []
        filterMaterias = []
        applyFilters()
    }

    private func applyFilters() {
        var result = allMarkers.applyModerationFilter()
        if !filterStars.isEmpty {
            result = result.filter { filterStars.contains($0.rating) }
        }
        if !filterProfesores.isEmpty {
            result = result.filter { filterProfesores.contains($0.profesorNombre) }
        }
        if !filterMaterias.isEmpty {
            result = result.filter { filterMaterias.contains($0.materia) }
        }
        markers = result
        buildClusters()
    }
}