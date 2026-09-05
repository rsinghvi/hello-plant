import SwiftUI
import UIKit

struct CloudSharingView: UIViewControllerRepresentable {
    let controller: UICloudSharingController

    func makeUIViewController(context: Context) -> UICloudSharingController {
        controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}
}
