// import AppKit
import Foundation
import Shaft

let hackerNewsService = HackerNewsService()

final class HackerNewsApp: StatelessWidget {
    func build(context: BuildContext) -> Widget {
        Column {
            Title()
            Expanded {
                Posts()
            }
        }
    }
}

private let searchController = TextEditingController()

final class Title: StatelessWidget {
    func build(context: BuildContext) -> Widget {
        DecoratedBox(
            decoration: BoxDecoration(color: .init(0xFFFF_6600))
        ) {
            Padding(.all(10)) {
                Row(mainAxisAlignment: .spaceBetween) {
                    Text(
                        "Hacker News",
                        style: .init(
                            color: Color(0xFF00_0000),
                            fontSize: 16,
                            fontWeight: .bold
                        )
                    )
                    SizedBox(width: 200) {
                        DecoratedBox(decoration: .box(color: Color(0xFFFF_FFFF))) {
                            TextField(controller: searchController) { value in
                                hackerNewsService.searchFilter = value
                            }
                        }
                    }
                }
            }
        }
    }
}

final class Posts: StatelessWidget {
    public func build(context: BuildContext) -> Widget {
        SizedBox.expand {
            DecoratedBox(decoration: BoxDecoration(color: .init(0xFFF6_F6EF))) {
                PostsList()
            }
        }
    }
}

final class PostsList: StatelessWidget {
    func build(context: BuildContext) -> Widget {
        if hackerNewsService.topStories.isEmpty {
            Text(
                "Loading\n\(hackerNewsService.progress.current) / \(hackerNewsService.progress.total)",
                style: .init(color: Color(0xFF00_0000))
            )
        } else {
            SingleChildScrollView {
                Padding(EdgeInsets.all(5)) {
                    Column(crossAxisAlignment: .start) {
                        for (index, story) in hackerNewsService.topStories.enumerated() {
                            if hackerNewsService.searchFilter.isEmpty
                                || story.title.contains(hackerNewsService.searchFilter)
                            {
                                Padding(EdgeInsets.all(5)) {
                                    PostRow(index: index + 1, story: story)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

final class PostRow: StatelessWidget {
    init(index: Int, story: HackerNewsItem) {
        self.index = index
        self.story = story
    }

    let index: Int
    let story: HackerNewsItem

    func onTap(_: TapDownDetails) {
        // print("PostRow.onTap: \(story.title)")
        // if let url = story.url {
        //     NSWorkspace.shared.open(URL(string: url)!)
        // }
    }

    func build(context: BuildContext) -> Widget {
        let displayURL = story.url.flatMap { URL(string: $0)?.host }
        return GestureDetector(onTapDown: onTap) {
            Row(crossAxisAlignment: .start) {
                SizedBox(width: 25) {
                    Text(
                        "\(index).",
                        style: .init(color: Color(0xFF99_9999), fontSize: 16),
                        textAlign: .right
                    )
                }
                SizedBox(width: 5)
                Column(crossAxisAlignment: .start) {
                    Row {
                        Text(
                            story.title,
                            style: .init(color: Color(0xFF00_0000), fontSize: 16)
                        )
                        if let displayURL {
                            SizedBox(width: 5)
                            Text(
                                "(\(displayURL))",
                                style: .init(color: Color(0xFF82_8282), fontSize: 14)
                            )
                        }
                    }
                    SizedBox(height: 5)
                    Row {
                        Text(
                            "\(story.score) points by \(story.by)",
                            style: .init(color: Color(0xFF82_8282), fontSize: 12)
                        )
                    }
                }
            }
        }
    }
}
