import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String

    func makeUIViewController(context: Context) -> BannerAdViewController {
        let controller = BannerAdViewController()
        controller.adUnitID = adUnitID
        return controller
    }

    func updateUIViewController(_ uiViewController: BannerAdViewController, context: Context) {}
}

class BannerAdViewController: UIViewController {
    var adUnitID: String = ""
    private var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard bannerView == nil else { return }

        let adWidth = view.frame.width
        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(adWidth)
        bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        bannerView.load(GADRequest())
    }
}

struct AdBannerContainer: View {
    @Environment(ThemeManager.self) private var themeManager

    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    static let bannerAdUnitID = "ca-app-pub-2695730501568915/4015170772"
    #endif

    var body: some View {
        BannerAdView(adUnitID: Self.bannerAdUnitID)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(themeManager.theme.cardBackground)
    }
}
