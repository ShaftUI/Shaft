import Shaft
import ShaftLucide

final class Kit_Icons: StatefulWidget {
    func createState() -> some State<Kit_Icons> {
        Kit_IconsState()
    }
}

final class Kit_IconsState: State<Kit_Icons> {
    override func build(context: BuildContext) -> Widget {
        return GridView.builder(
            padding: .all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
            ),
            itemCount: LucideIcon.allIcons.count,
            itemBuilder: { context, index in
                Column(mainAxisAlignment: .spaceEvenly) {
                    LucideIcon(
                        name: LucideIcon.allIcons[index],
                        size: 32,
                        color: .init(0xFF_696969)
                    )
                    Text(LucideIcon.allIcons[index], textAlign: .center)
                }
                .padding(.symmetric(horizontal: 4))
                .background(.init(0x05_000000))
            }
        )
        .textStyle(.init(color: .init(0xFF_8c8c8c), fontSize: 12))
    }
}
