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

        expect(
            sut,
            credentials: credentials,
            toCompleteWith: failure(.invalidCredentials),
            when: {}
        )

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_deliversUserOn200HTTPResponseWithValidJSON() throws {
        let (sut, client) = makeSUT()
        let credentials = LoginCredentials(
            username: "Dimitra",
            password: "123456"
        )
        let user = makeUserJson(
            id: UUID(),
            credentials: credentials,
            token: "a-token",
            expirein: 3600
        )
        let data = try JSONSerialization.data(withJSONObject: user.json)

        expect(
            sut,
            credentials: credentials,
            toCompleteWith: .success(user.model),
            when: {
                client.complete(withStatusCode: 200, data: data)
            }
        )
    }

    func test_login_doesNotRequestLoginWhenUsernameIsEmpty() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let credentials = LoginCredentials(
            username: "",
            password: "123456"
        )

        expect(
            sut,
            credentials: credentials,
            toCompleteWith: failure(.invalidCredentials),
            when: {}
        )

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_doesNotRequestLoginWhenUsernameAndPasswordAreEmpty() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let credentials = LoginCredentials(
            username: "",
            password: ""
        )

        expect(
            sut,
            credentials: credentials,
            toCompleteWith: failure(.invalidCredentials),
            when: {}
        )

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_login_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        let credentials = LoginCredentials(
            username: "Dimitra",
            password: "123456"
        )

        expect(
            sut,
            credentials: credentials,
            toCompleteWith: failure(.invalidData),
            when: {
                client.complete(
                    withStatusCode: 200,
                    data: Data("invalid json".utf8)
                )
            }
        )
    }

    func test_login_deliversInvalidDataErrorOnNon200HTTPResponse() throws {
        let credentials = LoginCredentials(
                username: "Dimitra",
                password: "123456"
            )
            let user = makeUserJson(
                id: UUID(),
                credentials: credentials,
                token: "a-token",
                expirein: 3600
            )
            let data = try JSONSerialization.data(withJSONObject: user.json)

        for code in [199, 201, 300, 400, 500] {
            let (sut, client) = makeSUT()
            
            expect(sut, credentials: credentials, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: code, data: data)
            })
        }
    }

    func test_login_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://a-given-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteUserLogin? = RemoteUserLogin(client: client, url: url)

        var captured = [RemoteUserLogin.Result?]()

        sut?.login(
                username: "Dimitra",
                password: "123456"
            )
        {
            captured.append($0)
        }

        sut = nil

        client.complete(withStatusCode: 200, data: Data())

        XCTAssertTrue(captured.isEmpty)
    }

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteUserLogin, httpClient: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteUserLogin(client: client, url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }

    private func makeUserJson(id: UUID, credentials: LoginCredentials, token: String, expirein: Int)-> (model: User, json: [String: Any]) {
        let user = User(
            id: id,
            username: credentials.username,
            token: token,
            expiresIn: expirein
        )

        let json: [String: Any] = [
            "id": user.id.uuidString,
            "username": user.username,
            "token": user.token,
            "expiresIn": user.expiresIn
        ]

        return (user, json)
    }

    private func failure(_ error: RemoteUserLogin.Error) -> RemoteUserLogin.Result {
        return .failure(error)
    }

    private func expect(
        _ sut: RemoteUserLogin,
        credentials: LoginCredentials,
        toCompleteWith expectedResult: RemoteUserLogin.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {

        let exp = expectation(description: "Wait for load completion")

        sut.login(username: credentials.username, password: credentials.password) { receivedResult in
            switch (receivedResult, expectedResult) {
                case let (.success(receivedUser), .success(expecteduser)):
                    XCTAssertEqual(receivedUser, expecteduser, file: file, line: line)
            case let (.failure(receivedError as RemoteUserLogin.Error), .failure(expectedError as RemoteUserLogin.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), but got \(receivedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1)
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

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!

            messages[index].completion(.success(data, response))
        }
    }
}
