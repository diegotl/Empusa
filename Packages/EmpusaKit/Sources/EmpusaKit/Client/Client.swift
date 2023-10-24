import Foundation
import Combine

public enum ClientError: Error {
    case rateLimitExceeded
}

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
        let (data, _) = try await URLSession
            .shared
            .data(for: request)

        do {
            let decodedResponse = try JSONDecoder()
                .decode(
                    T.self,
                    from: data
                )
            return decodedResponse
        } catch {
            if let decodedErrorResponse = try? JSONDecoder()
                .decode(
                    GitHubErrorResponse.self,
                    from: data
                ),
               decodedErrorResponse.message.contains("API rate limit exceeded") {
                throw ClientError.rateLimitExceeded
            }

            throw error
        }
    }

    func downloadFile(
        url: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> URL {
        // TODO: implement download progress
        defer {
            progressSubject.send(1)
        }

        let (localUrl, _) = try await URLSession
            .shared
            .download(from: url)

        return localUrl
    }
}
