import Foundation
import Combine

protocol ClientProtocol {
    func request<T: Decodable>(url: URL) async throws -> T
    func downloadFile(
        url: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> Data
}

final class Client: ClientProtocol {
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
    ) async throws -> Data {
        let (asyncBytes, urlResponse) = try await URLSession
            .shared
            .bytes(from: url)

        let length = urlResponse.expectedContentLength
        var data = Data()
        data.reserveCapacity(Int(length))

        for try await byte in asyncBytes {
            data.append(byte)
            let downloadProgress = Double(data.count) / Double(length)
            progressSubject.send(downloadProgress)
        }

        return data
    }
}
