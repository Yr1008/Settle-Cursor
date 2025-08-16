import SwiftUI
import PhotosUI
import CoreLocation
import AVKit
import UIKit

// MARK: - Haptics
enum Haptic {
    static let light = UIImpactFeedbackGenerator(style: .light)
    static let soft  = UIImpactFeedbackGenerator(style: .soft)
    static let note  = UINotificationFeedbackGenerator()
    static func tap() { light.impactOccurred() }
    static func pop() { soft.impactOccurred() }
    static func success() { note.notificationOccurred(.success) }
}

// MARK: - Distance / Time helpers
private func kmBetween(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let R = 6371.0
    let dLat = (b.latitude - a.latitude) * .pi/180
    let dLon = (b.longitude - a.longitude) * .pi/180
    let lat1 = a.latitude * .pi/180, lat2 = b.latitude * .pi/180
    let x = sin(dLat/2)*sin(dLat/2) + cos(lat1)*cos(lat2)*sin(dLon/2)*sin(dLon/2)
    return 2*R*asin(sqrt(x))
}
private func hoursFromNow(to end: Date) -> Int {
    max(0, Int(ceil(end.timeIntervalSinceNow/3600)))
}

// MARK: - Models (Equatable/Hashable by id for stable ForEach)
struct Author: Identifiable, Hashable, Equatable {
    var id = UUID()
    var username: String          // show without @
    var avatar: String
    var verified: Bool = false
    var location: String
    var followers: Int = 0
    var interests: Set<String> = []
}
enum PollKind: String, Codable { case image, text, video }

struct PollOption: Identifiable, Hashable, Equatable {
    var id = UUID()
    var label: String
    var imageURL: String? = nil
}

struct Poll: Identifiable, Hashable, Equatable {
    static func ==(l: Poll, r: Poll) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    var id = UUID()
    var kind: PollKind
    var author: Author
    var title: String
    var tags: [String]
    var locationName: String
    var coords: CLLocationCoordinate2D?
    var createdAt: Date = .init()
    var endsAt: Date
    var options: [PollOption]
    var votes: [UUID:Int] = [:]         // optionID -> count
    var myChoice: UUID? = nil           // one vote per user (local demo)
    var promoted: Bool = false
}

// MARK: - Location manager
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coords: CLLocationCoordinate2D = .init(latitude: 40.7128, longitude: -74.0060) // NYC default
    private let manager = CLLocationManager()
    func request() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        if let c = locs.last?.coordinate { DispatchQueue.main.async { self.coords = c } }
    }
}

// MARK: - Demo user & seed
private var me = Author(
    username: "jordan",
    avatar: "https://i.pravatar.cc/100?img=12",
    verified: true,
    location: "New York City",
    followers: 2304,
    interests: ["food","fashion","tech","fitness","movies"]
)

private func seedPolls() -> [Poll] {
    let now = Date()
    func opt(_ label: String, _ url: String) -> PollOption { .init(label: label, imageURL: url) }

    let a = Author(username: "aria.codes", avatar:"https://i.pravatar.cc/100?img=14", verified: false, location:"Lower East Side", followers: 980, interests:["fashion","tech"])
    let m = Author(username: "mayamakes", avatar:"https://i.pravatar.cc/100?img=32", verified: true, location:"Williamsburg", followers: 5400, interests:["food"])
    let d = Author(username: "devvibes", avatar:"https://i.pravatar.cc/100?img=25", verified: false, location:"Brooklyn Heights", followers: 2100, interests:["tech"])
    let s = Author(username: "sara.moves", avatar:"https://i.pravatar.cc/100?img=5", verified: false, location:"Bushwick", followers: 1200, interests:["fitness"])

    var list: [Poll] = [
        Poll(kind:.image, author:a, title:"Everyday sneakers?", tags:["fashion"], locationName:a.location, coords:.init(latitude:40.715, longitude:-73.984), createdAt: now.addingTimeInterval(-60*60*5), endsAt: now.addingTimeInterval(60*60*2), options:[
            opt("Nike Air",   "https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=1200&auto=format&fit=crop"),
            opt("Adidas Stan Smith","https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=1200&auto=format&fit=crop")
        ], votes:[ : ], myChoice:nil),
        Poll(kind:.image, author:m, title:"Dinner date tonight?", tags:["food"], locationName:m.location, coords:.init(latitude:40.7081, longitude:-73.9571), createdAt: now.addingTimeInterval(-60*35), endsAt: now.addingTimeInterval(60*60), options:[
            opt("Sushi","https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=1200&auto=format&fit=crop"),
            opt("Tacos","https://images.unsplash.com/photo-1601924582971-b0c5be3bb2a1?q=80&w=1200&auto=format&fit=crop")
        ], votes:[ : ], myChoice:nil),
        Poll(kind:.image, author:s, title:"Leg day finisher?", tags:["fitness"], locationName:s.location, coords:.init(latitude:40.6943, longitude:-73.9213), createdAt: now.addingTimeInterval(-60*200), endsAt: now.addingTimeInterval(60*60*3), options:[
            opt("Sled pushes","https://images.unsplash.com/photo-1517832606299-7ae9b720a186?q=80&w=1200&auto=format&fit=crop"),
            opt("Walking lunges","https://images.unsplash.com/photo-1571388208497-71bedc66e932?q=80&w=1200&auto=format&fit=crop")
        ], votes:[ : ], myChoice:nil),
        Poll(kind:.image, author:d, title:"iPad for notes — Mini or Air?", tags:["tech"], locationName:d.location, coords:.init(latitude:40.6959, longitude:-73.9955), createdAt: now.addingTimeInterval(-60*90), endsAt: now.addingTimeInterval(60*60*6), options:[
            opt("iPad mini (8.3)","https://images.unsplash.com/photo-1546074177-ffdda98d214a?q=80&w=1200&auto=format&fit=crop"),
            opt("iPad Air (11)","https://images.unsplash.com/photo-1593642532400-2682810df593?q=80&w=1200&auto=format&fit=crop")
        ], votes:[ : ], myChoice:nil),
    ]

    // add more to reach ~20 for scrolling demo
    let extraImages = [
        ("Best Sunday brunch?", "food","https://images.unsplash.com/photo-1551218808-94e220e084d2?q=80&w=1200&auto=format&fit=crop","https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?q=80&w=1200&auto=format&fit=crop"),
        ("Movie night vibe?", "movies","https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=1200&auto=format&fit=crop","https://images.unsplash.com/photo-1517602302552-471fe67acf66?q=80&w=1200&auto=format&fit=crop"),
        ("Campus coffee?", "food","https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=1200&auto=format&fit=crop","https://images.unsplash.com/photo-1445077100181-a33e9ac94db0?q=80&w=1200&auto=format&fit=crop")
    ]
    for (i, e) in extraImages.enumerated() {
        list.append(
            Poll(kind:.image, author:a, title:e.0, tags:[e.1], locationName:"SoHo", coords:.init(latitude:40.7233, longitude:-74.0030), createdAt: now.addingTimeInterval(-60*Double(30 + i*10)), endsAt: now.addingTimeInterval(60*60*Double(5+i)), options:[
                opt("A", e.2), opt("B", e.3)
            ], votes:[ : ], myChoice:nil)
        )
    }
    return list
}

// MARK: - Ranking (interest ▸ social ▸ location ▸ recency)
private func score(_ p: Poll, me: Author, here: CLLocationCoordinate2D, tab: FeedTab) -> Double {
    let interest = p.tags.contains(where: me.interests.contains) ? 1.0 : 0.0
    let social = min(1.0, Double(p.author.followers)/5000.0)
    let recencyHours = max(0.0, -p.createdAt.timeIntervalSinceNow/3600.0)
    let recency = max(0, 1 - recencyHours/24)      // 0..1
    let prox: Double = {
        guard let c = p.coords else { return 0.2 }
        let km = kmBetween(here, c)
        return max(0, 1 - min(km, 24)/24)          // ~15 miles focus
    }()

    switch tab {
    case .forYou: return interest*0.45 + social*0.15 + prox*0.15 + recency*0.25
    case .nearby: return prox*0.60 + recency*0.30 + interest*0.10
    case .global: return recency*0.60 + interest*0.25 + social*0.15
    }
}

enum FeedTab: String, CaseIterable, Identifiable { case forYou = "For You", nearby = "Nearby", global = "Global"; var id: String { rawValue } }

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var locMan = LocationManager()
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isDark") private var isDark = false

    @State private var activeTab: FeedTab = .forYou
    @State private var polls: [Poll] = seedPolls()
    @State private var query: String = ""
    @State private var showProfile = false
    @State private var showCreate = false
    @State private var showSearch = false
    @State private var sharingItem: Any?

    // Sorting + filtering
    private var ranked: [Poll] {
        let here = locMan.coords
        return polls
            .filter { q in query.isEmpty ? true : (q.title.lowercased().contains(query.lowercased()) || q.tags.joined().contains(query.lowercased())) }
            .sorted { a, b in score(a, me: me, here: here, tab: activeTab) > score(b, me: me, here: here, tab: activeTab) }
    }

    var body: some View {
        ZStack {
            (isDark ? Color.black : Color(UIColor.systemGroupedBackground)).ignoresSafeArea()

            ScrollViewReader { proxy in
                List {
                    Section {
                        header
                        tabs
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    ForEach(ranked) { p in
                        PollCard(poll: binding(for: p), onShare: { item in
                            sharingItem = item
                        })
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .id(p.id)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    // lightweight "new content" shuffle to mimic feed refresh
                    polls.shuffle()
                }
            }

            bottomBar
        }
        .sheet(isPresented: $showProfile) { ProfileSheet(isDark: $isDark) }
        .sheet(isPresented: $showCreate) { ComposeSheet { newPoll in
            polls.insert(newPoll, at: 0)
        }}
        .sheet(isPresented: $showSearch) { SearchSheet(polls: polls) }
        .sheet(item: Binding(get: {
            sharingItem.map { ShareItem(id: UUID(), item: $0) }
        }, set: { _ in sharingItem = nil })) { item in
            ActivityView(activityItems: [item.item])
        }
        .onAppear { locMan.request() }
        .onReceive(locMan.$coords) { _ in /* react to location if needed */ }
        .preferredColorScheme(isDark ? .dark : .light)
    }

    private func binding(for poll: Poll) -> Binding<Poll> {
        guard let idx = polls.firstIndex(of: poll) else { return .constant(poll) }
        return $polls[idx]
    }

    // MARK: Header & Tabs
    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Settle").font(.system(size: 32, weight: .black, design: .rounded))
                    if me.verified { Image(systemName: "checkmark.seal.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.black).padding(4).background(.white).clipShape(Circle()) }
                }
                Text("@\(me.username)").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showProfile = true } label: {
                AsyncImage(url: URL(string: me.avatar)) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.gray.opacity(0.25) }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var tabs: some View {
        HStack(spacing: 10) {
            ForEach(FeedTab.allCases) { t in
                Button {
                    Haptic.pop()
                    activeTab = t
                } label: {
                    Text(t.rawValue)
                        .font(.footnote.bold())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule().fill(activeTab == t ? Color.black : Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(activeTab == t ? 0.15 : 0.05), radius: activeTab == t ? 10 : 6, y: 4)
                        )
                        .foregroundStyle(activeTab == t ? .white : .primary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: Bottom bar
    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                Button {
                    Haptic.tap()
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 58, height: 58)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
                }
                Spacer()
                Button { showProfile = true } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12) // sits above home indicator
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Poll Card
struct PollCard: View {
    @Binding var poll: Poll
    var onShare: (Any) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var showMenu = false
    @State private var showBurst = false
    @State private var isZooming = false
    @State private var mute = true

    private var totalVotes: Int { max(0, poll.votes.values.reduce(0,+)) }
    private func pct(_ id: UUID) -> Int {
        let t = max(1, totalVotes)
        let c = poll.votes[id, default: 0]
        return Int(round(Double(c) * 100 / Double(t)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .center, spacing: 10) {
                AsyncImage(url: URL(string: poll.author.avatar)) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.gray.opacity(0.25) }
                .frame(width: 34, height: 34)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(poll.author.username).font(.subheadline.weight(.semibold))
                        if poll.author.verified {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(.white).padding(2).background(Color.black, in: Circle())
                        }
                    }
                    Text(poll.locationName).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()
                Text("Ends in \(hoursFromNow(to: poll.endsAt))h")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.15), in: Capsule())

                Menu {
                    Button("Share") { onShare(URL(string: "https://settle.app/p/\(poll.id.uuidString)")!) }
                    Button("Report", role: .destructive) { }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Title
            Text(poll.title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 8)

            // Options (image layout – fully rounded, no overlap)
            if poll.kind == .image {
                GeometryReader { geo in
                    let spacing: CGFloat = 12
                    let width = (geo.size.width - spacing) / 2
                    HStack(spacing: spacing) {
                        ForEach(poll.options) { opt in
                            optionImage(opt, width: width)
                        }
                    }
                    .frame(width: geo.size.width, height: width * 4/5, alignment: .center)
                }
                .frame(height: 220)
                .padding(8)
            }
            // Footer
            HStack {
                Text("\(totalVotes) \(totalVotes == 1 ? "vote" : "votes")").font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Button("Undo") {
                    if let c = poll.myChoice, let cur = poll.votes[c], cur > 0 {
                        poll.votes[c] = cur - 1
                        poll.myChoice = nil
                        Haptic.tap()
                    }
                }
                .font(.footnote)
                .disabled(poll.myChoice == nil)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    // single image cell
    @ViewBuilder
    private func optionImage(_ opt: PollOption, width: CGFloat) -> some View {
        let chosen = poll.myChoice == opt.id
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: opt.imageURL ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: width, height: width * 4/5)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if poll.kind == .video {
                    Image(systemName: mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
            }
            .overlay(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.5),
                    .init(color: .black.opacity(0.45), location: 1.0)
                ], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )

            HStack {
                Text(opt.label).font(.headline).foregroundStyle(.white).shadow(radius: 6)
                Spacer()
                Text("\(pct(opt.id))%")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(10)
        }
        .frame(width: width, height: width * 4/5)
        .contentShape(Rectangle())
        .scaleEffect(isZooming && chosen ? 1.02 : 1.0)
        .gesture(LongPressGesture(minimumDuration: 0.15).onChanged { _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isZooming = true }
        }.onEnded { _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isZooming = false }
        })
        .highPriorityGesture(TapGesture(count: 2).onEnded { vote(opt.id) })
    }

    private func vote(_ optionID: UUID) {
        guard poll.myChoice == nil else { return } // one vote per poll
        poll.votes[optionID] = (poll.votes[optionID] ?? 0) + 1
        poll.myChoice = optionID
        Haptic.success()
    }
}

// MARK: - Compose (PhotosPicker)
struct ComposeSheet: View {
    var onCreate: (Poll) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var tag = "food"
    @State private var itemA: PhotosPickerItem?
    @State private var itemB: PhotosPickerItem?
    @State private var imgA: UIImage?
    @State private var imgB: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section("Ask the crowd") {
                    TextField("What's your question?", text: $title)
                    Picker("Tag", selection: $tag) {
                        ForEach(["food","fashion","tech","fitness","movies"], id:\.self) { Text($0) }
                    }
                }
                Section("Options") {
                    PhotosPicker("Choose A", selection: $itemA, matching: .images)
                    PhotosPicker("Choose B", selection: $itemB, matching: .images)
                    if let imgA { Image(uiImage: imgA).resizable().scaledToFill().frame(height:120).clipped().cornerRadius(12) }
                    if let imgB { Image(uiImage: imgB).resizable().scaledToFill().frame(height:120).clipped().cornerRadius(12) }
                }
            }
            .navigationTitle("New Poll")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        guard let a = imgA?.jpegData(compressionQuality: 0.8),
                              let b = imgB?.jpegData(compressionQuality: 0.8),
                              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        else { return }
                        // For demo: write temp files and use file URLs
                        let urlA = writeTemp(a, name: "a.jpg")
                        let urlB = writeTemp(b, name: "b.jpg")
                        let poll = Poll(
                            kind: .image,
                            author: me,
                            title: title,
                            tags: [tag],
                            locationName: me.location,
                            coords: nil,
                            createdAt: .init(),
                            endsAt: Date().addingTimeInterval(60*60*24),
                            options: [
                                .init(label: "Option A", imageURL: urlA.absoluteString),
                                .init(label: "Option B", imageURL: urlB.absoluteString)
                            ],
                            votes: [:],
                            myChoice: nil
                        )
                        onCreate(poll)
                        dismiss()
                    }
                }
            }
            .task(id: itemA) { imgA = await loadImage(itemA) }
            .task(id: itemB) { imgB = await loadImage(itemB) }
        }
    }

    private func writeTemp(_ data: Data, name: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + name)
        try? data.write(to: url)
        return url
    }
    private func loadImage(_ item: PhotosPickerItem?) async -> UIImage? {
        guard let item else { return nil }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) { return img }
        return nil
    }
}

// MARK: - Profile
struct ProfileSheet: View {
    @Binding var isDark: Bool
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AsyncImage(url: URL(string: me.avatar)) { $0.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.25) }
                            .frame(width: 56, height: 56).clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text("@\(me.username)").font(.headline)
                            Text(me.location).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if me.verified { Image(systemName: "checkmark.circle.fill").foregroundStyle(.white).padding(6).background(Color.black, in: Circle()) }
                    }
                }
                Section("Preferences") {
                    Toggle("Dark Mode", isOn: $isDark)
                    NavigationLink("Account") { Text("Account settings (stub)") }
                    NavigationLink("Safety & Reporting") { Text("Report history (stub)") }
                }
                Section("About") {
                    Link("Terms", destination: URL(string:"https://example.com")!)
                    Link("Privacy", destination: URL(string:"https://example.com")!)
                }
            }
            .navigationTitle("Profile & Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

// MARK: - Search (simple explore + timeframe filter)
struct SearchSheet: View {
    var polls: [Poll]
    @Environment(\.dismiss) private var dismiss
    @State private var timeframe = 7 // days

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Sort", selection: $timeframe) {
                    Text("Last 7 days").tag(7)
                    Text("Last month").tag(30)
                    Text("This year").tag(365)
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    ForEach(filteredTop) { p in
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: p.options.first?.imageURL ?? "")) { $0.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                                .frame(width: 64, height: 64).clipped().cornerRadius(10)
                            VStack(alignment:.leading) {
                                Text(p.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                                Text("@\(p.author.username) · \(p.locationName)").font(.caption).foregroundStyle(.secondary)
                                Text("\(p.votes.values.reduce(0,+)) votes").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }.listStyle(.plain)
            }
            .navigationTitle("Search")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
    private var filteredTop: [Poll] {
        let cutoff = Date().addingTimeInterval(-Double(timeframe)*24*3600)
        return polls
            .filter { $0.createdAt >= cutoff }
            .sorted { $0.votes.values.reduce(0,+) > $1.votes.values.reduce(0,+) }
    }
}

// MARK: - Share sheet wrapper
struct ShareItem: Identifiable { let id: UUID; let item: Any }
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}