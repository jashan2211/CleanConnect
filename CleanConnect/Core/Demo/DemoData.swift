import Foundation
import CoreLocation

/// Sample content for `-demo` launches (App Store screenshots and previews). Never shown otherwise.
enum DemoData {
    static let home = CLLocationCoordinate2D(latitude: 12.9719, longitude: 77.6412)
    static let homePlace = Place(locality: "Indiranagar", city: "Bengaluru", state: "Karnataka")

    static let me = profile("me", "Riya Malhotra", points: 1240, week: 185, reports: 27, cleanups: 18, bags: 64,
                            hosted: 2, joined: 6, verifications: 11, streak: 12, best: 21,
                            upi: "riya.cleans@okicici", bio: "Weekend plogger. Ulsoor Lake regular. Let's make Bengaluru shine ✨")

    static let profiles: [Profile] = [
        profile("p1", "Arjun Nair", points: 3420, week: 310, reports: 41, cleanups: 52, bags: 230, hosted: 6, joined: 14, verifications: 30, streak: 33, best: 40, upi: "arjun.n@okaxis", bio: "Cleaning one footpath at a time."),
        profile("p2", "Fatima Khan", points: 2980, week: 265, reports: 35, cleanups: 44, bags: 176, hosted: 4, joined: 9, verifications: 22, streak: 9, best: 18),
        profile("p3", "Gurpreet Singh", points: 2310, week: 240, reports: 22, cleanups: 37, bags: 150, hosted: 3, joined: 11, verifications: 14, streak: 15, best: 15),
        me,
        profile("p4", "Ananya Iyer", points: 1105, week: 150, reports: 30, cleanups: 12, bags: 40, hosted: 1, joined: 5, verifications: 9, streak: 4, best: 10),
        profile("p5", "Rohan Mehta", points: 960, week: 120, reports: 18, cleanups: 11, bags: 38, hosted: 0, joined: 7, verifications: 6, streak: 2, best: 8),
        profile("p6", "Kavya Reddy", points: 720, week: 95, reports: 12, cleanups: 9, bags: 30, hosted: 1, joined: 3, verifications: 4, streak: 6, best: 6),
        profile("p7", "Vikram Rao", points: 540, week: 80, reports: 15, cleanups: 5, bags: 18, hosted: 0, joined: 4, verifications: 3, streak: 1, best: 5),
        profile("p8", "Sneha Patil", points: 410, week: 60, reports: 9, cleanups: 4, bags: 14, hosted: 0, joined: 2, verifications: 2, streak: 3, best: 3),
        profile("p9", "Aditya Joshi", points: 260, week: 45, reports: 6, cleanups: 3, bags: 9, hosted: 0, joined: 1, verifications: 1, streak: 0, best: 2),
    ]

    static let spots: [Spot] = [
        spot("s1", .cleaned, .mixed, .cart, "Ulsoor Lake Road", 12.9810, 77.6200, before: "demo_before_1", after: "demo_after_1",
             reporter: profiles[4], cleaner: me, bags: 9, crew: 4, respect: 128, verified: 14, hoursAgo: 3,
             note: "Overflowing pile next to the bus stop for weeks.", cleanupNote: "4 of us, 9 bags, 90 minutes. Bus stop is spotless now!"),
        spot("s2", .cleaned, .plastic, .bag, "Bellandur Lake", 12.9352, 77.6686, before: "demo_before_2", after: "demo_after_2",
             reporter: profiles[1], cleaner: profiles[0], bags: 14, crew: 6, respect: 342, verified: 31, hoursAgo: 20,
             note: "Plastic bottles all along the lake edge.", cleanupNote: "Morning plog with the HSR crew 💪"),
        spot("s3", .cleaned, .construction, .truck, "Koramangala 5th Block", 12.9352, 77.6245, before: "demo_before_3", after: "demo_after_3",
             reporter: profiles[5], cleaner: profiles[2], bags: 22, crew: 9, respect: 211, verified: 19, hoursAgo: 40,
             note: "Debris dumped on the footpath.", cleanupNote: "Got the ward office to send a tractor for the heavy stuff."),
        spot("s4", .open, .mixed, .cart, "100 Feet Road, Indiranagar", 12.9784, 77.6408, before: "demo_before_4", after: nil,
             reporter: me, cleaner: nil, bags: 0, crew: 1, respect: 12, verified: 0, hoursAgo: 5, stillThere: 9,
             note: "Garbage piling up behind the metro pillar 52."),
        spot("s5", .claimed, .plastic, .bag, "Domlur Flyover", 12.9609, 77.6387, before: "demo_before_5", after: nil,
             reporter: profiles[6], cleaner: nil, bags: 0, crew: 1, respect: 6, verified: 0, hoursAgo: 9, stillThere: 4,
             note: "Plastic and wrappers under the flyover.", claimer: profiles[4]),
        spot("s6", .open, .drain, .cart, "HAL 2nd Stage", 12.9690, 77.6480, before: "demo_before_6", after: nil,
             reporter: profiles[7], cleaner: nil, bags: 0, crew: 1, respect: 3, verified: 0, hoursAgo: 26, stillThere: 6,
             note: "Drain blocked with plastic, water overflowing onto the road."),
        spot("s7", .open, .walls, .bag, "CMH Road", 12.9786, 77.6390, before: "demo_before_7", after: nil,
             reporter: profiles[8], cleaner: nil, bags: 0, crew: 1, respect: 2, verified: 0, hoursAgo: 50, stillThere: 2,
             note: "Paan stains all over the underpass wall. Needs a paint job!"),
        spot("s8", .open, .burning, .bag, "Old Airport Road", 12.9590, 77.6560, before: "demo_before_8", after: nil,
             reporter: profiles[5], cleaner: nil, bags: 0, crew: 1, respect: 4, verified: 0, hoursAgo: 70, stillThere: 3,
             note: "Someone keeps burning garbage here every evening."),
        spot("s9", .cleaned, .water, .cart, "Ulsoor Lake", 12.9830, 77.6210, before: "demo_before_9", after: "demo_after_9",
             reporter: profiles[0], cleaner: profiles[3], bags: 11, crew: 5, respect: 97, verified: 8, hoursAgo: 80,
             note: "Thermocol and plastic floating near the steps.", cleanupNote: "Lake steps clean again 🌊"),
    ]

    static let drives: [Drive] = [
        drive("d1", "Ulsoor Lake Sunday Plog", hoursFromNow: 46, organizer: profiles[0], address: "Ulsoor Lake main gate",
              lat: 12.9822, lng: 77.6195, attendees: 38, capacity: 60, cover: "demo_cover_1",
              about: "Join us for 2 hours of plogging around the lake. Gloves and bags provided — just bring water and energy! Kids welcome with parents."),
        drive("d2", "Clean Up 100 Feet Road", hoursFromNow: 120, organizer: me, address: "Indiranagar Metro Station",
              lat: 12.9784, lng: 77.6408, attendees: 17, capacity: 30, cover: "demo_cover_2",
              about: "Let's clear the garbage pile behind metro pillar 52 and paint the wall after."),
        drive("d3", "Bellandur Lake Shore Drive", hoursFromNow: 200, organizer: profiles[1], address: "Bellandur Lake, Kariyammana Agrahara",
              lat: 12.9352, lng: 77.6686, attendees: 52, capacity: 100, cover: "demo_cover_3",
              about: "Monthly lake shore cleanup with residents' welfare associations. Breakfast after!"),
    ]

    static let attendees: [Attendee] = profiles.map { Attendee(uid: $0.id, name: $0.name, photoURL: nil) }

    static let comments: [Comment] = [
        Comment(id: "c1", authorId: "p1", authorName: "Arjun Nair", authorPhoto: nil, text: "Amazing work! This bus stop was a mess for months 🙌", createdAt: .now.addingTimeInterval(-7200)),
        Comment(id: "c2", authorId: "p2", authorName: "Fatima Khan", authorPhoto: nil, text: "Walked past this morning — verified, it's spotless.", createdAt: .now.addingTimeInterval(-3600)),
        Comment(id: "c3", authorId: "p5", authorName: "Rohan Mehta", authorPhoto: nil, text: "Count me in for the next one!", createdAt: .now.addingTimeInterval(-1200)),
    ]

    static let indiaStats = ImpactStats(reported: 48_210, cleaned: 31_465, bags: 212_380, drives: 2_940, volunteers: 86_300)
    static let cityStats = ImpactStats(reported: 3_412, cleaned: 2_587, bags: 17_904, drives: 214, volunteers: 6_820)

    // MARK: Builders

    private static func profile(_ id: String, _ name: String, points: Int, week: Int, reports: Int, cleanups: Int, bags: Int,
                                hosted: Int, joined: Int, verifications: Int, streak: Int, best: Int,
                                upi: String? = nil, bio: String = "") -> Profile {
        Profile(id: id, name: name, photoURL: nil, bio: bio, city: "Bengaluru", state: "Karnataka", upiId: upi,
                supportURL: nil, instagram: nil, points: points, weekKey: WeekKey.current, weekPoints: week,
                reports: reports, cleanups: cleanups, bags: bags, drivesHosted: hosted, drivesJoined: joined,
                verifications: verifications, streak: streak, bestStreak: best, lastActiveDay: DayKey.today,
                createdAt: .now.addingTimeInterval(-90 * 86_400))
    }

    private static func spot(_ id: String, _ status: SpotStatus, _ category: SpotCategory, _ size: SpotSize,
                             _ locality: String, _ lat: Double, _ lng: Double, before: String, after: String?,
                             reporter: Profile, cleaner: Profile?, bags: Int, crew: Int, respect: Int, verified: Int,
                             hoursAgo: Double, stillThere: Int = 0, note: String, cleanupNote: String? = nil,
                             claimer: Profile? = nil) -> Spot {
        let created = Date.now.addingTimeInterval(-hoursAgo * 3600 - 86_400)
        return Spot(id: id, reporterId: reporter.id, reporterName: reporter.name, reporterPhoto: nil, status: status,
                    category: category, size: size, note: note, lat: lat, lng: lng, locality: locality, city: "Bengaluru",
                    state: "Karnataka", beforePhotos: ["demo:\(before)"], afterPhotos: after.map { ["demo:\($0)"] } ?? [],
                    claimedBy: claimer?.id, claimedByName: claimer?.name, claimedAt: claimer == nil ? nil : created,
                    cleanedBy: cleaner?.id, cleanedByName: cleaner?.name, cleanedByPhoto: nil,
                    cleanedAt: cleaner == nil ? nil : Date.now.addingTimeInterval(-hoursAgo * 3600),
                    cleanupNote: cleanupNote, bags: bags, crew: crew, respectCount: respect, stillThereCount: stillThere,
                    verifiedCount: verified, commentCount: cleaner == nil ? 2 : 3, hidden: false, createdAt: created, driveId: nil)
    }

    private static func drive(_ id: String, _ title: String, hoursFromNow: Double, organizer: Profile, address: String,
                              lat: Double, lng: Double, attendees: Int, capacity: Int, cover: String, about: String) -> Drive {
        let start = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0,
                                          of: .now.addingTimeInterval(hoursFromNow * 3600)) ?? .now
        return Drive(id: id, organizerId: organizer.id, organizerName: organizer.name, organizerPhoto: nil, title: title,
                     about: about, startsAt: start, durationMinutes: 120, lat: lat, lng: lng, address: address,
                     city: "Bengaluru", state: "Karnataka", spotId: nil, coverURL: "demo:\(cover)",
                     bring: [.water, .cap, .shoes], providing: [.gloves, .bags, .snacks], capacity: capacity,
                     attendeeCount: attendees, upiId: organizer.upiId, whatsappLink: "https://chat.whatsapp.com/demo",
                     status: .upcoming, resultBags: 0, resultPhotos: [], commentCount: 3, hidden: false, createdAt: .now)
    }
}
