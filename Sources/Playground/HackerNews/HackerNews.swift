import Foundation
import Observation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct HackerNewsItem: Codable {
    let id: Int
    let title: String
    let url: String?
    let score: Int
    let by: String
    let time: Int
    let descendants: Int?
    let kids: [Int]?
    let type: String
    let text: String?
    let dead: Bool?
    let deleted: Bool?
}

struct HackerNews {
    func getTopStories() async throws -> [Int] {
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!
        )
        return try JSONDecoder().decode([Int].self, from: data)
    }

    func getItem(id: Int) async throws -> HackerNewsItem {
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
        )
        return try JSONDecoder().decode(HackerNewsItem.self, from: data)
    }
}

@Observable
class HackerNewsService {
    init() {
        Task {
            await refresh()
        }
    }

    var topStories: [HackerNewsItem] = []

    let itemsPerPage = 30

    var progress = (total: 0, current: 0)

    var searchFilter: String = ""

    func refresh() async {
        let storyIDs = try! await HackerNews().getTopStories()
        print("storyIDs: \(storyIDs.count)")

        let results = await withTaskGroup(of: HackerNewsItem?.self) { group in
            for id in storyIDs[0..<itemsPerPage] {
                group.addTask {
                    try? await HackerNews().getItem(id: id)
                }
            }
            var downloaded = [HackerNewsItem]()
            for await story in group {
                if let story {
                    downloaded.append(story)
                }
                self.progress = (itemsPerPage, downloaded.count)
            }
            return downloaded
        }

        topStories = results
    }
}
