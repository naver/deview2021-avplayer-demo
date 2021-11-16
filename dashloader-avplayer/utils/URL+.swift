//
//  URL+.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/25.
//

import Foundation

extension URL {
    var recoveryScheme: URL {
        change(scheme: "https")
    }

    var customScheme: URL {
        change(scheme: "cdash")
    }

    func change(scheme: String) -> URL {
        var component = URLComponents(url: self,
                                      resolvingAgainstBaseURL: false)
        component?.scheme = scheme
        return component?.url ?? self
    }

    var tempM3U8: URL {
        if lastPathComponent.contains("mpd") {
            var component = URLComponents(url: self.deletingPathExtension(),
                                          resolvingAgainstBaseURL: false)

            var queryItems: [URLQueryItem] = [URLQueryItem(name: "originExtension", value: "mpd")]
            if let urlQueryItems = URLComponents(url: self,
                                                 resolvingAgainstBaseURL: false)?.queryItems {
                queryItems.append(contentsOf: urlQueryItems)
            }

            component?.path += ".m3u8"
            component?.queryItems = queryItems
            return component?.url ?? self
        } else {
            return self
        }
    }

    var recoverMPDIfIsTempM3U8: URL {
        guard var component = URLComponents(url: self.deletingPathExtension(),
                                            resolvingAgainstBaseURL: false),
              let originQueryValue = component.queryItems?.first(where: { $0.name == "originExtension" })?.value else { return self }
        component.path += ".\(originQueryValue)"
        component.queryItems = component.queryItems?.filter { $0.name != "originExtension" }
        return component.url ?? self
    }
}
