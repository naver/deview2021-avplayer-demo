//
//  CustomAssetDelegate.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/09.
//

import AVFoundation

class CustomAssetDelegate: NSObject, AVAssetResourceLoaderDelegate {

    let loader: CustomLoader

    init(loader: CustomLoader) {
        self.loader = loader
    }

    func loadRequestedResource(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }

        if url.pathExtension == "ts" {
            loadingRequest.redirect = URLRequest(url: url.recoveryScheme)
            loadingRequest.response = HTTPURLResponse(url: url.recoveryScheme,
                                                      statusCode: 302,
                                                      httpVersion: nil,
                                                      headerFields: nil)
            loadingRequest.finishLoading()
        } else {
            loader.loadResource(url: url) {
                switch $0 {
                case .success(let data):
                    loadingRequest.dataRequest?.respond(with: data)
                    loadingRequest.finishLoading()
                case .failure(let error):
                    error.printDescription()
                    loadingRequest.finishLoading(with: error)
                }
            }
        }
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        loadRequestedResource(loadingRequest)
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        loadRequestedResource(renewalRequest)
    }
}
