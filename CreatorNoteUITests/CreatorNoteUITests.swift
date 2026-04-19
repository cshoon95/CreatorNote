import XCTest

@MainActor
final class CreatorNoteUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - 로그인 화면 테스트

    func test_로그인화면_앱이름_표시() throws {
        let influeText = app.staticTexts["Influe"]
        XCTAssertTrue(influeText.waitForExistence(timeout: 5), "앱 이름 'Influe'가 표시되어야 합니다")
    }

    func test_로그인화면_태그라인_표시() throws {
        let tagline = app.staticTexts["인플루언서를 위한 스마트 관리"]
        XCTAssertTrue(tagline.waitForExistence(timeout: 5), "태그라인이 표시되어야 합니다")
    }

    func test_로그인화면_버전뱃지_표시() throws {
        let badge = app.staticTexts["✦ v2.0"]
        XCTAssertTrue(badge.waitForExistence(timeout: 5), "v2.0 뱃지가 표시되어야 합니다")
    }

    func test_로그인화면_Google버튼_존재() throws {
        let googleButton = app.buttons["Google로 계속하기"]
        XCTAssertTrue(googleButton.waitForExistence(timeout: 5), "Google 로그인 버튼이 존재해야 합니다")
    }

    func test_로그인화면_Apple버튼_존재() throws {
        // SignInWithAppleButton은 다양한 접근성 라벨을 가질 수 있음
        let predicate = NSPredicate(format: "label CONTAINS[c] 'Apple' OR label CONTAINS[c] 'apple'")
        let appleButton = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(appleButton.waitForExistence(timeout: 5), "Apple 로그인 버튼이 존재해야 합니다")
    }

    func test_로그인화면_개인정보처리방침_링크() throws {
        // SwiftUI Link는 button으로 노출될 수 있음
        let predicate = NSPredicate(format: "label CONTAINS '개인정보처리방침'")
        let link = app.buttons.matching(predicate).firstMatch
        let linkAsLink = app.links.matching(predicate).firstMatch
        let found = link.waitForExistence(timeout: 5) || linkAsLink.waitForExistence(timeout: 3)
        XCTAssertTrue(found, "개인정보처리방침 링크가 존재해야 합니다")
    }

    func test_로그인화면_이용약관_링크() throws {
        let predicate = NSPredicate(format: "label CONTAINS '이용약관'")
        let link = app.buttons.matching(predicate).firstMatch
        let linkAsLink = app.links.matching(predicate).firstMatch
        let found = link.waitForExistence(timeout: 5) || linkAsLink.waitForExistence(timeout: 3)
        XCTAssertTrue(found, "이용약관 링크가 존재해야 합니다")
    }

    func test_로그인화면_Google버튼_탭가능() throws {
        let googleButton = app.buttons["Google로 계속하기"]
        XCTAssertTrue(googleButton.waitForExistence(timeout: 5))
        XCTAssertTrue(googleButton.isEnabled, "Google 버튼이 탭 가능해야 합니다")
    }

    func test_로그인화면_스크린샷() throws {
        let influeText = app.staticTexts["Influe"]
        XCTAssertTrue(influeText.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "LoginView_v2.0"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
