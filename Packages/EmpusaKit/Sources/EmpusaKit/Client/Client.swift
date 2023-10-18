import Foundation
import Combine

protocol ClientProtocol {
    func request<T: Decodable>(
        url: URL
    ) async throws -> T

    func downloadFile(
        url: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> URL
}

final class Client: NSObject, ClientProtocol {
    func request<T: Decodable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession
            .shared
            .data(for: request)

        return try JSONDecoder()
            .decode(
                T.self,
                from: data
            )
    }

    func downloadFile(
        url: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> URL {
        // TODO: implement download progress
        defer {
            progressSubject.send(1)
        }

        let (localUrl, response) = try await URLSession
            .shared
            .download(from: url)

        return localUrl
    }
}
