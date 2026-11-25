//
//  EssentialLoginAPIEndToEndTests.swift
//  Challenge2Tests
//
//  Created by Dimitra Malliarou on 25/11/26.
//

import XCTest
@testable import Challenge2

final class EssentialLoginAPIEndToEndTests: XCTestCase {


    func test_login_deliversUserWithValidCredentials() {
        let result = loginUserResult(
            loginCredentials: LoginCredentials(
                username: "dimitra",
                password: "Challenge2-Test-123!"
            )
        )

        switch result {
        case let .success(user)?:
            XCTAssertEqual(
                user.id,
                UUID(
                    uuidString: "A12C047E-89F8-42AE-BDE1-60AF56BA9E25"
                )!
            )
            XCTAssertEqual(user.username, "dimitra")
            XCTAssertFalse(user.token.isEmpty)
            XCTAssertEqual(user.expiresIn, 3600)

        case let .failure(error)?:
            XCTFail("Expected successful login, got \(error)")

        case nil:
            XCTFail("Expected login result, got no result")
        }
    }

    private func loginUserResult(
        loginCredentials: LoginCredentials,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserLoginResult? {
        let testServerURL = URL(string: "http://127.0.0.1:8080/login")!
        let client = URLSessionHTTPClient()
        let remoteUserLogin = RemoteUserLogin(
            client: client,
            url: testServerURL
        )

        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(remoteUserLogin, file: file, line: line)

        let exp = expectation(description: "Wait for login completion")
        var receivedResult: UserLoginResult?

        remoteUserLogin.login(
            username: loginCredentials.username,
            password: loginCredentials.password
        ) { result in
            receivedResult = result
            exp.fulfill()
        }

        withExtendedLifetime(remoteUserLogin) {
            wait(for: [exp], timeout: 5.0)
        }

        return receivedResult
    }

}
