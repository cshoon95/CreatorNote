import SwiftUI
@preconcurrency import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID = "ca-app-pub-2695730501568915/4015170772"

    func makeUIViewController(context: Context) -> BannerAdViewController {
        let vc = BannerAdViewController()
        vc.adUnitID = adUnitID
        return vc
    }

    func updateUIViewController(_ uiViewController: BannerAdViewController, context: Context) {}
}

class BannerAdViewController: UIViewController, GADBannerViewDelegate {
    var adUnitID: String = ""
    private var bannerView: GADBannerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if bannerView == nil {
            loadBanner()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in } completion: { _ in
            self.loadBanner()
        }
    }

    private func loadBanner() {
        bannerView?.removeFromSuperview()

        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(view.frame.width)
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = self
        banner.delegate = self
        banner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        banner.load(GADRequest())
        bannerView = banner
    }

    nonisolated func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        DispatchQueue.main.async {
            bannerView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                bannerView.alpha = 1
            }
        }
    }

    nonisolated func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("[AdMob] 배너 로드 실패: \(error.localizedDescription)")
    }
}

struct AdBannerModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            BannerAdView()
                .frame(height: 50)
        }
    }
}

extension View {
    func withBannerAd() -> some View {
        modifier(AdBannerModifier())
    }
}
