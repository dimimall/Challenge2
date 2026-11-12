//
//  Challenge2Tests.swift
//  Challenge2Tests
//
//  Created by Dimitra Malliarou on 11/11/26.
//

import XCTest
@testable import Challenge2

final class Challenge2Tests: XCTestCase {

    func test_init_doesNotRequestLogin() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_doesNotRequestLoginWhenPasswordIsEmpty() {
        let (sut, client) = makeSUT()

        let credentials = LoginCredentials(
            username: "Dimitra",
            password: ""
        )

        sut.login(loginCredentials: credentials) {
            _ in
        }

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_forwardsGivenCredentialsToClient() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let credentials = LoginCredentials(
            username: "Dimitra",
            password: "123456"
        )

        sut.login(loginCredentials: credentials) {
            _ in
        }

        XCTAssertEqual(client.requests,
                       [HTTPClientSpy.Request(url: url, credentials: credentials)])

    }

    func test_login_doesNotRequestLoginWhenUsernameIsEmpty() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let credentials = LoginCredentials(
            username: "",
            password: "123456"
        )

        sut.login(loginCredentials: credentials) {
            _ in
        }

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_doesNotRequestLoginWhenUsernameAndPasswordAreEmpty() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let credentials = LoginCredentials(
            username: "",
            password: ""
        )

        sut.login(loginCredentials: credentials) {
            _ in
        }

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_forwardsCredentialsToClientOnEachCall() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let credentials = LoginCredentials(
            username: "Dimitra",
            password: "123456"
        )

        let otherCredentials = LoginCredentials(
            username: "Mary",
            password: "012345"
        )

        sut.login(loginCredentials: credentials) {
            _ in
        }

        sut.login(loginCredentials: otherCredentials) {
            _ in
        }

        XCTAssertEqual(client.requests,
                       [HTTPClientSpy.Request(url: url, credentials: credentials), HTTPClientSpy.Request(url: url, credentials: otherCredentials)])
    }

    func test_login_loginErrorOnClientError() {
        let (sut, client) = makeSUT()

        var capturedErrors = [RemoteUserLogin.Error]()
        sut.login(loginCredentials: LoginCredentials(username: "Dimitra", password: "123456")) {
            capturedErrors.append($0)
        }

        let error = NSError(domain: "Test", code: 0)
        client.complete(with: error)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_login_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            var capturedErrors: [RemoteUserLogin.Error] = []
            sut.login(loginCredentials: LoginCredentials(
                username: "Dimitra",
                password: "123456"
            )) {
                capturedErrors.append($0)
            }
            
            client.complete(withStatusCode: code, at: index)

            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteUserLogin, httpClient: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteUserLogin(client: client, url: url)

        return (sut, client)
    }

    private final class HTTPClientSpy: HTTPClient {
        struct Request: Equatable {
            let url: URL
            let credentials: LoginCredentials
        }

        private var messages = [
            (
                url: URL,
                credentials: LoginCredentials,
                completion: (HTTPClientResult) -> Void
            )
        ]()

        var requests: [Request] {
            messages.map {
                Request(url: $0.url, credentials: $0.credentials)
            }
        }

        func login(
            from url: URL,
            loginCredentials: LoginCredentials,
            completion: @escaping (HTTPClientResult) -> Void
        ) {
            messages.append((url, loginCredentials, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!

            messages[index].completion(.success(response))
        }
    }
}
