//
//  Call.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/09.
//

import Foundation

enum CallError: Error {
    case emptyResponse
    case httpError(statusCode: Int)
}

public class Call {

    @discardableResult
    class func get(url: URL,
                   completion: @escaping ((Result<Data, Error>) -> Void)) -> URLSessionTask? {

        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { (data, response, error) in
            // JSON 생성이 안되면 실패 처리
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  let data = data else {

                completion(.failure(error ?? CallError.emptyResponse))
                return
            }

            guard (200...399).contains(statusCode) else {
                let defaultError: Error = {
                    error ?? CallError.httpError(statusCode: statusCode)
                }()

                completion(.failure(defaultError))
                return
            }

            completion(.success(data))
        }
        task.resume()
        return task
    }
}
