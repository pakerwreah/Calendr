//
//  EventIntervalView.swift
//  Calendr
//
//  Created by Paker on 01/03/2021.
//

import RxSwift
import SwiftUI

struct EventIntervalView: View {

    @StateObject private var viewModel: UIViewModel

    init(
        viewModel: EventIntervalViewModel,
        scaling: Observable<Double> = Scaling.observable
    ) {
        _viewModel = UIViewModel(viewModel: viewModel, scaling: scaling).asStateObject()
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("⋮")
            Text(viewModel.text).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 10 * viewModel.textScale))
        .foregroundColor(.primary)
        .opacity(viewModel.fade ? 0.5 : 1)
    }
}

private class UIViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var fade: Bool = false
    @Published var textScale: Double = 1
    
    private let disposeBag = DisposeBag()

    init(
        viewModel: EventIntervalViewModel,
        scaling: Observable<Double>
    ) {
        disposeBag.insert(
            viewModel.text.bind(to: self, \.text),
            viewModel.fade.bind(to: self, \.fade),
            scaling.bind(to: self, \.textScale)
        )
    }
}

struct EventIntervalView_Previews: PreviewProvider {

    static var previews: some View {

        VStack(spacing: 16) {
            preview(faded: false)
            preview(faded: true)
        }
        .frame(width: 220)
        .padding()
    }

    static func preview(faded: Bool) -> some View {

        EventIntervalView(
            viewModel: .init(
                text: .just("1h30m"),
                fade: .just(faded)
            ),
            scaling: .just(1.5)
        )
    }
}
